#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QQuickStyle>

#include "core/SettingsManager.h"
#include "core/DocCatalogManager.h"
#include "core/DocsetDownloader.h"
#include "core/DocsetSearchEngine.h"
#include "core/DocsetManager.h"

int main(int argc, char* argv[]) {
    QGuiApplication::setOrganizationName("ColdManual");
    QGuiApplication::setApplicationName("ColdManual");
    QGuiApplication::setApplicationVersion("1.0.0");

    QQuickStyle::setStyle("Basic");

    QGuiApplication app(argc, argv);

    // Initialize backend core singletons
    SettingsManager settingsMgr;
    DocCatalogManager catalogMgr;
    DocsetDownloader downloader;
    DocsetSearchEngine searchEngine;
    DocsetManager docsetMgr(&catalogMgr, &downloader, &searchEngine, &settingsMgr);

    QQmlApplicationEngine engine;

    // Expose backend instances to QML root context
    auto* ctx = engine.rootContext();
    ctx->setContextProperty("settingsMgr", &settingsMgr);
    ctx->setContextProperty("catalogMgr", &catalogMgr);
    ctx->setContextProperty("downloader", &downloader);
    ctx->setContextProperty("searchEngine", &searchEngine);
    ctx->setContextProperty("docsetMgr", &docsetMgr);

    qDebug() << "ColdManual starting...";

    // Connect to QML warnings
    QObject::connect(&engine, &QQmlApplicationEngine::warnings, [](const QList<QQmlError>& warnings) {
        for (const auto& w : warnings) {
            qWarning() << "QML Error:" << w.toString();
        }
    });

    // Add resource root to import path
    engine.addImportPath("qrc:/");

    // Load main QML
    const QUrl url(QStringLiteral("qrc:/Main.qml"));
    qDebug() << "Loading QML from:" << url;

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject* obj, const QUrl& objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "FATAL: Failed to load QML root object from" << url;
            QCoreApplication::exit(-1);
        } else {
            qDebug() << "Successfully loaded root QML object:" << obj;
        }
    }, Qt::QueuedConnection);

    engine.load(url);
    qDebug() << "After engine.load, rootObjects count:" << engine.rootObjects().count();

    int ret = app.exec();
    qDebug() << "Application exited with code:" << ret;
    return ret;
}
