#include <cassert>
#include <iostream>
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>

#include "core/SettingsManager.h"
#include "core/CatalogItem.h"
#include "core/DocCatalogManager.h"
#include "core/DocsetSearchEngine.h"
#include "core/DocsetDownloader.h"
#include "core/DocsetManager.h"

void testCatalogParsing() {
    std::cout << "[TEST] Running testCatalogParsing..." << std::endl;
    DocCatalogManager catalogMgr;
    assert(catalogMgr.rowCount() > 0);
    std::cout << "  Catalog loaded items: " << catalogMgr.rowCount() << std::endl;

    // Filter test
    catalogMgr.setSearchQuery("python");
    assert(catalogMgr.rowCount() == 1);
    QVariantMap item = catalogMgr.getItem(0);
    assert(item["id"].toString() == "python");
    assert(item["name"].toString() == "Python");
    assert(!item["latestVersion"].toString().isEmpty());

    // Category filter test
    catalogMgr.setSearchQuery("");
    catalogMgr.setSelectedCategory("Languages");
    assert(catalogMgr.rowCount() > 0);

    catalogMgr.setSelectedCategory("All");
    assert(catalogMgr.rowCount() > 5);

    // Download URL resolution test
    QString latestReleaseUrl = catalogMgr.getDownloadUrl("python", "Latest Release");
    assert(!latestReleaseUrl.isEmpty());
    QString latestLtsUrl = catalogMgr.getDownloadUrl("python", "Latest LTS");
    assert(!latestLtsUrl.isEmpty());
    QString specificUrl = catalogMgr.getDownloadUrl("python", "3.11");
    assert(!specificUrl.isEmpty());

    // Test structured version list
    QVariant versionsData = catalogMgr.data(catalogMgr.index(0), DocCatalogManager::VersionsRole);
    QVariantList vList = versionsData.toList();
    assert(vList.size() >= 3);
    assert(vList[0].toMap()["text"].toString() == "Latest Release");
    assert(vList[1].toMap()["text"].toString() == "Latest LTS");
    assert(vList[1].toMap()["isLts"].toBool() == true);
    assert(vList[2].toMap()["isDivider"].toBool() == true);

    std::cout << "[PASS] testCatalogParsing passed!" << std::endl;
}

void testSearchEngineWithSqlite() {
    std::cout << "[TEST] Running testSearchEngineWithSqlite..." << std::endl;

    QString testDir = QDir::tempPath() + "/coldmanual_test_docset";
    QDir().mkpath(testDir + "/Contents/Resources/Documents");

    QString dbPath = testDir + "/Contents/Resources/docSet.dsidx";
    {
        QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", "test_setup");
        db.setDatabaseName(dbPath);
        bool ok = db.open();
        assert(ok);

        QSqlQuery q(db);
        q.exec("CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);");
        q.exec("INSERT INTO searchIndex VALUES(1, 'print', 'Function', 'builtins.html#print');");
        q.exec("INSERT INTO searchIndex VALUES(2, 'len', 'Function', 'builtins.html#len');");
        q.exec("INSERT INTO searchIndex VALUES(3, 'list', 'Class', 'builtins.html#list');");
        q.exec("INSERT INTO searchIndex VALUES(4, 'dict', 'Class', 'builtins.html#dict');");
        q.exec("INSERT INTO searchIndex VALUES(5, 'append', 'Method', 'list.html#append');");
        db.close();
    }
    QSqlDatabase::removeDatabase("test_setup");

    // Write dummy HTML
    QFile docFile(testDir + "/Contents/Resources/Documents/builtins.html");
    if (docFile.open(QIODevice::WriteOnly)) {
        docFile.write("<html><body><h1>Builtins</h1><p>Documentation test</p></body></html>");
        docFile.close();
    }

    DocsetSearchEngine searchEngine;
    searchEngine.registerDocset("python", "Python", dbPath, testDir + "/Contents/Resources/Documents");

    // Test symbol query
    searchEngine.setQuery("print");
    assert(searchEngine.rowCount() == 1);
    QVariantMap res = searchEngine.getResult(0);
    assert(res["name"].toString() == "print");
    assert(res["type"].toString() == "Function");

    // Test partial prefix query
    searchEngine.setQuery("le");
    assert(searchEngine.rowCount() >= 1);

    // Test symbol types
    QVariantList types = searchEngine.getSymbolTypes("python");
    assert(types.size() >= 2); // Function, Class, Method

    // Test read file content
    QString content = searchEngine.readFileContent(testDir + "/Contents/Resources/Documents/builtins.html");
    assert(content.contains("Documentation test"));

    // Cleanup
    searchEngine.unregisterDocset("python");
    QDir(testDir).removeRecursively();

    std::cout << "[PASS] testSearchEngineWithSqlite passed!" << std::endl;
}

void testSettingsAndRegistry() {
    std::cout << "[TEST] Running testSettingsAndRegistry..." << std::endl;
    SettingsManager settings;
    settings.setThemeMode("dark");
    assert(settings.themeMode() == "dark");
    settings.setReaderFontSize(18);
    assert(settings.readerFontSize() == 18);
    settings.setAutoUpdateEnabled(true);
    assert(settings.autoUpdateEnabled() == true);
    std::cout << "[PASS] testSettingsAndRegistry passed!" << std::endl;
}

int main(int argc, char* argv[]) {
    QCoreApplication app(argc, argv);

    testCatalogParsing();
    testSearchEngineWithSqlite();
    testSettingsAndRegistry();

    std::cout << "\nALL TESTS PASSED SUCCESSFULLY! (ColdManual Engine Verified)" << std::endl;
    return 0;
}
