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
    roles[LogoUrlRole] = "logoUrl";
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
    case LogoUrlRole: return getLogoUrl(item.id);
    case LatestVersionRole: return item.latestVersion;
    case VersionsRole: {
        QVariantList list;

        // 1. "Latest Release" (selected by default)
        QVariantMap latestRelease;
        latestRelease["text"] = "Latest Release";
        latestRelease["version"] = "Latest Release";
        latestRelease["isDivider"] = false;
        latestRelease["isLts"] = false;
        latestRelease["isEol"] = false;
        list.append(latestRelease);

        // 2. "Latest LTS" (with green LTS tag)
        QVariantMap latestLts;
        latestLts["text"] = "Latest LTS";
        latestLts["version"] = "Latest LTS";
        latestLts["isDivider"] = false;
        latestLts["isLts"] = true;
        latestLts["isEol"] = false;
        list.append(latestLts);

        // 3. Divider
        QVariantMap divider;
        divider["text"] = "";
        divider["version"] = "";
        divider["isDivider"] = true;
        divider["isLts"] = false;
        divider["isEol"] = false;
        list.append(divider);

        // 4. Fetched dynamic versions
        if (!item.fetchedVersions.isEmpty()) {
            for (const auto& fv : item.fetchedVersions) {
                QVariantMap vMap;
                vMap["text"] = fv.displayName.isEmpty() ? ("v" + fv.version) : fv.displayName;
                vMap["version"] = fv.version;
                vMap["isDivider"] = false;
                vMap["isLts"] = fv.isLts;
                vMap["isEol"] = fv.isEol;
                list.append(vMap);
            }
        } else {
            for (const auto& v : item.versions) {
                QVariantMap vMap;
                vMap["text"] = "v" + v.version;
                vMap["version"] = v.version;
                vMap["isDivider"] = false;
                vMap["isLts"] = false;
                vMap["isEol"] = false;
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

void DocCatalogManager::cleanLegacyCache() {
    QString appData = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QFile::remove(appData + "/catalog_cache.json");
    QDir(appData + "/versions_cache").removeRecursively();
    QDir(appData + "/logos").removeRecursively();
}

void DocCatalogManager::loadDefaultCatalog() {
    // Purge any stale cache from disk so nothing is cached locally
    cleanLegacyCache();

    // Prefer local coldmanual-db repository if available during development
    QString localCatalog = "C:/falcon/Projects/Windows/coldmanual-db/catalog.json";
    if (QFile::exists(localCatalog)) {
        QFile file(localCatalog);
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
                fetchAllDynamicVersions();
            }
            file.close();
        }
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

    // Primary: raw GitHub feed from coldmanual-db
    QUrl primaryUrl("https://raw.githubusercontent.com/falconwasplaying/coldmanual-db/main/catalog.json");
    QNetworkRequest request(primaryUrl);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setHeader(QNetworkRequest::UserAgentHeader, "ColdManual/1.0");

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

                updateCategories();
                applyFilter();
                fetchAllDynamicVersions();
            }
        } else {
            qWarning() << "ColdManual primary catalog fetch failed, trying jsDelivr CDN fallback:" << reply->errorString();
            QUrl cdnUrl("https://cdn.jsdelivr.net/gh/falconwasplaying/coldmanual-db@main/catalog.json");
            QNetworkRequest cdnReq(cdnUrl);
            cdnReq.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
            cdnReq.setHeader(QNetworkRequest::UserAgentHeader, "ColdManual/1.0");

            auto* cdnReply = m_networkManager.get(cdnReq);
            connect(cdnReply, &QNetworkReply::finished, this, [this, cdnReply]() {
                if (cdnReply->error() == QNetworkReply::NoError) {
                    QByteArray cdnData = cdnReply->readAll();
                    QJsonDocument cdnDoc = QJsonDocument::fromJson(cdnData);
                    if (cdnDoc.isArray()) {
                        beginResetModel();
                        m_allItems.clear();
                        for (const auto& val : cdnDoc.array()) {
                            m_allItems.append(CatalogItem::fromJson(val.toObject()));
                        }
                        endResetModel();

                        updateCategories();
                        applyFilter();
                        fetchAllDynamicVersions();
                    }
                } else {
                    qWarning() << "ColdManual CDN catalog fetch also failed:" << cdnReply->errorString();
                }
                cdnReply->deleteLater();
            });
        }
        reply->deleteLater();
    });
}

