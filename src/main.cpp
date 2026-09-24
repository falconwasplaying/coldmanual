#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QPalette>
#include <QColor>
#include <QTimer>
#include <memory>

#ifdef Q_OS_WIN
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <dwmapi.h>

#ifndef DWMWA_CLOAK
#define DWMWA_CLOAK 13
#endif
#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif
#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE_OLD
#define DWMWA_USE_IMMERSIVE_DARK_MODE_OLD 19
#endif
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
            // 1. Cloak the window from DWM desktop composition before showing so Windows never composites unrendered white frames
            BOOL cloak = TRUE;
            DwmSetWindowAttribute(hwnd, DWMWA_CLOAK, &cloak, sizeof(cloak));

            // 2. Assign dark background brush to Win32 window class
            HBRUSH winBrush = CreateSolidBrush(RGB(initialBgColor.red(), initialBgColor.green(), initialBgColor.blue()));
            SetClassLongPtr(hwnd, GCLP_HBRBACKGROUND, reinterpret_cast<LONG_PTR>(winBrush));

            // 3. Enable Windows 10/11 Immersive Dark Mode for native title bar
            if (isDark) {
                BOOL darkMode = TRUE;
                DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &darkMode, sizeof(darkMode)); // Windows 10 build 18985+ and Windows 11
                DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE_OLD, &darkMode, sizeof(darkMode)); // Older Windows 10 builds
            }
        }
#endif

        window->show();

#ifdef Q_OS_WIN
        if (hwnd) {
            auto connection = std::make_shared<QMetaObject::Connection>();
            *connection = QObject::connect(window, &QQuickWindow::frameSwapped, window, [hwnd, connection]() {
                QObject::disconnect(*connection);
                BOOL uncloak = FALSE;
                DwmSetWindowAttribute(hwnd, DWMWA_CLOAK, &uncloak, sizeof(uncloak));
            }, Qt::QueuedConnection);

            // Safety fallback: uncloak after 250ms in case frameSwapped is delayed
            QTimer::singleShot(250, window, [hwnd, connection]() {
                QObject::disconnect(*connection);
                BOOL uncloak = FALSE;
                DwmSetWindowAttribute(hwnd, DWMWA_CLOAK, &uncloak, sizeof(uncloak));
            });
        }
#endif
    }

    int ret = app.exec();
    qDebug() << "Application exited with code:" << ret;
    return ret;
}
