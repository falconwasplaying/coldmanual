#pragma once

#include <QAbstractListModel>
#include <QList>
#include <QTimer>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include "CatalogItem.h"
#include "DocCatalogManager.h"
#include "DocsetDownloader.h"
#include "DocsetSearchEngine.h"
#include "SettingsManager.h"

class DocsetManager : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int installedCount READ installedCount NOTIFY installedCountChanged)
    Q_PROPERTY(QString totalStorageUsage READ totalStorageUsage NOTIFY storageUsageChanged)
    Q_PROPERTY(bool isCheckingUpdates READ isCheckingUpdates NOTIFY isCheckingUpdatesChanged)

public:
    enum InstalledRoles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        InstalledVersionRole,
        TrackLatestRole,
        LocalPathRole,
        IndexPathRole,
        LogoPathRole,
        SizeBytesRole,
        SizeFormattedRole,
        InstalledAtRole,
        LastCheckedRole,
        UpdateAvailableRole,
        AvailableVersionRole
    };

    explicit DocsetManager(DocCatalogManager* catalogMgr,
                           DocsetDownloader* downloader,
                           DocsetSearchEngine* searchEngine,
                           SettingsManager* settingsMgr,
                           QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int installedCount() const { return m_installedList.size(); }
    QString totalStorageUsage() const;
    bool isCheckingUpdates() const { return m_isCheckingUpdates; }

    Q_INVOKABLE void installDocset(const QString& id, const QString& versionChoice);
    Q_INVOKABLE void updateDocset(const QString& id);
    Q_INVOKABLE void updateAll();
    Q_INVOKABLE void removeDocset(const QString& id);
    Q_INVOKABLE void setTrackLatest(const QString& id, bool trackLatest);
    Q_INVOKABLE void checkForUpdates();
    Q_INVOKABLE QVariantMap getInstalledDocset(const QString& id) const;
    Q_INVOKABLE QString getLogoPath(const QString& id) const;

signals:
    void installedCountChanged();
    void storageUsageChanged();
    void isCheckingUpdatesChanged();
    void docsetInstalled(const QString& id, const QString& name);
    void docsetRemoved(const QString& id);
    void updateFound(const QString& id, const QString& newVersion);

private slots:
    void onDownloadCompleted(const QString& id, const QString& version, bool trackLatest, const QString& extractedDir);
    void onDownloadFailed(const QString& id, const QString& errorMessage);
    void onDownloadProgress(const QString& id, qreal progress, const QString& speedStr);

private:
    DocCatalogManager* m_catalogMgr;
    DocsetDownloader* m_downloader;
    DocsetSearchEngine* m_searchEngine;
    SettingsManager* m_settingsMgr;
    QNetworkAccessManager m_networkManager;

    QList<InstalledDocset> m_installedList;
    bool m_isCheckingUpdates{false};
    QTimer m_autoUpdateTimer;

    void loadInstalledRegistry();
    void saveInstalledRegistry();
    void scanInstalledFolder();
    void registerWithSearchEngine(const InstalledDocset& doc);
    static qint64 calculateDirectorySize(const QString& dirPath);
    static QString formatBytes(qint64 bytes);
    void setupAutoUpdateTimer();
};
