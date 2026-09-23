#pragma once

#include <QObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QFile>
#include <QElapsedTimer>
#include <QThread>

class DocsetDownloader : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isBusy READ isBusy NOTIFY isBusyChanged)

public:
    struct DownloadTask {
        QString id;
        QString version;
        bool trackLatest{false};
        QString url;
        QString destinationDir;
    };

    explicit DocsetDownloader(QObject* parent = nullptr);
    ~DocsetDownloader();

    bool isBusy() const { return m_isBusy; }

    Q_INVOKABLE void startDownload(const QString& id, const QString& version, bool trackLatest, const QString& url, const QString& destinationDir);
    Q_INVOKABLE void cancelDownload(const QString& id);

signals:
    void isBusyChanged(bool busy);
    void downloadProgress(const QString& id, qreal progress, const QString& speedStr);
    void downloadCompleted(const QString& id, const QString& version, bool trackLatest, const QString& extractedDir);
    void downloadFailed(const QString& id, const QString& errorMessage);

private slots:
    void onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal);
    void onDownloadFinished();

private:
    bool m_isBusy{false};
    QNetworkAccessManager m_networkManager;
    QNetworkReply* m_currentReply{nullptr};
    QFile* m_tempFile{nullptr};
    DownloadTask m_currentTask;
    QElapsedTimer m_speedTimer;
    qint64 m_lastBytesReceived{0};

    void processExtraction(const QString& archivePath, const QString& targetDir);
    static bool extractArchive(const QString& archivePath, const QString& targetDir, QString* errorOut);
};
