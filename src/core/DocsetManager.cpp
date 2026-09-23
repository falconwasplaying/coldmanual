#include "DocsetManager.h"
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDebug>

DocsetManager::DocsetManager(DocCatalogManager* catalogMgr,
                             DocsetDownloader* downloader,
                             DocsetSearchEngine* searchEngine,
                             SettingsManager* settingsMgr,
                             QObject* parent)
    : QAbstractListModel(parent)
    , m_catalogMgr(catalogMgr)
    , m_downloader(downloader)
    , m_searchEngine(searchEngine)
    , m_settingsMgr(settingsMgr)
{
    connect(m_downloader, &DocsetDownloader::downloadProgress, this, &DocsetManager::onDownloadProgress);
    connect(m_downloader, &DocsetDownloader::downloadCompleted, this, &DocsetManager::onDownloadCompleted);
    connect(m_downloader, &DocsetDownloader::downloadFailed, this, &DocsetManager::onDownloadFailed);

    loadInstalledRegistry();
    setupAutoUpdateTimer();
}

int DocsetManager::rowCount(const QModelIndex& parent) const {
    if (parent.isValid()) return 0;
    return m_installedList.size();
}

QHash<int, QByteArray> DocsetManager::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[NameRole] = "name";
    roles[InstalledVersionRole] = "installedVersion";
    roles[TrackLatestRole] = "trackLatest";
    roles[LocalPathRole] = "localPath";
    roles[IndexPathRole] = "indexPath";
    roles[LogoPathRole] = "logoPath";
    roles[SizeBytesRole] = "sizeBytes";
    roles[SizeFormattedRole] = "sizeFormatted";
    roles[InstalledAtRole] = "installedAt";
    roles[LastCheckedRole] = "lastChecked";
    roles[UpdateAvailableRole] = "updateAvailable";
    roles[AvailableVersionRole] = "availableVersion";
    return roles;
}

QVariant DocsetManager::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_installedList.size()) {
        return QVariant();
    }

    const auto& item = m_installedList.at(index.row());
    switch (role) {
    case IdRole: return item.id;
    case NameRole: return item.name;
    case InstalledVersionRole: return item.installedVersion;
    case TrackLatestRole: return item.trackLatest;
    case LocalPathRole: return item.localPath;
    case IndexPathRole: return item.indexPath;
    case LogoPathRole: return item.logoPath.isEmpty() ? "" : ("file:///" + item.logoPath);
    case SizeBytesRole: return item.sizeBytes;
    case SizeFormattedRole: return formatBytes(item.sizeBytes);
    case InstalledAtRole: return item.installedAt.toString("yyyy-MM-dd");
    case LastCheckedRole: return item.lastChecked.toString("yyyy-MM-dd hh:mm");
    case UpdateAvailableRole: return item.updateAvailable;
    case AvailableVersionRole: return item.availableVersion;
    default:
        return QVariant();
    }
}

QString DocsetManager::getLogoPath(const QString& id) const {
    for (const auto& doc : m_installedList) {
        if (doc.id == id) {
            if (!doc.logoPath.isEmpty() && QFile::exists(doc.logoPath)) {
                return "file:///" + doc.logoPath;
            }
            QString fallback = doc.localPath + "/logo.svg";
            if (QFile::exists(fallback)) {
                return "file:///" + fallback;
            }
            break;
        }
    }
    return QString();
}

QString DocsetManager::totalStorageUsage() const {
    qint64 total = 0;
    for (const auto& doc : m_installedList) {
        total += doc.sizeBytes;
    }
    return formatBytes(total);
}

void DocsetManager::installDocset(const QString& id, const QString& versionChoice) {
    bool trackLatest = versionChoice.startsWith("Latest", Qt::CaseInsensitive);
    QString resolvedVersion;

    if (trackLatest) {
        resolvedVersion = m_catalogMgr->getLatestVersion(id);
    } else {
        resolvedVersion = versionChoice;
    }

    QString downloadUrl = m_catalogMgr->getDownloadUrl(id, versionChoice);
    if (downloadUrl.isEmpty()) {
        qWarning() << "No download URL found for" << id << versionChoice;
        return;
    }

    QString destDir = m_settingsMgr->storagePath();
    m_catalogMgr->setDownloadProgress(id, true, 0.01, "Connecting...");
    m_downloader->startDownload(id, resolvedVersion, trackLatest, downloadUrl, destDir);
}

