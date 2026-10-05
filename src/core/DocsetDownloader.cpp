#include "DocsetDownloader.h"
#include <QDir>
#include <QFileInfo>
#include <QtConcurrent>
#include <QDebug>
#include <QProcess>
#include <QStandardPaths>
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

    // Direct local manual resolution (e.g. from local coldmanual-db repository)
    QString localFilePath;
    if (url.startsWith("file:///", Qt::CaseInsensitive)) {
        localFilePath = QUrl(url).toLocalFile();
    } else if (QFile::exists(url)) {
        localFilePath = url;
    }

    if (!localFilePath.isEmpty() && QFile::exists(localFilePath)) {
        emit downloadProgress(id, 0.5, "Extracting manual...");
        auto task = m_currentTask;
        QThreadPool::globalInstance()->start([this, localFilePath, task]() {
            QString targetDir = task.destinationDir + "/" + task.id;
            QDir().mkpath(targetDir);

            QString errorStr;
            auto progressCb = [this, task](int count) {
                QMetaObject::invokeMethod(this, [this, task, count]() {
                    qreal p = 0.5 + std::min(0.48, count / 20000.0);
                    emit downloadProgress(task.id, p, QString("Extracting (%1 files)...").arg(count));
                });
            };

            bool ok = extractArchive(localFilePath, targetDir, &errorStr, progressCb);

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
        return;
    }

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
        QByteArray remaining = m_currentReply->readAll();
        if (!remaining.isEmpty()) {
            m_tempFile->write(remaining);
        }
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

    // Detect if downloaded file is a Git LFS pointer text file (e.g. from raw.githubusercontent.com)
    QFile downloadedFile(archivePath);
    if (downloadedFile.size() < 1024 && downloadedFile.open(QIODevice::ReadOnly)) {
        QByteArray preview = downloadedFile.read(256);
        downloadedFile.close();
        if (preview.startsWith("version https://git-lfs.github.com/spec/v1")) {
            qWarning() << "Downloaded file is a Git LFS pointer, switching to media.githubusercontent.com for" << m_currentTask.id;
            downloadedFile.remove();
            m_isBusy = false;
            emit isBusyChanged(false);
            QString mediaUrl = QString("https://media.githubusercontent.com/media/falconwasplaying/coldmanual-db/main/manuals/%1.tgz").arg(m_currentTask.id);
            startDownload(m_currentTask.id, m_currentTask.version, m_currentTask.trackLatest, mediaUrl, m_currentTask.destinationDir);
            return;
        }
    }

    emit downloadProgress(m_currentTask.id, 0.90, "Extracting...");

    // Process archive extraction in background thread
    auto task = m_currentTask;
    QThreadPool::globalInstance()->start([this, archivePath, task]() {
        QString targetDir = task.destinationDir + "/" + task.id;
        QDir().mkpath(targetDir);

        QString errorStr;
        auto progressCb = [this, task](int count) {
            QMetaObject::invokeMethod(this, [this, task, count]() {
                qreal p = 0.90 + std::min(0.09, count / 20000.0);
                emit downloadProgress(task.id, p, QString("Extracting (%1 files)...").arg(count));
            });
        };

        bool ok = extractArchive(archivePath, targetDir, &errorStr, progressCb);

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

bool DocsetDownloader::extractArchiveWithNativeTar(const QString& archivePath, const QString& targetDir, QString* errorOut) {
    QString tarExe = QStandardPaths::findExecutable("tar");
    if (tarExe.isEmpty() && QFile::exists("C:/Windows/System32/tar.exe")) {
        tarExe = "C:/Windows/System32/tar.exe";
    }
    if (tarExe.isEmpty()) {
        if (errorOut) *errorOut = "Extraction utility (tar) not available on this system.";
        return false;
    }

    QDir().mkpath(targetDir);

    QProcess process;
    process.setProgram(tarExe);
    process.setArguments(QStringList() << "-xzf" << QDir::toNativeSeparators(archivePath) << "-C" << QDir::toNativeSeparators(targetDir));
    process.start();
    if (!process.waitForFinished(180000)) {
        process.kill();
        if (errorOut) *errorOut = "Extraction timed out after 3 minutes.";
        return false;
    }

    if (process.exitStatus() == QProcess::NormalExit && process.exitCode() == 0) {
        return true;
    }

    QString stderrOutput = QString::fromUtf8(process.readAllStandardError()).trimmed();
    if (errorOut) {
        *errorOut = stderrOutput.isEmpty() ? QString("tar exited with code %1").arg(process.exitCode()) : stderrOutput;
    }
    return false;
}

bool DocsetDownloader::extractArchive(const QString& archivePath, const QString& targetDir, QString* errorOut, std::function<void(int count)> progressCb) {
    struct archive* a = archive_read_new();
    archive_read_support_filter_all(a);
    archive_read_support_format_all(a);

    struct archive* ext = archive_write_disk_new();
    // Do NOT use ARCHIVE_EXTRACT_PERM on Windows NTFS as POSIX permission translation marks dirs/files read-only
    archive_write_disk_set_options(ext, ARCHIVE_EXTRACT_TIME | ARCHIVE_EXTRACT_SECURE_NODOTDOT | ARCHIVE_EXTRACT_UNLINK);

    // 256 KB buffer for high-speed streaming
    int r = archive_read_open_filename(a, archivePath.toUtf8().constData(), 262144);
    if (r != ARCHIVE_OK) {
        if (errorOut) *errorOut = QString::fromUtf8(archive_error_string(a));
        archive_read_free(a);
        archive_write_free(ext);
        return extractArchiveWithNativeTar(archivePath, targetDir, errorOut);
    }

    struct archive_entry* entry;
    QString lastParentDir;
    int fileCount = 0;
    bool hadFatalError = false;

    while (true) {
        r = archive_read_next_header(a, &entry);
        if (r == ARCHIVE_EOF) break;
        if (r < ARCHIVE_WARN) { // Error or Fatal
            if (errorOut) *errorOut = QString::fromUtf8(archive_error_string(a));
            hadFatalError = true;
            break;
        }

        QString currentPath = QString::fromUtf8(archive_entry_pathname(entry));
        currentPath.replace('\\', '/');
        while (currentPath.startsWith("./")) currentPath.remove(0, 2);
        while (currentPath.startsWith("/")) currentPath.remove(0, 1);
        if (currentPath.contains("../")) {
            currentPath.replace("../", "");
        }
        if (currentPath.isEmpty()) continue;

        QString fullDest = targetDir + "/" + currentPath;
        QFileInfo fi(fullDest);
        QString parentDir = fi.absolutePath();

        // Cached directory creation avoids thousands of redundant Win32 directory checks
        if (parentDir != lastParentDir) {
            QDir().mkpath(parentDir);
            lastParentDir = parentDir;
        }

        archive_entry_set_pathname(entry, fullDest.toUtf8().constData());

        int writeHeaderRes = archive_write_header(ext, entry);
        if (writeHeaderRes >= ARCHIVE_WARN && archive_entry_size(entry) > 0) {
            const void* buff;
            size_t size;
            la_int64_t offset;
            while ((r = archive_read_data_block(a, &buff, &size, &offset)) == ARCHIVE_OK) {
                if (archive_write_data_block(ext, buff, size, offset) != ARCHIVE_OK) {
                    break;
                }
            }
        }
        archive_write_finish_entry(ext);

        fileCount++;
        if (progressCb && (fileCount % 200 == 0)) {
            progressCb(fileCount);
        }
    }

    archive_read_close(a);
    archive_read_free(a);
    archive_write_close(ext);
    archive_write_free(ext);

    if (hadFatalError || fileCount == 0) {
        qWarning() << "libarchive extraction incomplete or failed (files:" << fileCount << "), attempting native tar fallback for" << archivePath;
        return extractArchiveWithNativeTar(archivePath, targetDir, errorOut);
    }

    return true;
}
