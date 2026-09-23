#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QPalette>
#include <QColor>

#ifdef Q_OS_WIN
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <dwmapi.h>
#endif

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

    const bool isDark = (settingsMgr.themeMode() != "light");
    const QColor initialBgColor = isDark ? QColor("#121214") : QColor("#f8fafc");

    // Apply global palette immediately to prevent native Windows OS white flashbang on window creation
    QPalette globalPalette;
    globalPalette.setColor(QPalette::Window, initialBgColor);
    globalPalette.setColor(QPalette::WindowText, isDark ? QColor("#f4f4f5") : QColor("#0f172a"));
    globalPalette.setColor(QPalette::Base, initialBgColor);
    globalPalette.setColor(QPalette::AlternateBase, isDark ? QColor("#18181b") : QColor("#f1f5f9"));
    globalPalette.setColor(QPalette::Text, isDark ? QColor("#f4f4f5") : QColor("#0f172a"));
    globalPalette.setColor(QPalette::Button, isDark ? QColor("#202024") : QColor("#ffffff"));
    globalPalette.setColor(QPalette::ButtonText, isDark ? QColor("#f4f4f5") : QColor("#0f172a"));
    globalPalette.setColor(QPalette::Highlight, isDark ? QColor("#38bdf8") : QColor("#0284c7"));
    globalPalette.setColor(QPalette::HighlightedText, Qt::white);
    QGuiApplication::setPalette(globalPalette);

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

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "FATAL: Failed to load QML root object from" << url;
        return -1;
    }

    auto* rootObj = engine.rootObjects().first();
    if (auto* window = qobject_cast<QQuickWindow*>(rootObj)) {
        window->setColor(initialBgColor);

#ifdef Q_OS_WIN
        HWND hwnd = reinterpret_cast<HWND>(window->winId());
        if (hwnd) {
            // 1. Assign dark background brush to Win32 window class so Windows never paints white on erase
            HBRUSH winBrush = CreateSolidBrush(RGB(initialBgColor.red(), initialBgColor.green(), initialBgColor.blue()));
            SetClassLongPtr(hwnd, GCLP_HBRBACKGROUND, reinterpret_cast<LONG_PTR>(winBrush));

            // 2. Enable Windows 10/11 Immersive Dark Mode for native title bar
            if (isDark) {
                BOOL darkMode = TRUE;
                DwmSetWindowAttribute(hwnd, 20, &darkMode, sizeof(darkMode)); // Windows 10 build 18985+ and Windows 11
                DwmSetWindowAttribute(hwnd, 19, &darkMode, sizeof(darkMode)); // Older Windows 10 builds
            }
        }
#endif

        window->show();
    }

    int ret = app.exec();
    qDebug() << "Application exited with code:" << ret;
    return ret;
}
