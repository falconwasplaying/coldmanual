#include "DocsetSearchEngine.h"
#include <QSqlError>
#include <QFileInfo>
#include <QDir>
#include <QUrl>
#include <QRegularExpression>
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
        return db;
    }

    // Check if searchIndex table or view exists; if not, create TEMP VIEW from CoreData schema (ZTOKEN)
    QSqlQuery check(db);
    check.exec("SELECT 1 FROM sqlite_master WHERE type IN ('table', 'view') AND name = 'searchIndex'");
    if (!check.next()) {
        QSqlQuery zCheck(db);
        zCheck.exec("SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'ZTOKEN'");
        if (zCheck.next()) {
            QSqlQuery createView(db);
            createView.exec(
                "CREATE TEMP VIEW IF NOT EXISTS searchIndex AS "
                "SELECT "
                "  t.Z_PK as id, "
                "  t.ZTOKENNAME as name, "
                "  CASE ty.ZTYPENAME "
                "    WHEN 'cl' THEN 'Class' "
                "    WHEN 'clm' THEN 'Method' "
                "    WHEN 'func' THEN 'Function' "
                "    WHEN 'tdef' THEN 'Type' "
                "    WHEN 'macro' THEN 'Macro' "
                "    WHEN 'clconst' THEN 'Constant' "
                "    WHEN 'instp' THEN 'Property' "
                "    WHEN 'Guide' THEN 'Guide' "
                "    WHEN 'File' THEN 'Header' "
                "    WHEN 'Enum' THEN 'Enum' "
                "    WHEN 'Struct' THEN 'Struct' "
                "    WHEN 'Operator' THEN 'Operator' "
                "    ELSE COALESCE(ty.ZTYPENAME, 'Symbol') "
                "  END as type, "
                "  CASE "
                "    WHEN m.ZANCHOR IS NOT NULL AND m.ZANCHOR != '' THEN f.ZPATH || '#' || m.ZANCHOR "
                "    ELSE f.ZPATH "
                "  END as path "
                "FROM ZTOKEN t "
                "LEFT JOIN ZTOKENTYPE ty ON t.ZTOKENTYPE = ty.Z_PK "
                "LEFT JOIN ZTOKENMETAINFORMATION m ON t.ZMETAINFORMATION = m.Z_PK "
                "LEFT JOIN ZFILEPATH f ON m.ZFILE = f.Z_PK"
            );
        }
    }

    return db;
}

static QString cleanDocsetPath(QString path) {
    // Strip <dash_entry_name=...> prefix tags commonly found in CoreData docsets
    static const QRegularExpression dashTagRe("<[^>]+>");
    return path.remove(dashTagRe);
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
                item.relativePath = cleanDocsetPath(q.value(2).toString());

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
    q.prepare("SELECT type, count(*) FROM searchIndex WHERE type IS NOT NULL AND type != '' GROUP BY type ORDER BY count(*) DESC");
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
    return getSymbolsFiltered(docsetId, type, "", limit);
}

