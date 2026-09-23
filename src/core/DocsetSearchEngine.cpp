#include "DocsetSearchEngine.h"
#include <QSqlError>
#include <QFileInfo>
#include <QDir>
#include <QUrl>
#include <QDebug>

DocsetSearchEngine::DocsetSearchEngine(QObject* parent)
    : QAbstractListModel(parent)
{
}

DocsetSearchEngine::~DocsetSearchEngine() {
    for (auto it = m_registeredDocsets.begin(); it != m_registeredDocsets.end(); ++it) {
        if (QSqlDatabase::contains(it.value().connectionName)) {
            QSqlDatabase::removeDatabase(it.value().connectionName);
        }
    }
}

int DocsetSearchEngine::rowCount(const QModelIndex& parent) const {
    if (parent.isValid()) return 0;
    return m_results.size();
}

QHash<int, QByteArray> DocsetSearchEngine::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[DocsetIdRole] = "docsetId";
    roles[DocsetNameRole] = "docsetName";
    roles[NameRole] = "name";
    roles[TypeRole] = "type";
    roles[RelativePathRole] = "relativePath";
    roles[FullFilePathRole] = "fullFilePath";
    return roles;
}

QVariant DocsetSearchEngine::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_results.size()) {
        return QVariant();
    }

    const auto& item = m_results.at(index.row());
    switch (role) {
    case DocsetIdRole: return item.docsetId;
    case DocsetNameRole: return item.docsetName;
    case NameRole: return item.name;
    case TypeRole: return item.type;
    case RelativePathRole: return item.relativePath;
    case FullFilePathRole: return item.fullFilePath;
    default:
        return QVariant();
    }
}

void DocsetSearchEngine::setQuery(const QString& query) {
    if (m_query != query) {
        m_query = query;
        emit queryChanged();
        executeSearch();
    }
}

void DocsetSearchEngine::registerDocset(const QString& docsetId, const QString& docsetName, const QString& dsidxPath, const QString& documentsDir) {
    DocsetDbInfo info;
    info.docsetName = docsetName;
    info.dsidxPath = dsidxPath;
    info.documentsDir = documentsDir;
    info.connectionName = "coldmanual_docset_" + docsetId;
    m_registeredDocsets[docsetId] = info;
}

void DocsetSearchEngine::unregisterDocset(const QString& docsetId) {
    if (m_registeredDocsets.contains(docsetId)) {
        QString conn = m_registeredDocsets[docsetId].connectionName;
        m_registeredDocsets.remove(docsetId);
        if (QSqlDatabase::contains(conn)) {
            QSqlDatabase::removeDatabase(conn);
        }
    }
}

QSqlDatabase DocsetSearchEngine::getDatabase(const QString& docsetId) {
    if (!m_registeredDocsets.contains(docsetId)) {
        return QSqlDatabase();
    }

    const auto& info = m_registeredDocsets[docsetId];
    if (QSqlDatabase::contains(info.connectionName)) {
        auto db = QSqlDatabase::database(info.connectionName);
        if (db.isOpen()) return db;
    }

    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", info.connectionName);
    db.setDatabaseName(info.dsidxPath);
    if (!db.open()) {
        qWarning() << "Failed to open docset db" << info.dsidxPath << ":" << db.lastError().text();
    }
    return db;
}

void DocsetSearchEngine::executeSearch() {
    beginResetModel();
    m_results.clear();

    QString trimmed = m_query.trimmed();
    if (trimmed.isEmpty()) {
        endResetModel();
        emit resultCountChanged();
        return;
    }

    m_isSearching = true;
    emit isSearchingChanged();

    for (auto it = m_registeredDocsets.begin(); it != m_registeredDocsets.end(); ++it) {
        const QString& docsetId = it.key();
        const auto& info = it.value();

        QSqlDatabase db = getDatabase(docsetId);
        if (!db.isOpen()) continue;

        QSqlQuery q(db);
        // Prefix search or substring search
        q.prepare("SELECT name, type, path FROM searchIndex WHERE name LIKE :pattern ORDER BY (name LIKE :prefixPattern) DESC, length(name) ASC LIMIT 30");
        q.bindValue(":pattern", "%" + trimmed + "%");
        q.bindValue(":prefixPattern", trimmed + "%");

        if (q.exec()) {
            while (q.next()) {
                SearchResultItem item;
                item.docsetId = docsetId;
                item.docsetName = info.docsetName;
                item.name = q.value(0).toString();
                item.type = q.value(1).toString();
                item.relativePath = q.value(2).toString();

                QString rel = item.relativePath;
                // Path might contain URL anchor fragment (#...)
                QString anchor = "";
                int hashIdx = rel.indexOf('#');
                if (hashIdx >= 0) {
                    anchor = rel.mid(hashIdx);
                    rel = rel.left(hashIdx);
                }

                item.fullFilePath = info.documentsDir + "/" + rel + anchor;
                m_results.append(item);

                if (m_results.size() >= 80) break;
            }
        } else {
            qWarning() << "Search query error:" << q.lastError().text();
        }

        if (m_results.size() >= 80) break;
    }

    m_isSearching = false;
    emit isSearchingChanged();
    endResetModel();
    emit resultCountChanged();
}

QVariantList DocsetSearchEngine::getSymbolTypes(const QString& docsetId) {
    QVariantList list;
    QSqlDatabase db = getDatabase(docsetId);
    if (!db.isOpen()) return list;

    QSqlQuery q(db);
    q.prepare("SELECT type, count(*) FROM searchIndex GROUP BY type ORDER BY count(*) DESC");
    if (q.exec()) {
        while (q.next()) {
            QVariantMap map;
            map["type"] = q.value(0).toString();
            map["count"] = q.value(1).toInt();
            list.append(map);
        }
    }
    return list;
}

QVariantList DocsetSearchEngine::getSymbolsByType(const QString& docsetId, const QString& type, int limit) {
    QVariantList list;
    if (!m_registeredDocsets.contains(docsetId)) return list;

    const auto& info = m_registeredDocsets[docsetId];
    QSqlDatabase db = getDatabase(docsetId);
    if (!db.isOpen()) return list;

    QSqlQuery q(db);
    q.prepare("SELECT name, path FROM searchIndex WHERE type = :type ORDER BY name ASC LIMIT :lim");
    q.bindValue(":type", type);
    q.bindValue(":lim", limit);

    if (q.exec()) {
        while (q.next()) {
            QVariantMap map;
            map["name"] = q.value(0).toString();
            map["path"] = q.value(1).toString();
            map["fullFilePath"] = info.documentsDir + "/" + q.value(1).toString();
            list.append(map);
        }
    }
    return list;
}

QVariantMap DocsetSearchEngine::getResult(int index) const {
    QVariantMap map;
    if (index >= 0 && index < m_results.size()) {
        const auto& item = m_results.at(index);
        map["docsetId"] = item.docsetId;
        map["docsetName"] = item.docsetName;
        map["name"] = item.name;
        map["type"] = item.type;
        map["relativePath"] = item.relativePath;
        map["fullFilePath"] = item.fullFilePath;
    }
    return map;
}

QString DocsetSearchEngine::readFileContent(const QString& filePath) {
    QString cleanPath = filePath;
    // Strip URL anchor fragment if present
    int hashIdx = cleanPath.indexOf('#');
    if (hashIdx >= 0) {
        cleanPath = cleanPath.left(hashIdx);
    }

    if (cleanPath.startsWith("file:///")) {
        cleanPath = QUrl(cleanPath).toLocalFile();
    }

    QFile file(cleanPath);
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return QString::fromUtf8(file.readAll());
    }
    return QString();
}
