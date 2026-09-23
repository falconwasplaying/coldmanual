#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QAbstractListModel>

struct SearchResultItem {
    QString docsetId;
    QString docsetName;
    QString name;
    QString type;
    QString relativePath;
    QString fullFilePath;
};

class DocsetSearchEngine : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged)
    Q_PROPERTY(int resultCount READ resultCount NOTIFY resultCountChanged)
    Q_PROPERTY(bool isSearching READ isSearching NOTIFY isSearchingChanged)

public:
    enum SearchRoles {
        DocsetIdRole = Qt::UserRole + 1,
        DocsetNameRole,
        NameRole,
        TypeRole,
        RelativePathRole,
        FullFilePathRole
    };

    explicit DocsetSearchEngine(QObject* parent = nullptr);
    ~DocsetSearchEngine();

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString query() const { return m_query; }
    void setQuery(const QString& query);

    int resultCount() const { return m_results.size(); }
    bool isSearching() const { return m_isSearching; }

    void registerDocset(const QString& docsetId, const QString& docsetName, const QString& dsidxPath, const QString& documentsDir);
    void unregisterDocset(const QString& docsetId);

    // Sidebar navigation helpers
    Q_INVOKABLE QVariantList getSymbolTypes(const QString& docsetId);
    Q_INVOKABLE QVariantList getSymbolsByType(const QString& docsetId, const QString& type, int limit = 100);
    Q_INVOKABLE QVariantMap getResult(int index) const;
    Q_INVOKABLE QString readFileContent(const QString& filePath);

signals:
    void queryChanged();
    void resultCountChanged();
    void isSearchingChanged();

private:
    struct DocsetDbInfo {
        QString docsetName;
        QString dsidxPath;
        QString documentsDir;
        QString connectionName;
    };

    QString m_query;
    bool m_isSearching{false};
    QList<SearchResultItem> m_results;
    QMap<QString, DocsetDbInfo> m_registeredDocsets;

    void executeSearch();
    QSqlDatabase getDatabase(const QString& docsetId);
};
