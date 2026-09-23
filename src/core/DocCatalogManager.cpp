#include "DocCatalogManager.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <QDate>
#include <QUrl>

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
        QVariantList list;

        // 1. "Latest Release" (selected by default)
        QVariantMap latestRelease;
        latestRelease["text"] = "Latest Release";
        latestRelease["version"] = "Latest Release";
        latestRelease["isDivider"] = false;
        latestRelease["isStable"] = false;
        list.append(latestRelease);

        // 2. "Latest Stable" (with green Stable tag)
        QVariantMap latestStable;
        latestStable["text"] = "Latest Stable";
        latestStable["version"] = "Latest Stable";
        latestStable["isDivider"] = false;
        latestStable["isStable"] = true;
        list.append(latestStable);

        // 3. Divider
        QVariantMap divider;
        divider["text"] = "";
        divider["version"] = "";
        divider["isDivider"] = true;
        divider["isStable"] = false;
        list.append(divider);

        // 4. Fetched dynamic versions
        if (!item.fetchedVersions.isEmpty()) {
            for (const auto& fv : item.fetchedVersions) {
                QVariantMap vMap;
                vMap["text"] = fv.displayName.isEmpty() ? ("v" + fv.version) : fv.displayName;
                vMap["version"] = fv.version;
                vMap["isDivider"] = false;
                vMap["isStable"] = fv.isStable;
                list.append(vMap);
            }
        } else {
            for (const auto& v : item.versions) {
                QVariantMap vMap;
                vMap["text"] = "v" + v.version;
                vMap["version"] = v.version;
                vMap["isDivider"] = false;
                vMap["isStable"] = v.isLatest;
                list.append(vMap);
            }
        }
        return list;
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
            loadCachedVersions();
            fetchAllDynamicVersions();
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
                loadCachedVersions();
                fetchAllDynamicVersions();
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
            // Check if version is "Latest Release" or "Latest Stable"
            bool isLatestReq = version.startsWith("Latest", Qt::CaseInsensitive);
            if (isLatestReq) {
                for (const auto& v : item.versions) {
                    if (v.isLatest || v.version == item.latestVersion) {
                        return v.downloadUrl;
                    }
                }
                if (!item.versions.isEmpty()) {
                    return item.versions.first().downloadUrl;
                }
            }
            // Check specific version match or partial match
            for (const auto& v : item.versions) {
                if (v.version == version || version.contains(v.version) || v.version.contains(version)) {
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

void DocCatalogManager::loadCachedVersions() {
    QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/versions_cache";
    for (int i = 0; i < m_allItems.size(); ++i) {
        QString filePath = cacheDir + "/" + m_allItems[i].id + ".json";
        QFile file(filePath);
        if (file.open(QIODevice::ReadOnly)) {
            QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
            if (doc.isArray()) {
                QList<FetchedVersion> fList;
                for (const auto& val : doc.array()) {
                    QJsonObject obj = val.toObject();
                    FetchedVersion fv;
                    fv.version = obj["version"].toString();
                    fv.displayName = obj["displayName"].toString();
                    fv.isStable = obj["isStable"].toBool(false);
                    fv.releaseDate = obj["releaseDate"].toString();
                    fList.append(fv);
                }
                if (!fList.isEmpty()) {
                    m_allItems[i].fetchedVersions = fList;
                }
            }
            file.close();
        }
    }
    for (int i = 0; i < m_filteredItems.size(); ++i) {
        for (const auto& item : m_allItems) {
            if (item.id == m_filteredItems[i].id) {
                m_filteredItems[i].fetchedVersions = item.fetchedVersions;
                break;
            }
        }
    }
}

void DocCatalogManager::saveCachedVersions(const QString& docsetId, const QList<FetchedVersion>& versions) {
    QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/versions_cache";
    QDir().mkpath(cacheDir);

    QJsonArray arr;
    for (const auto& fv : versions) {
        QJsonObject obj;
        obj["version"] = fv.version;
        obj["displayName"] = fv.displayName;
        obj["isStable"] = fv.isStable;
        obj["releaseDate"] = fv.releaseDate;
        arr.append(obj);
    }

    QFile file(cacheDir + "/" + docsetId + ".json");
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(arr).toJson(QJsonDocument::Compact));
        file.close();
    }
}

void DocCatalogManager::fetchAllDynamicVersions() {
    for (const auto& item : m_allItems) {
        fetchDynamicVersions(item.id);
    }
}

