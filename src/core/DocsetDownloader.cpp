#include "DocsetDownloader.h"
#include <QDir>
#include <QFileInfo>
#include <QtConcurrent>
#include <QDebug>
#include <archive.h>
#include <archive_entry.h>

DocsetDownloader::DocsetDownloader(QObject* parent)
    : QObject(parent)
{
}

DocsetDownloader::~DocsetDownloader() {
    if (m_currentReply) {
        m_currentReply->abort();
        delete m_currentReply;
    }
    if (m_tempFile) {
        m_tempFile->close();
        delete m_tempFile;
    }
}

void DocsetDownloader::startDownload(const QString& id, const QString& version, bool trackLatest, const QString& url, const QString& destinationDir) {
    if (m_isBusy) {
        emit downloadFailed(id, "Another download is already in progress.");
        return;
    }

    m_currentTask = { id, version, trackLatest, url, destinationDir };
    m_isBusy = true;
    emit isBusyChanged(true);

    QDir().mkpath(destinationDir);

    QString tempFilePath = destinationDir + "/" + id + "_temp_archive.download";
    m_tempFile = new QFile(tempFilePath);
    if (!m_tempFile->open(QIODevice::WriteOnly)) {
        m_isBusy = false;
        emit isBusyChanged(false);
        emit downloadFailed(id, "Failed to create temporary download file: " + m_tempFile->errorString());
        delete m_tempFile;
        m_tempFile = nullptr;
        return;
    }

    m_lastBytesReceived = 0;
    m_speedTimer.start();

    QNetworkRequest request(QUrl::fromUserInput(url));
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setRawHeader("User-Agent", "ColdManual/1.0");

    m_currentReply = m_networkManager.get(request);

    connect(m_currentReply, &QNetworkReply::downloadProgress, this, &DocsetDownloader::onDownloadProgress);
    connect(m_currentReply, &QNetworkReply::readyRead, this, [this]() {
        if (m_currentReply && m_tempFile) {
            m_tempFile->write(m_currentReply->readAll());
        }
    });
    connect(m_currentReply, &QNetworkReply::finished, this, &DocsetDownloader::onDownloadFinished);

    emit downloadProgress(id, 0.0, "Starting...");
}

void DocsetDownloader::cancelDownload(const QString& id) {
    if (m_isBusy && m_currentTask.id == id && m_currentReply) {
        m_currentReply->abort();
    }
}

void DocsetDownloader::onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal) {
    if (bytesTotal <= 0) return;

    qreal progress = static_cast<qreal>(bytesReceived) / static_cast<qreal>(bytesTotal);

    // Calculate speed
    qint64 elapsedMs = m_speedTimer.elapsed();
    QString speedStr = "";
    if (elapsedMs >= 500) {
        qint64 bytesDiff = bytesReceived - m_lastBytesReceived;
        double bytesPerSec = (bytesDiff * 1000.0) / elapsedMs;
        m_lastBytesReceived = bytesReceived;
        m_speedTimer.restart();

        if (bytesPerSec > 1024 * 1024) {
            speedStr = QString("%1 MB/s").arg(bytesPerSec / (1024 * 1024), 0, 'f', 1);
        } else {
            speedStr = QString("%1 KB/s").arg(bytesPerSec / 1024, 0, 'f', 0);
        }
    }

    emit downloadProgress(m_currentTask.id, progress, speedStr);
}

void DocsetDownloader::onDownloadFinished() {
    if (!m_currentReply) return;

    if (m_tempFile) {
        m_tempFile->flush();
        m_tempFile->close();
    }

    if (m_currentReply->error() != QNetworkReply::NoError) {
        QString err = m_currentReply->errorString();
        if (m_tempFile) {
            m_tempFile->remove();
            delete m_tempFile;
            m_tempFile = nullptr;
        }
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
        m_isBusy = false;
        emit isBusyChanged(false);
        emit downloadFailed(m_currentTask.id, err);
        return;
    }

    QString archivePath = m_tempFile->fileName();
    delete m_tempFile;
    m_tempFile = nullptr;

    m_currentReply->deleteLater();
    m_currentReply = nullptr;

    emit downloadProgress(m_currentTask.id, 0.99, "Extracting...");

    // Process archive extraction in background thread
    auto task = m_currentTask;
    QThreadPool::globalInstance()->start([this, archivePath, task]() {
        QString targetDir = task.destinationDir + "/" + task.id;
        QDir().mkpath(targetDir);

        QString errorStr;
        bool ok = extractArchive(archivePath, targetDir, &errorStr);

        // Clean up temp archive
        QFile::remove(archivePath);

        QMetaObject::invokeMethod(this, [this, ok, task, targetDir, errorStr]() {
            m_isBusy = false;
            emit isBusyChanged(false);
            if (ok) {
                emit downloadCompleted(task.id, task.version, task.trackLatest, targetDir);
            } else {
                emit downloadFailed(task.id, "Extraction error: " + errorStr);
            }
        });
    });
}

bool DocsetDownloader::extractArchive(const QString& archivePath, const QString& targetDir, QString* errorOut) {
    struct archive* a = archive_read_new();
    archive_read_support_filter_all(a);
    archive_read_support_format_all(a);

    struct archive* ext = archive_write_disk_new();
    archive_write_disk_set_options(ext, ARCHIVE_EXTRACT_TIME | ARCHIVE_EXTRACT_PERM | ARCHIVE_EXTRACT_ACL | ARCHIVE_EXTRACT_FFLAGS);
    archive_write_disk_set_standard_lookup(ext);

    int r = archive_read_open_filename(a, archivePath.toUtf8().constData(), 10240);
    if (r != ARCHIVE_OK) {
        if (errorOut) *errorOut = QString::fromUtf8(archive_error_string(a));
        archive_read_free(a);
        archive_write_free(ext);
        return false;
    }

    struct archive_entry* entry;
    while ((r = archive_read_next_header(a, &entry)) == ARCHIVE_OK) {
        QString currentPath = QString::fromUtf8(archive_entry_pathname(entry));
        // Normalize and avoid directory traversal
        if (currentPath.startsWith("/") || currentPath.contains("../")) {
            currentPath.replace("../", "");
            while (currentPath.startsWith("/")) currentPath.remove(0, 1);
        }

        QString fullDest = targetDir + "/" + currentPath;
        archive_entry_set_pathname(entry, fullDest.toUtf8().constData());

        r = archive_write_header(ext, entry);
        if (r < ARCHIVE_OK) {
            qWarning() << "archive_write_header:" << archive_error_string(ext);
        } else if (archive_entry_size(entry) > 0) {
            const void* buff;
            size_t size;
            la_int64_t offset;
            while ((r = archive_read_data_block(a, &buff, &size, &offset)) == ARCHIVE_OK) {
                if (archive_write_data_block(ext, buff, size, offset) != ARCHIVE_OK) {
                    qWarning() << "archive_write_data_block:" << archive_error_string(ext);
                    break;
                }
            }
            if (r != ARCHIVE_EOF && r != ARCHIVE_OK) {
                qWarning() << "archive_read_data_block error:" << archive_error_string(a);
            }
        }
        r = archive_write_finish_entry(ext);
        if (r < ARCHIVE_OK) {
            qWarning() << "archive_write_finish_entry:" << archive_error_string(ext);
        }
    }

    archive_read_close(a);
    archive_read_free(a);
    archive_write_close(ext);
    archive_write_free(ext);

    return true;
}
