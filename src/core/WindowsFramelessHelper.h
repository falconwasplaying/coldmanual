#pragma once

#include <QObject>
#include <QPointer>
#include <QQuickWindow>
#include <QPointF>
#include <QCursor>

#ifdef Q_OS_WIN
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

class WindowsFramelessHelper : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isMaximized READ isMaximized NOTIFY isMaximizedChanged)
    Q_PROPERTY(qreal titleBarHeight READ titleBarHeight WRITE setTitleBarHeight NOTIFY titleBarHeightChanged)
    Q_PROPERTY(qreal tabsStartX READ tabsStartX WRITE setTabsStartX NOTIFY tabsStartXChanged)
    Q_PROPERTY(qreal tabsEndX READ tabsEndX WRITE setTabsEndX NOTIFY tabsEndXChanged)

public:
    explicit WindowsFramelessHelper(QObject* parent = nullptr);
    ~WindowsFramelessHelper() override;

    Q_INVOKABLE void init(QQuickWindow* window);
    Q_INVOKABLE void toggleMaximize();
    Q_INVOKABLE void showMinimized();
    Q_INVOKABLE void close();
    Q_INVOKABLE void updateTabsWidth(qreal startX, qreal endX);
    Q_INVOKABLE QPointF cursorPosition() const;
    Q_INVOKABLE bool isCursorInHoverZone(qreal tabX1, qreal tabY1, qreal tabX2, qreal tabY2,
                                         qreal cardX1, qreal cardY1, qreal cardX2, qreal cardY2) const;

    bool isMaximized() const;
    void setIsMaximized(bool max);

    qreal titleBarHeight() const;
    void setTitleBarHeight(qreal h);

    qreal tabsStartX() const;
    void setTabsStartX(qreal x);

    qreal tabsEndX() const;
    void setTabsEndX(qreal x);

signals:
    void isMaximizedChanged(bool max);
    void titleBarHeightChanged(qreal h);
    void tabsStartXChanged(qreal x);
    void tabsEndXChanged(qreal x);

private:
    QPointer<QQuickWindow> m_window;
    bool m_isMaximized{false};
    qreal m_titleBarHeight{40.0};
    qreal m_tabsStartX{44.0};
    qreal m_tabsEndX{200.0};

#ifdef Q_OS_WIN
    static LRESULT CALLBACK SubclassProc(
        HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam,
        UINT_PTR uIdSubclass, DWORD_PTR dwRefData);
#endif
};