void DocsetManager::updateDocset(const QString& id) {
    for (const auto& doc : m_installedList) {
        if (doc.id == id) {
            installDocset(id, "Latest Stable");
            break;
        }
    }
}

void DocsetManager::updateAll() {
    for (const auto& doc : m_installedList) {
        if (doc.trackLatest && doc.updateAvailable) {
            updateDocset(doc.id);
            break; // Downloader handles sequential queue
        }
    }
}

void DocsetManager::removeDocset(const QString& id) {
    for (int i = 0; i < m_installedList.size(); ++i) {
        if (m_installedList.at(i).id == id) {
            QString path = m_installedList.at(i).localPath;
            beginRemoveRows(QModelIndex(), i, i);
            m_installedList.removeAt(i);
            endRemoveRows();

            m_searchEngine->unregisterDocset(id);
            m_catalogMgr->setInstalledStatus(id, false, "", false, false);

            // Delete folder from disk in thread
            QDir dir(path);
            if (dir.exists()) {
                dir.removeRecursively();
            }

            saveInstalledRegistry();
            emit installedCountChanged();
            emit storageUsageChanged();
            emit docsetRemoved(id);
            break;
        }
    }
}

void DocsetManager::setTrackLatest(const QString& id, bool trackLatest) {
    for (int i = 0; i < m_installedList.size(); ++i) {
        if (m_installedList.at(i).id == id) {
            m_installedList[i].trackLatest = trackLatest;
            QModelIndex idx = index(i);
            emit dataChanged(idx, idx, {TrackLatestRole});
            saveInstalledRegistry();
            m_catalogMgr->setInstalledStatus(id, true, m_installedList[i].installedVersion, trackLatest, m_installedList[i].updateAvailable);
            break;
        }
    }
}

void DocsetManager::checkForUpdates() {
    if (m_isCheckingUpdates) return;
    m_isCheckingUpdates = true;
    emit isCheckingUpdatesChanged();

    for (int i = 0; i < m_installedList.size(); ++i) {
        auto& doc = m_installedList[i];
        doc.lastChecked = QDateTime::currentDateTime();

        if (doc.trackLatest) {
            QString latest = m_catalogMgr->getLatestVersion(doc.id);
            if (!latest.isEmpty() && latest != doc.installedVersion) {
                doc.updateAvailable = true;
                doc.availableVersion = latest;
                emit updateFound(doc.id, latest);
            } else {
                doc.updateAvailable = false;
            }
        } else {
            doc.updateAvailable = false;
        }

        QModelIndex idx = index(i);
        emit dataChanged(idx, idx, {LastCheckedRole, UpdateAvailableRole, AvailableVersionRole});
        m_catalogMgr->setInstalledStatus(doc.id, true, doc.installedVersion, doc.trackLatest, doc.updateAvailable);
    }

    saveInstalledRegistry();
    m_isCheckingUpdates = false;
    emit isCheckingUpdatesChanged();
}

QVariantMap DocsetManager::getInstalledDocset(const QString& id) const {
    QVariantMap map;
    for (const auto& doc : m_installedList) {
        if (doc.id == id) {
            map["id"] = doc.id;
            map["name"] = doc.name;
            map["installedVersion"] = doc.installedVersion;
            map["trackLatest"] = doc.trackLatest;
            map["localPath"] = doc.localPath;
            map["indexPath"] = doc.indexPath;
            map["dsidxPath"] = doc.dsidxPath;
            map["sizeFormatted"] = formatBytes(doc.sizeBytes);
            map["updateAvailable"] = doc.updateAvailable;
            map["availableVersion"] = doc.availableVersion;
            break;
        }
    }
    return map;
}