QString DocCatalogManager::getItemName(const QString& id) const {
    for (const auto& item : m_allItems) {
        if (item.id == id) {
            return item.name;
        }
    }
    if (id.isEmpty()) return QString();
    QString n = id;
    n[0] = n[0].toUpper();
    return n;
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
    // 1. Direct local repository check: if coldmanual-db exists locally on the machine
    QString localManual = "C:/falcon/Projects/Windows/coldmanual-db/manuals/" + id + ".tgz";
    if (QFile::exists(localManual)) {
        return "file:///" + localManual;
    }

    // 2. Resolve download URL from catalog or construct direct coldmanual-db Git LFS media endpoint
    QString targetUrl;
    for (const auto& item : m_allItems) {
        if (item.id == id) {
            bool isLatestReq = version.startsWith("Latest", Qt::CaseInsensitive);
            if (isLatestReq) {
                for (const auto& v : item.versions) {
                    if (v.isLatest || v.version == item.latestVersion) {
                        targetUrl = v.downloadUrl;
                        break;
                    }
                }
                if (targetUrl.isEmpty() && !item.versions.isEmpty()) {
                    targetUrl = item.versions.first().downloadUrl;
                }
            } else {
                for (const auto& v : item.versions) {
                    if (v.version == version || version.contains(v.version) || v.version.contains(version)) {
                        targetUrl = v.downloadUrl;
                        break;
                    }
                }
                if (targetUrl.isEmpty() && !item.versions.isEmpty()) {
                    targetUrl = item.versions.first().downloadUrl;
                }
            }
            break;
        }
    }

    if (targetUrl.isEmpty()) {
        targetUrl = QString("https://media.githubusercontent.com/media/falconwasplaying/coldmanual-db/main/manuals/%1.tgz").arg(id);
    } else if (targetUrl.contains("coldmanual-db") && (targetUrl.contains("/raw/") || targetUrl.contains("raw.githubusercontent.com"))) {
        // Direct media URL bypasses Git LFS pointer text file to fetch full binary archive directly
        targetUrl = QString("https://media.githubusercontent.com/media/falconwasplaying/coldmanual-db/main/manuals/%1.tgz").arg(id);
    }

    return targetUrl;
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

void DocCatalogManager::fetchAllDynamicVersions() {
    for (const auto& item : m_allItems) {
        if (item.fetchedVersions.isEmpty()) {
            fetchDynamicVersions(item.id);
        }
    }
}

void DocCatalogManager::fetchDynamicVersions(const QString& docsetId) {
    // 1. Static standard definitions for standard-based items (C++ and JavaScript)
    if (docsetId == "cpp") {
        QList<FetchedVersion> fList = {
            {"26", "C++26 (Working Draft)", false, false, "2026", ""},
            {"23", "C++23 (ISO/IEC 14882:2024)", true, false, "2024", ""},
            {"20", "C++20 (ISO/IEC 14882:2020)", true, false, "2020", ""},
            {"17", "C++17 (ISO/IEC 14882:2017)", false, false, "2017", ""},
            {"14", "C++14 (ISO/IEC 14882:2014)", false, true, "2014", ""},
            {"11", "C++11 (ISO/IEC 14882:2011)", false, true, "2011", ""}
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
        return;
    }

    if (docsetId == "javascript") {
        QList<FetchedVersion> fList = {
            {"ES2024", "ES2024 (15th Edition)", true, false, "2024", ""},
            {"ES2023", "ES2023 (14th Edition)", true, false, "2023", ""},
            {"ES2022", "ES2022 (13th Edition)", false, false, "2022", ""},
            {"ES2021", "ES2021 (12th Edition)", false, false, "2021", ""},
            {"ES2020", "ES2020 (11th Edition)", false, false, "2020", ""},
            {"ES2015", "ES6 / ES2015", false, true, "2015", ""}
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
                        else if (obj["lts"].isString()) isLts = !obj["lts"].toString().isEmpty() && obj["lts"].toString().toLower() != "false";
                    }

                    bool hasExtendedSupport = false;
                    if (obj.contains("extendedSupport") && obj["extendedSupport"].isString()) {
                        QDate extDate = QDate::fromString(obj["extendedSupport"].toString(), Qt::ISODate);
                        if (extDate.isValid() && extDate >= currentDate) {
                            hasExtendedSupport = true;
                        }
                    }

                    // Check if it's an unreleased future version or pre-release / preview / draft
                    bool isPreview = false;
                    QString lowerCycle = cycle.toLower();
                    if (lowerCycle.contains("rc") || lowerCycle.contains("beta") ||
                        lowerCycle.contains("alpha") || lowerCycle.contains("preview") ||
                        lowerCycle.contains("draft")) {
                        isPreview = true;
                    }
                    if (!relDate.isEmpty()) {
                        QDate releaseQDate = QDate::fromString(relDate, Qt::ISODate);
                        if (releaseQDate.isValid() && releaseQDate > currentDate) {
                            isPreview = true;
                        }
                    }

                    // EOL determination:
                    // If version has active extended support or is an unreleased preview, it is NOT EOL.
                    // Otherwise, inspect the "eol" field. If eol is a past date or boolean true, it's EOL.
                    bool isEol = false;
                    if (!isPreview && !hasExtendedSupport && obj.contains("eol")) {
                        if (obj["eol"].isBool()) {
                            isEol = obj["eol"].toBool();
                        } else if (obj["eol"].isString()) {
                            QDate eolDate = QDate::fromString(obj["eol"].toString(), Qt::ISODate);
                            if (eolDate.isValid()) {
                                isEol = (eolDate < currentDate);
                            } else if (obj["eol"].toString().toLower() == "true") {
                                isEol = true;
                            }
                        }
                    }

                    if (!isPreview && topStable.isEmpty()) {
                        topStable = cycle;
                    }

                    FetchedVersion fv;
                    fv.version = cycle;
                    QString baseName = QString("v%1").arg(cycle);
                    if (!latest.isEmpty() && latest != cycle) {
                        baseName = QString("v%1 (%2)").arg(cycle, latest);
                    }
                    fv.displayName = baseName;
                    fv.isLts = isLts;
                    fv.isEol = isEol;
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
                }
            }
        }
        reply->deleteLater();
    });
}

QString DocCatalogManager::getLogoUrl(const QString& id) const {
    if (id.isEmpty()) return QString();

    // Check local coldmanual-db development repository
    QString localDbLogo = "C:/falcon/Projects/Windows/coldmanual-db/logos/" + id + ".svg";
    if (QFile::exists(localDbLogo)) {
        return "file:///" + localDbLogo;
    }

    // Return direct remote URL without caching uninstalled assets to disk
    return QString("https://raw.githubusercontent.com/falconwasplaying/coldmanual-db/main/logos/%1.svg").arg(id);
}

