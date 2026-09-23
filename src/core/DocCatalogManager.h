#pragma once

#include <QAbstractListModel>
#include <QList>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include "CatalogItem.h"

class DocCatalogManager : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(QString searchQuery READ searchQuery WRITE setSearchQuery NOTIFY filterChanged)
    Q_PROPERTY(QString selectedCategory READ selectedCategory WRITE setSelectedCategory NOTIFY filterChanged)
    Q_PROPERTY(QStringList categories READ categories NOTIFY categoriesChanged)
    Q_PROPERTY(bool isRefreshing READ isRefreshing NOTIFY isRefreshingChanged)
    Q_PROPERTY(int totalItems READ totalItems NOTIFY catalogChanged)

public:
    enum CatalogRoles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        CategoryRole,
        DescriptionRole,
        IconRole,
        LatestVersionRole,
        VersionsRole,
        IsInstalledRole,
        InstalledVersionRole,
        TrackLatestRole,
        UpdateAvailableRole,
        IsDownloadingRole,
        DownloadProgressRole,
        DownloadSpeedRole,
        FormatRole
    };

    explicit DocCatalogManager(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString searchQuery() const { return m_searchQuery; }
    void setSearchQuery(const QString& query);

    QString selectedCategory() const { return m_selectedCategory; }
    void setSelectedCategory(const QString& category);

    QStringList categories() const { return m_categories; }
    bool isRefreshing() const { return m_isRefreshing; }
    int totalItems() const { return m_filteredItems.size(); }

    Q_INVOKABLE void refreshCatalog();
    Q_INVOKABLE QVariantMap getItem(int index) const;
    Q_INVOKABLE QString getDownloadUrl(const QString& id, const QString& version) const;
    Q_INVOKABLE QString getLatestVersion(const QString& id) const;

    // Called by DocsetManager / Downloader to synchronize live UI state
    void setDownloadProgress(const QString& id, bool isDownloading, qreal progress, const QString& speedStr = "");
    void setInstalledStatus(const QString& id, bool installed, const QString& version, bool trackLatest, bool updateAvailable = false);

signals:
    void filterChanged();
    void categoriesChanged();
    void isRefreshingChanged();
    void catalogChanged();
    void downloadRequested(const QString& id, const QString& version, bool trackLatest, const QString& downloadUrl);

private:
    struct ItemState {
        bool isInstalled{false};
        QString installedVersion;
        bool trackLatest{false};
        bool updateAvailable{false};
        bool isDownloading{false};
        qreal downloadProgress{0.0};
        QString downloadSpeed;
    };

    QList<CatalogItem> m_allItems;
    QList<int> m_filteredIndices; // Indices into m_allItems
    QList<CatalogItem> m_filteredItems;
    QMap<QString, ItemState> m_itemStates; // id -> state
    QStringList m_categories;
    QString m_searchQuery;
    QString m_selectedCategory{"All"};
    bool m_isRefreshing{false};

    QNetworkAccessManager m_networkManager;

    void loadDefaultCatalog();
    void applyFilter();
    void updateCategories();
};
