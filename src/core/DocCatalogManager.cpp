#include "DocCatalogManager.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>

DocCatalogManager::DocCatalogManager(QObject* parent)
    : QAbstractListModel(parent)
{
    loadDefaultCatalog();
}

int DocCatalogManager::rowCount(const QModelIndex& parent) const {
    if (parent.isValid()) return 0;
    return m_filteredItems.size();
}

QHash<int, QByteArray> DocCatalogManager::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[NameRole] = "name";
    roles[CategoryRole] = "category";
    roles[DescriptionRole] = "description";
    roles[IconRole] = "icon";
    roles[LatestVersionRole] = "latestVersion";
    roles[VersionsRole] = "versions";
    roles[IsInstalledRole] = "isInstalled";
    roles[InstalledVersionRole] = "installedVersion";
    roles[TrackLatestRole] = "trackLatest";
    roles[UpdateAvailableRole] = "updateAvailable";
    roles[IsDownloadingRole] = "isDownloading";
    roles[DownloadProgressRole] = "downloadProgress";
    roles[DownloadSpeedRole] = "downloadSpeed";
    roles[FormatRole] = "format";
    return roles;
}

QVariant DocCatalogManager::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_filteredItems.size()) {
        return QVariant();
    }

    const auto& item = m_filteredItems.at(index.row());
    const auto state = m_itemStates.value(item.id);

    switch (role) {
    case IdRole: return item.id;
    case NameRole: return item.name;
    case CategoryRole: return item.category;
    case DescriptionRole: return item.description;
    case IconRole: return item.icon;
    case LatestVersionRole: return item.latestVersion;
    case VersionsRole: {
        QStringList vList;
        vList.append(QString("Latest Stable (%1)").arg(item.latestVersion));
        for (const auto& v : item.versions) {
            vList.append(v.version);
        }
        vList.removeDuplicates();
        return vList;
    }
    case IsInstalledRole: return state.isInstalled;
    case InstalledVersionRole: return state.installedVersion;
    case TrackLatestRole: return state.trackLatest;
    case UpdateAvailableRole: return state.updateAvailable;
    case IsDownloadingRole: return state.isDownloading;
    case DownloadProgressRole: return state.downloadProgress;
    case DownloadSpeedRole: return state.downloadSpeed;
    case FormatRole: return item.documentationFormat;
    default:
        return QVariant();
    }
}

void DocCatalogManager::setSearchQuery(const QString& query) {
    if (m_searchQuery != query) {
        m_searchQuery = query;
        emit filterChanged();
        applyFilter();
    }
}

void DocCatalogManager::setSelectedCategory(const QString& category) {
    if (m_selectedCategory != category) {
        m_selectedCategory = category;
        emit filterChanged();
        applyFilter();
    }
}

void DocCatalogManager::loadDefaultCatalog() {
    // 1. Try loading cached catalog from app data
    QString cachePath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/catalog_cache.json";
    QFile file(cachePath);
    if (!file.exists()) {
        // Fall back to bundled catalog.json in resources/ or working dir
        file.setFileName(":/resources/catalog.json");
        if (!file.exists()) {
            file.setFileName("resources/catalog.json");
        }
    }

    if (file.open(QIODevice::ReadOnly)) {
        QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
        if (doc.isArray()) {
            beginResetModel();
            m_allItems.clear();
            const auto arr = doc.array();
            for (const auto& val : arr) {
                m_allItems.append(CatalogItem::fromJson(val.toObject()));
            }
            endResetModel();
            updateCategories();
            applyFilter();
        }
        file.close();
    }
}

void DocCatalogManager::updateCategories() {
    QSet<QString> catSet;
    catSet.insert("All");
    for (const auto& item : m_allItems) {
        if (!item.category.isEmpty()) {
            catSet.insert(item.category);
        }
    }
    m_categories = catSet.values();
    std::sort(m_categories.begin(), m_categories.end());
    // Move "All" to the front
    m_categories.removeAll("All");
    m_categories.prepend("All");
    emit categoriesChanged();
}

void DocCatalogManager::applyFilter() {
    beginResetModel();
    m_filteredItems.clear();
    m_filteredIndices.clear();

    const QString lowerQuery = m_searchQuery.trimmed().toLower();
    const bool filterCategory = (m_selectedCategory != "All" && !m_selectedCategory.isEmpty());

    for (int i = 0; i < m_allItems.size(); ++i) {
        const auto& item = m_allItems.at(i);
        if (filterCategory && item.category.compare(m_selectedCategory, Qt::CaseInsensitive) != 0) {
            continue;
        }

        if (!lowerQuery.isEmpty()) {
            bool matches = item.name.toLower().contains(lowerQuery) ||
                           item.id.toLower().contains(lowerQuery) ||
                           item.description.toLower().contains(lowerQuery);
            if (!matches) continue;
        }

        m_filteredItems.append(item);
        m_filteredIndices.append(i);
    }
    endResetModel();
    emit catalogChanged();
}

