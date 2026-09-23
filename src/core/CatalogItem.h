#pragma once

#include <QString>
#include <QStringList>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>

struct CatalogVersion {
    QString version;      // e.g. "3.12", "1.22", "18.2"
    QString downloadUrl;  // Direct download URL
    QString hash;         // SHA256 or etag for change detection
    qint64 sizeBytes{0};  // Archive size
    bool isLatest{false}; // True if this is marked latest stable
};

struct FetchedVersion {
    QString version;      // e.g. "3.12"
    QString displayName;  // e.g. "v3.12"
    bool isLts{false};    // True if Long Term Support
    bool isEol{false};    // True if End of Life / unsupported
    QString releaseDate;
    QString downloadUrl;
};

struct CatalogItem {
    QString id;              // Unique identifier, e.g. "python", "rust", "react"
    QString name;            // Display name, e.g. "Python", "Rust", "React"
    QString category;        // e.g. "Languages", "Frontend", "Backend", "Databases"
    QString description;     // Brief summary
    QString icon;            // Icon name or SVG data
    QString latestVersion;   // Version string for latest stable, e.g. "3.12"
    QList<CatalogVersion> versions; // All selectable versions
    QList<FetchedVersion> fetchedVersions; // Dynamically fetched upstream versions
    QString documentationFormat; // "dash" or "devdocs" or "html"

    static CatalogItem fromJson(const QJsonObject& obj) {
        CatalogItem item;
        item.id = obj["id"].toString();
        item.name = obj["name"].toString();
        item.category = obj["category"].toString("General");
        item.description = obj["description"].toString();
        item.icon = obj["icon"].toString();
        item.latestVersion = obj["latest_version"].toString();
        item.documentationFormat = obj["format"].toString("dash");

        const auto versionsArray = obj["versions"].toArray();
        for (const auto& val : versionsArray) {
            QJsonObject vObj = val.toObject();
            CatalogVersion cv;
            cv.version = vObj["version"].toString();
            cv.downloadUrl = vObj.contains("download_url") ? vObj["download_url"].toString() : vObj["url"].toString();
            cv.hash = vObj.contains("sha256") ? vObj["sha256"].toString() : vObj["hash"].toString();
            cv.sizeBytes = vObj["size_bytes"].toVariant().toLongLong();
            cv.isLatest = vObj["is_latest"].toBool(false);
            if (cv.isLatest && item.latestVersion.isEmpty()) {
                item.latestVersion = cv.version;
            }
            item.versions.append(cv);

            // Populate dynamic fetchedVersions directly from catalog manifest
            FetchedVersion fv;
            fv.version = cv.version;
            fv.displayName = vObj["display_name"].toString();
            if (fv.displayName.isEmpty()) {
                fv.displayName = "v" + fv.version;
            }
            fv.isLts = vObj["is_lts"].toBool(false);
            fv.isEol = vObj["is_eol"].toBool(false);
            fv.releaseDate = vObj["release_date"].toString();
            fv.downloadUrl = cv.downloadUrl;
            item.fetchedVersions.append(fv);
        }

        return item;
    }

    QJsonObject toJson() const {
        QJsonObject obj;
        obj["id"] = id;
        obj["name"] = name;
        obj["category"] = category;
        obj["description"] = description;
        obj["icon"] = icon;
        obj["latest_version"] = latestVersion;
        obj["format"] = documentationFormat;

        QJsonArray vArr;
        for (const auto& v : versions) {
            QJsonObject vObj;
            vObj["version"] = v.version;
            vObj["url"] = v.downloadUrl;
            vObj["hash"] = v.hash;
            vObj["size_bytes"] = v.sizeBytes;
            vObj["is_latest"] = v.isLatest;
            vArr.append(vObj);
        }
        obj["versions"] = vArr;
        return obj;
    }
};

struct InstalledDocset {
    QString id;              // Matches CatalogItem id, e.g. "python"
    QString name;            // Display name, e.g. "Python"
    QString installedVersion;// Specific version installed, e.g. "3.12.1"
    bool trackLatest{false}; // If true, auto-update when newer version is published
    QString localPath;       // Directory on disk
    QString indexPath;       // Relative or absolute path to primary index (e.g. index.html)
    QString dsidxPath;       // SQLite database path if dash format
    QString logoPath;        // Path to downloaded SVG logo on disk
    qint64 sizeBytes{0};     // Disk usage
    QDateTime installedAt;
    QDateTime lastChecked;
    bool updateAvailable{false};
    QString availableVersion;
    QString availableUrl;

    QJsonObject toJson() const {
        QJsonObject obj;
        obj["id"] = id;
        obj["name"] = name;
        obj["installed_version"] = installedVersion;
        obj["track_latest"] = trackLatest;
        obj["local_path"] = localPath;
        obj["index_path"] = indexPath;
        obj["dsidx_path"] = dsidxPath;
        obj["logo_path"] = logoPath;
        obj["size_bytes"] = sizeBytes;
        obj["installed_at"] = installedAt.toString(Qt::ISODate);
        obj["last_checked"] = lastChecked.toString(Qt::ISODate);
        obj["update_available"] = updateAvailable;
        obj["available_version"] = availableVersion;
        obj["available_url"] = availableUrl;
        return obj;
    }

    static InstalledDocset fromJson(const QJsonObject& obj) {
        InstalledDocset doc;
        doc.id = obj["id"].toString();
        doc.name = obj["name"].toString();
        doc.installedVersion = obj["installed_version"].toString();
        doc.trackLatest = obj["track_latest"].toBool(false);
        doc.localPath = obj["local_path"].toString();
        doc.indexPath = obj["index_path"].toString();
        doc.dsidxPath = obj["dsidx_path"].toString();
        doc.logoPath = obj["logo_path"].toString();
        doc.sizeBytes = obj["size_bytes"].toVariant().toLongLong();
        doc.installedAt = QDateTime::fromString(obj["installed_at"].toString(), Qt::ISODate);
        doc.lastChecked = QDateTime::fromString(obj["last_checked"].toString(), Qt::ISODate);
        doc.updateAvailable = obj["update_available"].toBool(false);
        doc.availableVersion = obj["available_version"].toString();
        doc.availableUrl = obj["available_url"].toString();
        return doc;
    }
};