void DocsetManager::onDownloadProgress(const QString& id, qreal progress, const QString& speedStr) {
    m_catalogMgr->setDownloadProgress(id, true, progress, speedStr);
}

void DocsetManager::onDownloadCompleted(const QString& id, const QString& version, bool trackLatest, const QString& extractedDir) {
    m_catalogMgr->setDownloadProgress(id, false, 1.0, "");

    // Locate docSet.dsidx and documents folder
    QString dsidxPath;
    QString documentsDir;
    QString indexPath;

    QDirIterator it(extractedDir, QStringList() << "*.dsidx", QDir::Files, QDirIterator::Subdirectories);
    if (it.hasNext()) {
        dsidxPath = it.next();
        QFileInfo dsidxInfo(dsidxPath);
        QDir resDir = dsidxInfo.dir(); // Contents/Resources
        if (resDir.exists("Documents")) {
            documentsDir = resDir.filePath("Documents");
        } else {
            documentsDir = resDir.absolutePath();
        }
    } else {
        documentsDir = extractedDir;
    }

    // Locate index.html
    if (QFile::exists(documentsDir + "/index.html")) {
        indexPath = documentsDir + "/index.html";
    } else {
        QDirIterator htmlIt(documentsDir, QStringList() << "*.html", QDir::Files, QDirIterator::Subdirectories);
        if (htmlIt.hasNext()) {
            indexPath = htmlIt.next();
        }
    }

    // Check if item already installed -> update existing record
    int existingIndex = -1;
    for (int i = 0; i < m_installedList.size(); ++i) {
        if (m_installedList.at(i).id == id) {
            existingIndex = i;
            break;
        }
    }

    InstalledDocset doc;
    doc.id = id;
    doc.name = m_catalogMgr->getItem(0)["id"] == id ? m_catalogMgr->getItem(0)["name"].toString() : id;
    // Look up display name from catalog
    for (int r = 0; r < m_catalogMgr->rowCount(); ++r) {
        if (m_catalogMgr->data(m_catalogMgr->index(r), DocCatalogManager::IdRole).toString() == id) {
            doc.name = m_catalogMgr->data(m_catalogMgr->index(r), DocCatalogManager::NameRole).toString();
            break;
        }
    }
    doc.installedVersion = version;
    doc.trackLatest = trackLatest;
    doc.localPath = extractedDir;
    doc.indexPath = indexPath;
    doc.dsidxPath = dsidxPath;
    doc.logoPath = extractedDir + "/logo.svg";
    doc.sizeBytes = calculateDirectorySize(extractedDir);
    doc.installedAt = QDateTime::currentDateTime();
    doc.lastChecked = QDateTime::currentDateTime();
    doc.updateAvailable = false;

    if (existingIndex >= 0) {
        m_installedList[existingIndex] = doc;
        QModelIndex idx = index(existingIndex);
        emit dataChanged(idx, idx);
    } else {
        beginInsertRows(QModelIndex(), m_installedList.size(), m_installedList.size());
        m_installedList.append(doc);
        endInsertRows();
    }

    registerWithSearchEngine(doc);
    saveInstalledRegistry();

    // Asynchronously download official SVG logo from coldmanual-db for reader & offline display
    QString logoDest = doc.logoPath;
    QUrl logoUrl(QString("https://raw.githubusercontent.com/falconwasplaying/coldmanual-db/main/logos/%1.svg").arg(id));
    QNetworkRequest logoReq(logoUrl);
    logoReq.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    logoReq.setHeader(QNetworkRequest::UserAgentHeader, "ColdManual/1.0");

    auto* logoReply = m_networkManager.get(logoReq);
    connect(logoReply, &QNetworkReply::finished, this, [this, logoReply, id, logoDest]() {
        if (logoReply->error() == QNetworkReply::NoError) {
            QFile file(logoDest);
            if (file.open(QIODevice::WriteOnly)) {
                file.write(logoReply->readAll());
                file.close();
            }
            for (int i = 0; i < m_installedList.size(); ++i) {
                if (m_installedList[i].id == id) {
                    m_installedList[i].logoPath = logoDest;
                    QModelIndex idx = index(i);
                    emit dataChanged(idx, idx, {LogoPathRole});
                    saveInstalledRegistry();
                    break;
                }
            }
        }
        logoReply->deleteLater();
    });

    m_catalogMgr->setInstalledStatus(id, true, version, trackLatest, false);

    emit installedCountChanged();
    emit storageUsageChanged();
    emit docsetInstalled(id, doc.name);
}