void DocCatalogManager::fetchDynamicVersions(const QString& docsetId) {
    // 1. Static standard definitions for standard-based items (C++ and JavaScript)
    if (docsetId == "cpp") {
        QList<FetchedVersion> fList = {
            {"26", "C++26 (Working Draft)", false, "2026", ""},
            {"23", "C++23 (ISO/IEC 14882:2024)", true, "2024", ""},
            {"20", "C++20 (ISO/IEC 14882:2020)", true, "2020", ""},
            {"17", "C++17 (ISO/IEC 14882:2017)", true, "2017", ""},
            {"14", "C++14 (ISO/IEC 14882:2014)", true, "2014", ""},
            {"11", "C++11 (ISO/IEC 14882:2011)", true, "2011", ""}
        };
        for (int i = 0; i < m_allItems.size(); ++i) {
            if (m_allItems[i].id == docsetId) {
                m_allItems[i].fetchedVersions = fList;
                m_allItems[i].latestVersion = "23";
                break;
            }
        }
        for (int i = 0; i < m_filteredItems.size(); ++i) {
            if (m_filteredItems[i].id == docsetId) {
                m_filteredItems[i].fetchedVersions = fList;
                m_filteredItems[i].latestVersion = "23";
                QModelIndex idx = index(i);
                emit dataChanged(idx, idx, {VersionsRole, LatestVersionRole});
                break;
            }
        }
        saveCachedVersions(docsetId, fList);
        return;
    }

    if (docsetId == "javascript") {
        QList<FetchedVersion> fList = {
            {"ES2024", "ES2024 (15th Edition)", true, "2024", ""},
            {"ES2023", "ES2023 (14th Edition)", true, "2023", ""},
            {"ES2022", "ES2022 (13th Edition)", true, "2022", ""},
            {"ES2021", "ES2021 (12th Edition)", true, "2021", ""},
            {"ES2020", "ES2020 (11th Edition)", true, "2020", ""},
            {"ES2015", "ES6 / ES2015", true, "2015", ""}
        };
        for (int i = 0; i < m_allItems.size(); ++i) {
            if (m_allItems[i].id == docsetId) {
                m_allItems[i].fetchedVersions = fList;
                m_allItems[i].latestVersion = "ES2024";
                break;
            }
        }
        for (int i = 0; i < m_filteredItems.size(); ++i) {
            if (m_filteredItems[i].id == docsetId) {
                m_filteredItems[i].fetchedVersions = fList;
                m_filteredItems[i].latestVersion = "ES2024";
                QModelIndex idx = index(i);
                emit dataChanged(idx, idx, {VersionsRole, LatestVersionRole});
                break;
            }
        }
        saveCachedVersions(docsetId, fList);
        return;
    }

    // 2. Query endoflife.date API for live release data
    QString product = docsetId;
    if (docsetId == "docker") product = "docker-engine";

    QUrl apiUrl(QString("https://endoflife.date/api/%1.json").arg(product));
    QNetworkRequest request(apiUrl);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setHeader(QNetworkRequest::UserAgentHeader, "ColdManual/1.0");

    auto* reply = m_networkManager.get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply, docsetId]() {
        if (reply->error() == QNetworkReply::NoError) {
            QByteArray data = reply->readAll();
            QJsonDocument doc = QJsonDocument::fromJson(data);
            if (doc.isArray()) {
                QList<FetchedVersion> fList;
                QDate currentDate = QDate::currentDate();
                QString topStable;

                for (const auto& val : doc.array()) {
                    QJsonObject obj = val.toObject();
                    QString cycle = obj["cycle"].toString();
                    QString latest = obj["latest"].toString();
                    QString relDate = obj["releaseDate"].toString();

                    bool isLts = false;
                    if (obj.contains("lts")) {
                        if (obj["lts"].isBool()) isLts = obj["lts"].toBool();
                        else if (obj["lts"].isString()) isLts = !obj["lts"].toString().isEmpty() && obj["lts"].toString() != "false";
                    }

                    bool hasExtendedSupport = false;
                    if (obj.contains("extendedSupport") && obj["extendedSupport"].isString()) {
                        QDate extDate = QDate::fromString(obj["extendedSupport"].toString(), Qt::ISODate);
                        if (extDate.isValid() && extDate >= currentDate) {
                            hasExtendedSupport = true;
                        }
                    }

                    bool isStable = false;
                    QJsonValue eolVal = obj["eol"];
                    if (eolVal.isBool()) {
                        isStable = !eolVal.toBool();
                    } else if (eolVal.isString()) {
                        QDate eolDate = QDate::fromString(eolVal.toString(), Qt::ISODate);
                        if (eolDate.isValid()) {
                            isStable = (eolDate >= currentDate);
                        }
                    }

                    // A release is Stable if:
                    // 1. It is an official LTS release (e.g. Qt 6.8, Qt 6.5, Qt 6.2, Qt 5.15, Node 22, Node 20)
                    // 2. It has active extended support
                    // 3. For Qt: all official releases in the current active Qt 6 series (Qt 6.x) are stable GA releases!
                    // 4. For Rust: all standard 6-week train releases (1.x) are stable compiler releases!
                    if (isLts || hasExtendedSupport) {
                        isStable = true;
                    }
                    if (docsetId == "qt" && (cycle.startsWith("6.") || isLts)) {
                        isStable = true;
                    }
                    if (docsetId == "rust" && cycle.startsWith("1.")) {
                        isStable = true;
                    }

                    if (isStable && topStable.isEmpty()) {
                        topStable = cycle;
                    }

                    FetchedVersion fv;
                    fv.version = cycle;
                    QString baseName = QString("v%1").arg(cycle);
                    if (!latest.isEmpty() && latest != cycle) {
                        baseName = QString("v%1 (%2)").arg(cycle, latest);
                    }
                    if (isLts) {
                        baseName += " [LTS]";
                    }
                    fv.displayName = baseName;
                    fv.isStable = isStable;
                    fv.releaseDate = relDate;
                    fList.append(fv);
                }

                if (!fList.isEmpty()) {
                    for (int i = 0; i < m_allItems.size(); ++i) {
                        if (m_allItems[i].id == docsetId) {
                            m_allItems[i].fetchedVersions = fList;
                            if (!topStable.isEmpty()) {
                                m_allItems[i].latestVersion = topStable;
                            }
                            break;
                        }
                    }
                    for (int i = 0; i < m_filteredItems.size(); ++i) {
                        if (m_filteredItems[i].id == docsetId) {
                            m_filteredItems[i].fetchedVersions = fList;
                            if (!topStable.isEmpty()) {
                                m_filteredItems[i].latestVersion = topStable;
                            }
                            QModelIndex idx = index(i);
                            emit dataChanged(idx, idx, {VersionsRole, LatestVersionRole});
                            break;
                        }
                    }
                    saveCachedVersions(docsetId, fList);
                }
            }
        }
        reply->deleteLater();
    });
}