QVariantList DocsetSearchEngine::getSymbolsFiltered(const QString& docsetId, const QString& type, const QString& filterText, int limit) {
    QVariantList list;
    if (!m_registeredDocsets.contains(docsetId)) return list;

    const auto& info = m_registeredDocsets[docsetId];
    QSqlDatabase db = getDatabase(docsetId);
    if (!db.isOpen()) return list;

    QString trimmedFilter = filterText.trimmed();
    bool isAll = type.isEmpty() || type.compare("All", Qt::CaseInsensitive) == 0;

    QString queryStr = "SELECT name, path, type FROM searchIndex WHERE 1=1";
    if (!isAll) {
        queryStr += " AND type = :type";
    }
    if (!trimmedFilter.isEmpty()) {
        queryStr += " AND name LIKE :filter";
    }
    queryStr += " ORDER BY name ASC LIMIT :lim";

    QSqlQuery q(db);
    q.prepare(queryStr);
    if (!isAll) {
        q.bindValue(":type", type);
    }
    if (!trimmedFilter.isEmpty()) {
        q.bindValue(":filter", "%" + trimmedFilter + "%");
    }
    q.bindValue(":lim", limit);

    if (q.exec()) {
        while (q.next()) {
            QVariantMap map;
            map["name"] = q.value(0).toString();
            QString rawPath = cleanDocsetPath(q.value(1).toString());
            map["path"] = rawPath;
            map["type"] = q.value(2).toString();
            map["fullFilePath"] = info.documentsDir + "/" + rawPath;
            list.append(map);
        }
    } else {
        qWarning() << "getSymbolsFiltered query error:" << q.lastError().text();
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

QString DocsetSearchEngine::prepareHtmlForReader(const QString& rawHtml, bool isDark) {
    if (rawHtml.isEmpty()) return QString();

    QString html = rawHtml;

    // 1. Remove all scripts to avoid syntax/execution overhead
    static const QRegularExpression scriptRe("<script\\b[^<]*(?:(?!<\\/script>)<[^<]*)*<\\/script>", QRegularExpression::CaseInsensitiveOption);
    html.remove(scriptRe);

    // 2. Remove web chrome (MediaWiki top bar, search form, tabs, footer)
    static const QRegularExpression mwHeadRe("<!--\\s*header\\s*-->[\\s\\S]*?<!--\\s*\\/header\\s*-->", QRegularExpression::CaseInsensitiveOption);
    html.remove(mwHeadRe);

    static const QRegularExpression headBaseRe("<div\\s+id=\"cpp-head-[\\s\\S]*?<div\\s+id=\"cpp-content-base\">", QRegularExpression::CaseInsensitiveOption);
    html.replace(headBaseRe, "<div id=\"cpp-content-base\">");

    static const QRegularExpression mwFooterRe("<!--\\s*footer\\s*-->[\\s\\S]*?<!--\\s*\\/footer\\s*-->", QRegularExpression::CaseInsensitiveOption);
    html.remove(mwFooterRe);

    // 3. Neutralize conflicting hardcoded white background styles in docset HTML
    static const QRegularExpression bodyBgRe("body\\s*\\{[^}]*background:[^}]*\\}", QRegularExpression::CaseInsensitiveOption);
    html.remove(bodyBgRe);

    static const QRegularExpression whiteBgRe("background:\\s*white\\s*!important", QRegularExpression::CaseInsensitiveOption);
    html.remove(whiteBgRe);

    static const QRegularExpression hexFffRe("background:\\s*#(fff|ffffff)\\b", QRegularExpression::CaseInsensitiveOption);
    html.remove(hexFffRe);

    // Neutralize inline background styles on tables or containers like fmbox
    static const QRegularExpression inlineBgRe("style=\"[^\"]*background:[^\"]*\"", QRegularExpression::CaseInsensitiveOption);
    html.remove(inlineBgRe);

    // 4. Inject modern high-contrast theme CSS
    QString bgColor = isDark ? "#141416" : "#ffffff";
    QString textColor = isDark ? "#e4e4e7" : "#18181b";
    QString linkColor = isDark ? "#38bdf8" : "#0284c7";
    QString codeBg = isDark ? "#1c1c21" : "#f1f5f9";
    QString borderColor = isDark ? "#27272a" : "#e2e8f0";
    QString tableHeaderBg = isDark ? "#1f1f23" : "#f8fafc";
    QString trEvenBg = isDark ? "#18181b" : "#fbfcfd";

    QString modernStyle = QString(
        "<style type=\"text/css\">\n"
        "  html, body { background-color: %1 !important; color: %2 !important; font-family: Segoe UI, -apple-system, BlinkMacSystemFont, sans-serif !important; line-height: 1.6 !important; margin: 0 !important; padding: 20px 24px !important; }\n"
        "  div#content, div#cpp-content-base, div.mw-body, div#bodyContent { background-color: transparent !important; color: inherit !important; width: 100% !important; margin: 0 !important; padding: 0 !important; }\n"
        "  h1, h2, h3, h4, h5, h6, .firstHeading { color: %3 !important; font-weight: 600 !important; border-bottom: 1px solid %4 !important; padding-bottom: 6px !important; margin-top: 24px !important; margin-bottom: 12px !important; }\n"
        "  a, a:visited { color: %5 !important; text-decoration: none !important; }\n"
        "  a:hover { text-decoration: underline !important; }\n"
        "  code, tt, kbd, samp { font-family: Cascadia Code, Consolas, Monaco, monospace !important; background-color: %6 !important; color: %7 !important; border-radius: 4px !important; padding: 2px 6px !important; font-size: 0.9em !important; }\n"
        "  pre, .mw-code, div.mw-geshi { font-family: Cascadia Code, Consolas, Monaco, monospace !important; background-color: %6 !important; color: %2 !important; border: 1px solid %4 !important; border-radius: 6px !important; padding: 14px !important; line-height: 1.45 !important; overflow-x: auto !important; margin: 12px 0 !important; }\n"
        "  table, .t-dsc-begin, .t-dcl-begin { border-collapse: collapse !important; width: 100% !important; margin: 14px 0 !important; border: 1px solid %4 !important; }\n"
        "  th { background-color: %8 !important; color: %3 !important; font-weight: 600 !important; border: 1px solid %4 !important; padding: 8px 12px !important; text-align: left !important; }\n"
        "  td, .t-dsc, .t-dcl { border: 1px solid %4 !important; padding: 8px 12px !important; color: %2 !important; }\n"
        "  tr:nth-child(even) { background-color: %9 !important; }\n"
        "  .t-lines { background: transparent !important; }\n"
        "  p, ul, ol, li, dt, dd { color: %2 !important; line-height: 1.6 !important; }\n"
        "  .t-mark-rev { border-radius: 3px !important; padding: 1px 4px !important; font-size: 0.85em !important; opacity: 0.85 !important; }\n"
        "</style>\n"
    ).arg(bgColor, textColor, (isDark ? "#ffffff" : "#09090b"), borderColor, linkColor, codeBg, (isDark ? "#fb7185" : "#e11d48"), tableHeaderBg, trEvenBg);

    // Insert modern styling right after <head> or at top
    int headPos = html.indexOf("<head>", 0, Qt::CaseInsensitive);
    if (headPos >= 0) {
        html.insert(headPos + 6, "\n" + modernStyle);
    } else {
        html.prepend(modernStyle);
    }

    return html;
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