void DocsetManager::onDownloadFailed(const QString& id, const QString& errorMessage) {
    m_catalogMgr->setDownloadProgress(id, false, 0.0, "");
    qWarning() << "Download failed for" << id << ":" << errorMessage;
}

void DocsetManager::loadInstalledRegistry() {
    QString regPath = m_settingsMgr->storagePath() + "/installed.json";
    QFile file(regPath);
    if (file.open(QIODevice::ReadOnly)) {
        QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
        if (doc.isArray()) {
            beginResetModel();
            m_installedList.clear();
            const auto arr = doc.array();
            for (const auto& val : arr) {
                InstalledDocset item = InstalledDocset::fromJson(val.toObject());
                // Verify directory still exists
                if (QDir(item.localPath).exists()) {
                    m_installedList.append(item);
                    registerWithSearchEngine(item);
                    m_catalogMgr->setInstalledStatus(item.id, true, item.installedVersion, item.trackLatest, item.updateAvailable);
                }
            }
            endResetModel();
        }
        file.close();
    }

    emit installedCountChanged();
    emit storageUsageChanged();
}

void DocsetManager::saveInstalledRegistry() {
    QString regPath = m_settingsMgr->storagePath() + "/installed.json";
    QFile file(regPath);
    if (file.open(QIODevice::WriteOnly)) {
        QJsonArray arr;
        for (const auto& doc : m_installedList) {
            arr.append(doc.toJson());
        }
        QJsonDocument jDoc(arr);
        file.write(jDoc.toJson(QJsonDocument::Indented));
        file.close();
    }
}

void DocsetManager::registerWithSearchEngine(const InstalledDocset& doc) {
    if (!doc.dsidxPath.isEmpty() && QFile::exists(doc.dsidxPath)) {
        QFileInfo info(doc.dsidxPath);
        QDir resDir = info.dir();
        QString docDir = resDir.exists("Documents") ? resDir.filePath("Documents") : resDir.absolutePath();
        m_searchEngine->registerDocset(doc.id, doc.name, doc.dsidxPath, docDir);
    }
}

qint64 DocsetManager::calculateDirectorySize(const QString& dirPath) {
    qint64 size = 0;
    QDir dir(dirPath);
    QFileInfoList list = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden);
    for (const auto& fileInfo : list) {
        if (fileInfo.isDir()) {
            size += calculateDirectorySize(fileInfo.absoluteFilePath());
        } else {
            size += fileInfo.size();
        }
    }
    return size;
}

QString DocsetManager::formatBytes(qint64 bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
        return QString("%1 GB").arg(bytes / (1024.0 * 1024.0 * 1024.0), 0, 'f', 1);
    }
    if (bytes >= 1024 * 1024) {
        return QString("%1 MB").arg(bytes / (1024.0 * 1024.0), 0, 'f', 1);
    }
    if (bytes >= 1024) {
        return QString("%1 KB").arg(bytes / 1024.0, 0, 'f', 0);
    }
    return QString("%1 B").arg(bytes);
}

void DocsetManager::setupAutoUpdateTimer() {
    connect(&m_autoUpdateTimer, &QTimer::timeout, this, [this]() {
        if (m_settingsMgr->autoUpdateEnabled()) {
            checkForUpdates();
        }
    });

    int intervalMs = m_settingsMgr->checkIntervalHours() * 3600 * 1000;
    if (intervalMs <= 0) intervalMs = 24 * 3600 * 1000;
    m_autoUpdateTimer.start(intervalMs);

    // Initial check after startup
    QTimer::singleShot(5000, this, [this]() {
        if (m_settingsMgr->autoUpdateEnabled()) {
            checkForUpdates();
        }
    });
}
