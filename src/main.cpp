#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QScreen>
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
#ifndef DWMWA_CAPTION_COLOR
#define DWMWA_CAPTION_COLOR 35
#endif
#ifndef DWMWA_TEXT_COLOR
#define DWMWA_TEXT_COLOR 36
#endif
#endif

#include "core/SettingsManager.h"
#include "core/DocCatalogManager.h"
#include "core/DocsetDownloader.h"
#include "core/DocsetSearchEngine.h"
#include "core/DocsetManager.h"
#include "core/NetworkManager.h"

int main(int argc, char* argv[]) {
    QGuiApplication::setOrganizationName("ColdManual");
    QGuiApplication::setApplicationName("ColdManual");
    QGuiApplication::setApplicationDisplayName("ColdManual");
    QGuiApplication::setApplicationVersion("1.0.0");

    QQuickStyle::setStyle("Material");

    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/resources/cmi.svg"));

    // Initialize backend core singletons
    SettingsManager settingsMgr;
    NetworkManager networkMgr;
    DocCatalogManager catalogMgr;
    DocsetDownloader downloader;
    DocsetSearchEngine searchEngine;
    DocsetManager docsetMgr(&catalogMgr, &downloader, &searchEngine, &settingsMgr);

    const bool isDark = (settingsMgr.themeMode() != "light");
    const QColor initialBgColor = isDark ? QColor("#111318") : QColor("#fdf8fd");

    // Apply global palette immediately to prevent native Windows OS white flashbang on window creation
    QPalette globalPalette;
    globalPalette.setColor(QPalette::Window, initialBgColor);
    globalPalette.setColor(QPalette::WindowText, isDark ? QColor("#e2e2e6") : QColor("#191c20"));
    globalPalette.setColor(QPalette::Base, initialBgColor);
    globalPalette.setColor(QPalette::AlternateBase, isDark ? QColor("#191c20") : QColor("#f3f3f8"));
    globalPalette.setColor(QPalette::Text, isDark ? QColor("#e2e2e6") : QColor("#191c20"));
    globalPalette.setColor(QPalette::Button, isDark ? QColor("#282a2f") : QColor("#ededf2"));
    globalPalette.setColor(QPalette::ButtonText, isDark ? QColor("#e2e2e6") : QColor("#191c20"));
    globalPalette.setColor(QPalette::Highlight, isDark ? QColor("#a8c7fa") : QColor("#0b57d0"));
    globalPalette.setColor(QPalette::HighlightedText, isDark ? QColor("#062e6f") : Qt::white);
    QGuiApplication::setPalette(globalPalette);

    QQmlApplicationEngine engine;

    // Expose backend instances to QML root context
    auto* ctx = engine.rootContext();
    ctx->setContextProperty("settingsMgr", &settingsMgr);
    ctx->setContextProperty("networkMgr", &networkMgr);
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
        window->setIcon(QIcon(":/resources/cmi.svg"));

        // 1. Calculate and restore window geometry and state (screen-aware)
        int winX = settingsMgr.windowX();
        int winY = settingsMgr.windowY();
        int winW = settingsMgr.windowWidth();
        int winH = settingsMgr.windowHeight();
        const QString winState = settingsMgr.windowState();
        const QString displayMode = settingsMgr.windowDisplayMode();

        // Apply initial display mode flags
        if (displayMode == "borderless") {
            window->setFlags(Qt::Window | Qt::FramelessWindowHint);
        } else {
            window->setFlags(Qt::Window);
        }

        // Enforce sensible minimums
        winW = std::max(960, winW);
        winH = std::max(640, winH);

        bool onValidScreen = false;
        const QRect targetRect(winX, winY, winW, winH);

        if (winX != -1 && winY != -1) {
            for (QScreen* screen : QGuiApplication::screens()) {
                const QRect avail = screen->availableGeometry();
                if (avail.intersects(targetRect)) {
                    const QRect inter = avail.intersected(targetRect);
                    // Ensure at least 150px of title bar / window area is visible on an active monitor
                    if (inter.width() >= 150 && inter.height() >= 60) {
                        onValidScreen = true;
                        break;
                    }
                }
            }
        }

        if (!onValidScreen) {
            // Center on primary screen if saved position is invalid or monitor was disconnected
            QScreen* primary = QGuiApplication::primaryScreen();
            if (primary) {
                const QRect avail = primary->availableGeometry();
                winW = std::min(winW, avail.width() - 40);
                winH = std::min(winH, avail.height() - 40);
                winX = avail.x() + (avail.width() - winW) / 2;
                winY = avail.y() + (avail.height() - winH) / 2;
            } else {
                winX = 100;
                winY = 100;
            }
        }

        // Apply normal geometry
        window->setGeometry(winX, winY, winW, winH);

        auto updateWindowTheme = [window, &settingsMgr]() {
            const bool dark = (settingsMgr.themeMode() != "light");
            const QColor bgColor = dark ? QColor("#111318") : QColor("#fdf8fd");
            window->setColor(bgColor);

            QPalette pal;
            pal.setColor(QPalette::Window, bgColor);
            pal.setColor(QPalette::WindowText, dark ? QColor("#e2e2e6") : QColor("#191c20"));
            pal.setColor(QPalette::Base, bgColor);
            pal.setColor(QPalette::AlternateBase, dark ? QColor("#191c20") : QColor("#f3f3f8"));
            pal.setColor(QPalette::Text, dark ? QColor("#e2e2e6") : QColor("#191c20"));
            pal.setColor(QPalette::Button, dark ? QColor("#282a2f") : QColor("#ededf2"));
            pal.setColor(QPalette::ButtonText, dark ? QColor("#e2e2e6") : QColor("#191c20"));
            pal.setColor(QPalette::Highlight, dark ? QColor("#a8c7fa") : QColor("#0b57d0"));
            pal.setColor(QPalette::HighlightedText, dark ? QColor("#062e6f") : Qt::white);
            QGuiApplication::setPalette(pal);

#ifdef Q_OS_WIN
            HWND hwnd = reinterpret_cast<HWND>(window->winId());
            if (hwnd) {
                // 1. Windows 10 & 11 immersive dark/light mode for title bar and caption buttons
                BOOL darkMode = dark ? TRUE : FALSE;
                DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &darkMode, sizeof(darkMode));
                DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE_OLD, &darkMode, sizeof(darkMode));

                // 2. Windows 11 exact caption and text color match (Material 3 Surface Container)
                COLORREF captionColor = dark ? RGB(17, 19, 24) : RGB(253, 248, 253);
                COLORREF textColor = dark ? RGB(226, 226, 230) : RGB(25, 28, 32);
                DwmSetWindowAttribute(hwnd, DWMWA_CAPTION_COLOR, &captionColor, sizeof(captionColor));
                DwmSetWindowAttribute(hwnd, DWMWA_TEXT_COLOR, &textColor, sizeof(textColor));

                // 3. Update Win32 window background brush
                HBRUSH winBrush = CreateSolidBrush(RGB(bgColor.red(), bgColor.green(), bgColor.blue()));
                SetClassLongPtr(hwnd, GCLP_HBRBACKGROUND, reinterpret_cast<LONG_PTR>(winBrush));

                // 4. Force DWM to redraw the window frame immediately with the new theme color
                SetWindowPos(hwnd, nullptr, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
            }
#endif
        };

        auto applyDisplayMode = [window, &settingsMgr, updateWindowTheme](const QString& mode) {
            if (mode == "fullscreen") {
                window->setFlags(Qt::Window);
                window->showFullScreen();
            } else if (mode == "borderless") {
                window->setFlags(Qt::Window | Qt::FramelessWindowHint);
                QScreen* screen = window->screen();
                if (!screen) screen = QGuiApplication::primaryScreen();
                if (screen) {
                    const QRect screenRect = screen->geometry();
                    window->setGeometry(screenRect);
                }
                window->showNormal();
#ifdef Q_OS_WIN
                HWND hwnd = reinterpret_cast<HWND>(window->winId());
                if (hwnd && screen) {
                    const QRect r = screen->geometry();
                    SetWindowPos(hwnd, HWND_TOP, r.x(), r.y(), r.width(), r.height(), SWP_FRAMECHANGED | SWP_SHOWWINDOW);
                }
#endif
            } else { // "windowed"
                window->setFlags(Qt::Window);
                int winX = settingsMgr.windowX();
                int winY = settingsMgr.windowY();
                int winW = settingsMgr.windowWidth();
                int winH = settingsMgr.windowHeight();
                if (winW < 400 || winH < 300) {
                    winW = 1200;
                    winH = 800;
                }
                QScreen* screen = window->screen();
                if (!screen) screen = QGuiApplication::primaryScreen();
                if (screen) {
                    const QRect avail = screen->availableGeometry();
                    winW = std::min(winW, avail.width() - 40);
                    winH = std::min(winH, avail.height() - 40);
                    if (winX < avail.x() || winX > avail.right() - 100 || winY < avail.y() || winY > avail.bottom() - 100) {
                        winX = avail.x() + (avail.width() - winW) / 2;
                        winY = avail.y() + (avail.height() - winH) / 2;
                    }
                }
                window->setGeometry(winX, winY, winW, winH);
                window->showNormal();
#ifdef Q_OS_WIN
                HWND hwnd = reinterpret_cast<HWND>(window->winId());
                if (hwnd) {
                    SetWindowPos(hwnd, HWND_TOP, winX, winY, winW, winH, SWP_FRAMECHANGED | SWP_SHOWWINDOW);
                }
#endif
            }

            updateWindowTheme();
        };

        // Debounce window geometry persistence to prevent flooding registry/disk I/O during drag
        auto* geomSaveTimer = new QTimer(window);
        geomSaveTimer->setSingleShot(true);
        geomSaveTimer->setInterval(500);

        QObject::connect(geomSaveTimer, &QTimer::timeout, window, [window, &settingsMgr]() {
            if (settingsMgr.windowDisplayMode() == "windowed" &&
                window->visibility() == QWindow::Windowed &&
                window->windowState() == Qt::WindowNoState) {
                settingsMgr.saveWindowGeometry(window->x(), window->y(), window->width(), window->height(), "normal");
            }
        });

        auto queueGeometrySave = [geomSaveTimer, &settingsMgr]() {
            if (settingsMgr.windowDisplayMode() == "windowed") {
                geomSaveTimer->start();
            }
        };

        QObject::connect(window, &QWindow::xChanged, window, queueGeometrySave);
        QObject::connect(window, &QWindow::yChanged, window, queueGeometrySave);
        QObject::connect(window, &QWindow::widthChanged, window, queueGeometrySave);
        QObject::connect(window, &QWindow::heightChanged, window, queueGeometrySave);

        QObject::connect(window, &QWindow::windowStateChanged, window, [window, &settingsMgr, geomSaveTimer](Qt::WindowState state) {
            geomSaveTimer->stop();
            if (settingsMgr.windowDisplayMode() == "windowed") {
                if (state == Qt::WindowMaximized) {
                    settingsMgr.saveWindowGeometry(window->x(), window->y(), window->width(), window->height(), "maximized");
                } else if (state == Qt::WindowFullScreen) {
                    settingsMgr.saveWindowGeometry(window->x(), window->y(), window->width(), window->height(), "fullscreen");
                } else if (state == Qt::WindowNoState) {
                    settingsMgr.saveWindowGeometry(window->x(), window->y(), window->width(), window->height(), "normal");
                }
            }
        });

        // Save state on window close
        QObject::connect(window, &QQuickWindow::closing, window, [window, &settingsMgr, geomSaveTimer](QQuickCloseEvent*) {
            geomSaveTimer->stop();
            if (settingsMgr.windowDisplayMode() == "windowed") {
                QString stateStr = "normal";
                if (window->visibility() == QWindow::Maximized || window->windowState() == Qt::WindowMaximized) {
                    stateStr = "maximized";
                } else if (window->visibility() == QWindow::FullScreen || window->windowState() == Qt::WindowFullScreen) {
                    stateStr = "fullscreen";
                }
                settingsMgr.saveWindowGeometry(window->x(), window->y(), window->width(), window->height(), stateStr);
            }
            settingsMgr.sync();
        });