void DocCatalogManager::refreshCatalog() {
    if (m_isRefreshing) return;
    m_isRefreshing = true;
    emit isRefreshingChanged();

    // ColdManual manifest endpoint or GitHub raw URL
    QUrl url("https://raw.githubusercontent.com/coldmanual/catalog/main/catalog.json");
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);

    auto* reply = m_networkManager.get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        m_isRefreshing = false;
        emit isRefreshingChanged();

        if (reply->error() == QNetworkReply::NoError) {
            QByteArray data = reply->readAll();
            QJsonDocument doc = QJsonDocument::fromJson(data);
            if (doc.isArray()) {
                beginResetModel();
                m_allItems.clear();
                for (const auto& val : doc.array()) {
                    m_allItems.append(CatalogItem::fromJson(val.toObject()));
                }
                endResetModel();

                // Save to cache
                QString cachePath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/catalog_cache.json";
                QFile outFile(cachePath);
                if (outFile.open(QIODevice::WriteOnly)) {
                    outFile.write(data);
                    outFile.close();
                }

                updateCategories();
                applyFilter();
            }
        } else {
            qWarning() << "ColdManual catalog fetch failed:" << reply->errorString();
        }
        reply->deleteLater();
    });
}

QVariantMap DocCatalogManager::getItem(int index) const {
    QVariantMap map;
    if (index >= 0 && index < m_filteredItems.size()) {
        const auto& item = m_filteredItems.at(index);
        const auto state = m_itemStates.value(item.id);
        map["id"] = item.id;
        map["name"] = item.name;
        map["category"] = item.category;
        map["description"] = item.description;
        map["icon"] = item.icon;
        map["latestVersion"] = item.latestVersion;
        map["isInstalled"] = state.isInstalled;
        map["installedVersion"] = state.installedVersion;
        map["trackLatest"] = state.trackLatest;
        map["updateAvailable"] = state.updateAvailable;
        map["isDownloading"] = state.isDownloading;
        map["downloadProgress"] = state.downloadProgress;
    }
    return map;
}

QString DocCatalogManager::getDownloadUrl(const QString& id, const QString& version) const {
    for (const auto& item : m_allItems) {
        if (item.id == id) {
            // Check if version is "Latest Stable (...)"
            bool isLatestReq = version.startsWith("Latest Stable", Qt::CaseInsensitive);
            if (isLatestReq) {
                for (const auto& v : item.versions) {
                    if (v.isLatest || v.version == item.latestVersion) {
                        return v.downloadUrl;
                    }
                }
            }
            // Check specific version match
            for (const auto& v : item.versions) {
                if (v.version == version) {
                    return v.downloadUrl;
                }
            }
            if (!item.versions.isEmpty()) {
                return item.versions.first().downloadUrl;
            }
        }
    }
    return QString();
}

QString DocCatalogManager::getLatestVersion(const QString& id) const {
    for (const auto& item : m_allItems) {
        if (item.id == id) {
            return item.latestVersion;
        }
    }
    return QString();
}

void DocCatalogManager::setDownloadProgress(const QString& id, bool isDownloading, qreal progress, const QString& speedStr) {
    m_itemStates[id].isDownloading = isDownloading;
    m_itemStates[id].downloadProgress = progress;
    m_itemStates[id].downloadSpeed = speedStr;

    for (int row = 0; row < m_filteredItems.size(); ++row) {
        if (m_filteredItems.at(row).id == id) {
            QModelIndex idx = index(row);
            emit dataChanged(idx, idx, {IsDownloadingRole, DownloadProgressRole, DownloadSpeedRole});
            break;
        }
    }
}

void DocCatalogManager::setInstalledStatus(const QString& id, bool installed, const QString& version, bool trackLatest, bool updateAvailable) {
    m_itemStates[id].isInstalled = installed;
    m_itemStates[id].installedVersion = version;
    m_itemStates[id].trackLatest = trackLatest;
    m_itemStates[id].updateAvailable = updateAvailable;

    for (int row = 0; row < m_filteredItems.size(); ++row) {
        if (m_filteredItems.at(row).id == id) {
            QModelIndex idx = index(row);
            emit dataChanged(idx, idx, {IsInstalledRole, InstalledVersionRole, TrackLatestRole, UpdateAvailableRole});
            break;
        }
    }
}
