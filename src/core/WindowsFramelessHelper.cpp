#include "WindowsFramelessHelper.h"

#ifdef Q_OS_WIN
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <windowsx.h>
#include <dwmapi.h>
#include <commctrl.h>
#endif

WindowsFramelessHelper::WindowsFramelessHelper(QObject* parent)
    : QObject(parent)
{
}

WindowsFramelessHelper::~WindowsFramelessHelper() {
#ifdef Q_OS_WIN
    if (m_window) {
        HWND hwnd = reinterpret_cast<HWND>(m_window->winId());
        if (hwnd) {
            RemoveWindowSubclass(hwnd, SubclassProc, 1);
        }
    }
#endif
}

void WindowsFramelessHelper::init(QQuickWindow* window) {
    m_window = window;
    if (!m_window) return;

#ifdef Q_OS_WIN
    HWND hwnd = reinterpret_cast<HWND>(m_window->winId());
    if (hwnd) {
        // Ensure standard window flags that Windows needs for Aero Snap, Snap Assist, Min/Max/Restore
        LONG_PTR style = GetWindowLongPtr(hwnd, GWL_STYLE);
        style |= WS_THICKFRAME | WS_CAPTION | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU;
        SetWindowLongPtr(hwnd, GWL_STYLE, style);

        // Extend frame into client area for native DWM drop shadow
        MARGINS margins = { 0, 0, 1, 0 };
        DwmExtendFrameIntoClientArea(hwnd, &margins);

        // Subclass window to intercept WM_NCCALCSIZE and WM_NCHITTEST
        SetWindowSubclass(hwnd, SubclassProc, 1, reinterpret_cast<DWORD_PTR>(this));

        // Update frame immediately
        SetWindowPos(hwnd, nullptr, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);

        setIsMaximized(IsZoomed(hwnd));
    }
#endif
}

void WindowsFramelessHelper::toggleMaximize() {
    if (!m_window) return;
    if (isMaximized()) {
        m_window->showNormal();
    } else {
        m_window->showMaximized();
    }
}

void WindowsFramelessHelper::showMinimized() {
    if (!m_window) return;
    m_window->showMinimized();
}

void WindowsFramelessHelper::close() {
    if (!m_window) return;
    m_window->close();
}

void WindowsFramelessHelper::updateTabsWidth(qreal startX, qreal endX) {
    setTabsStartX(startX);
    setTabsEndX(endX);
}

bool WindowsFramelessHelper::isMaximized() const {
    return m_isMaximized;
}

void WindowsFramelessHelper::setIsMaximized(bool max) {
    if (m_isMaximized != max) {
        m_isMaximized = max;
        emit isMaximizedChanged(m_isMaximized);
    }
}

qreal WindowsFramelessHelper::titleBarHeight() const {
    return m_titleBarHeight;
}

void WindowsFramelessHelper::setTitleBarHeight(qreal h) {
    if (m_titleBarHeight != h) {
        m_titleBarHeight = h;
        emit titleBarHeightChanged(m_titleBarHeight);
    }
}

qreal WindowsFramelessHelper::tabsStartX() const {
    return m_tabsStartX;
}

void WindowsFramelessHelper::setTabsStartX(qreal x) {
    if (m_tabsStartX != x) {
        m_tabsStartX = x;
        emit tabsStartXChanged(m_tabsStartX);
    }
}

qreal WindowsFramelessHelper::tabsEndX() const {
    return m_tabsEndX;
}

void WindowsFramelessHelper::setTabsEndX(qreal x) {
    if (m_tabsEndX != x) {
        m_tabsEndX = x;
        emit tabsEndXChanged(m_tabsEndX);
    }
}

#ifdef Q_OS_WIN
LRESULT CALLBACK WindowsFramelessHelper::SubclassProc(
    HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam,
    UINT_PTR uIdSubclass, DWORD_PTR dwRefData)
{
    auto* self = reinterpret_cast<WindowsFramelessHelper*>(dwRefData);
    if (!self) {
        return DefSubclassProc(hwnd, uMsg, wParam, lParam);
    }

    switch (uMsg) {
    case WM_NCCALCSIZE: {
        if (wParam == TRUE) {
            NCCALCSIZE_PARAMS* params = reinterpret_cast<NCCALCSIZE_PARAMS*>(lParam);
            if (IsZoomed(hwnd)) {
                // When maximized, match the monitor workarea so resize margins don't spill offscreen
                HMONITOR hMon = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
                MONITORINFO mi;
                mi.cbSize = sizeof(mi);
                if (GetMonitorInfo(hMon, &mi)) {
                    params->rgrc[0] = mi.rcWork;
                }
            }
            return 0; // Removes default Windows titlebar and borders completely!
        }
        return 0;
    }

    case WM_NCHITTEST: {
        POINT pt = { GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam) };
        RECT rc;
        GetWindowRect(hwnd, &rc);

        const bool maximized = IsZoomed(hwnd);
        self->setIsMaximized(maximized);

        // 1. Resize borders (only active when not maximized)
        if (!maximized) {
            const int border = 8;
            bool left = (pt.x < rc.left + border);
            bool right = (pt.x >= rc.right - border);
            bool top = (pt.y < rc.top + border);
            bool bottom = (pt.y >= rc.bottom - border);

            if (top && left) return HTTOPLEFT;
            if (top && right) return HTTOPRIGHT;
            if (bottom && left) return HTBOTTOMLEFT;
            if (bottom && right) return HTBOTTOMRIGHT;
            if (left) return HTLEFT;
            if (right) return HTRIGHT;
            if (top) return HTTOP;
            if (bottom) return HTBOTTOM;
        }

        // 2. Title bar hit testing
        qreal dpr = self->m_window ? self->m_window->devicePixelRatio() : 1.0;
        int titleBarPhysicalH = static_cast<int>(self->m_titleBarHeight * dpr);

        if (pt.y >= rc.top && pt.y < rc.top + titleBarPhysicalH) {
            int clientPhysicalX = pt.x - rc.left;
            qreal clientLogicalX = clientPhysicalX / dpr;
            qreal windowLogicalW = (rc.right - rc.left) / dpr;

            // Window controls on the right (Minimize, Maximize, Close): width ~140px
            const qreal controlsWidth = 140.0;
            if (clientLogicalX >= windowLogicalW - controlsWidth) {
                return HTCLIENT; // QML handles clicks & hover on controls
            }

            // Tabs strip & + button: from tabsStartX to tabsEndX
            if (clientLogicalX >= self->m_tabsStartX && clientLogicalX < self->m_tabsEndX) {
                return HTCLIENT; // QML handles tabs, close button, hover cards, and + button
            }

            // Draggable titlebar area: Aero Snap, Snap Assist, double-click to maximize/restore!
            return HTCAPTION;
        }

        return HTCLIENT;
    }

    case WM_SIZE: {
        self->setIsMaximized(IsZoomed(hwnd));
        break;
    }

    case WM_DESTROY: {
        RemoveWindowSubclass(hwnd, SubclassProc, uIdSubclass);
        break;
    }
    }

    return DefSubclassProc(hwnd, uMsg, wParam, lParam);
}
#endif