#ifdef Q_OS_WIN
        HWND hwnd = reinterpret_cast<HWND>(window->winId());
        if (hwnd) {
            // 1. Cloak the window from DWM desktop composition before showing so Windows never composites unrendered white frames
            BOOL cloak = TRUE;
            DwmSetWindowAttribute(hwnd, DWMWA_CLOAK, &cloak, sizeof(cloak));
        }
#endif

        // Apply initial theme to window and native title bar
        updateWindowTheme();

        // Dynamic Theme changes at runtime (matches title bar to white/dark mode immediately)
        QObject::connect(&settingsMgr, &SettingsManager::themeModeChanged, window, [updateWindowTheme](const QString&) {
            updateWindowTheme();
        });

        // Dynamic Display Mode changes at runtime
        QObject::connect(&settingsMgr, &SettingsManager::windowDisplayModeChanged, window, [applyDisplayMode](const QString& mode) {
            applyDisplayMode(mode);
        });

        // Show window with its initial state according to display mode
        if (displayMode == "borderless") {
            applyDisplayMode("borderless");
        } else if (displayMode == "fullscreen" || winState == "fullscreen") {
            applyDisplayMode("fullscreen");
        } else {
            window->setFlags(Qt::Window);
            window->setGeometry(winX, winY, winW, winH);
            if (winState == "maximized") {
                window->showMaximized();
            } else {
                window->showNormal();
            }
            updateWindowTheme();
        }

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
