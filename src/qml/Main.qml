import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import "views"
import "components"

ApplicationWindow {
    id: window
    visible: false
    width: 1200
    height: 800
    minimumWidth: 960
    minimumHeight: 640
    title: ""
    color: Theme.background
    Material.theme: Theme.isDark ? Material.Dark : Material.Light
    Material.accent: Theme.primary
    Material.primary: Theme.primary
    Material.background: Theme.surface
    Material.foreground: Theme.onSurface

    onVisibleChanged: {
        if (visible) {
            splashDismissTimer.restart()
        }
    }

    property int currentTab: 1 // Default to Browse Catalog on first run if no docs, or Reader
    property bool sidebarMinimized: false

    function showToast(title, message, iconName, duration) {
        toastNotification.show(title, message, iconName || "wifi-off", duration || 4000)
    }

    onCurrentTabChanged: {
        if (currentTab === 1 && !networkMgr.isOnline) {
            currentTab = (docsetMgr.installedCount > 0) ? 0 : 2
            showToast("Offline Mode", "Cannot open catalog while offline. Please connect to the internet.", "wifi-off")
        }
    }

    Connections {
        target: networkMgr
        function onIsOnlineChanged() {
            if (!networkMgr.isOnline && currentTab === 1) {
                currentTab = (docsetMgr.installedCount > 0) ? 0 : 2
                showToast("Connection Lost", "Catalog was closed because you went offline.", "wifi-off")
            }
        }
    }

    Connections {
        target: docsetMgr
        function onDocsetInstalled(id, name) {
            showToast("Installation Complete", name + " documentation is ready for offline reading.", "check-circle", 5000)
        }
        function onDocsetInstallationFailed(id, errorMessage) {
            showToast("Installation Failed", errorMessage, "alert-circle", 6000)
        }
    }

    Component.onCompleted: {
        if (docsetMgr.installedCount > 0) {
            currentTab = 0
            var firstDoc = docsetMgr.getInstalledDocset(docsetMgr.data(docsetMgr.index(0), 1).toString())
            if (firstDoc.indexPath) {
                readerView.openDocument(firstDoc.id, firstDoc.name, firstDoc.indexPath, firstDoc.name)
            }
        } else {
            if (networkMgr.isOnline) {
                currentTab = 1
            } else {
                currentTab = 2
                showToast("Offline Mode", "You are currently offline. Connect to the internet to browse the catalog.", "wifi-off")
            }
        }
    }

    // Keyboard Shortcuts
    Shortcut {
        sequences: ["Ctrl+K", "Ctrl+P"]
        onActivated: omniSearch.open()
    }
    Shortcut {
        sequence: "Ctrl+1"
        onActivated: currentTab = 0
    }
    Shortcut {
        sequence: "Ctrl+2"
        onActivated: {
            if (networkMgr.isOnline) {
                currentTab = 1
            } else {
                showToast("Offline Mode", "Cannot open catalog while offline. Please connect to the internet.", "wifi-off")
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+3"
        onActivated: currentTab = 2
    }
    property string previousNonFullscreenMode: (settingsMgr.windowDisplayMode === "borderless") ? "borderless" : "windowed"

    Shortcut {
        sequence: "Ctrl+,"
        onActivated: currentTab = 3
    }
    Shortcut {
        sequence: "Ctrl+B"
        onActivated: sidebarMinimized = !sidebarMinimized
    }
    Shortcut {
        sequence: "F11"
        onActivated: {
            if (settingsMgr.windowDisplayMode === "fullscreen" || settingsMgr.windowDisplayMode === "borderless") {
                settingsMgr.windowDisplayMode = "windowed"
            } else {
                settingsMgr.windowDisplayMode = "borderless"
            }
        }
    }
    Shortcut {
        sequence: "Esc"
        enabled: settingsMgr.windowDisplayMode !== "windowed"
        onActivated: {
            settingsMgr.windowDisplayMode = "windowed"
        }
    }

    onClosing: function(close) {
        if (settingsMgr.windowDisplayMode === "windowed") {
            var stateStr = "normal"
            if (window.visibility === Window.Maximized) {
                stateStr = "maximized"
            } else if (window.visibility === Window.FullScreen) {
                stateStr = "fullscreen"
            }
            settingsMgr.saveWindowGeometry(window.x, window.y, window.width, window.height, stateStr)
            settingsMgr.sync()
        }
    }

    // Floating Quick Controls in Borderless & Fullscreen modes
    Rectangle {
        id: floatingControls
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.rightMargin: 16
        z: 99999
        width: 108
        height: 32
        radius: Theme.shapeFull
        color: Theme.surfaceContainerHigh
        border.color: Theme.outlineVariant
        border.width: 1
        visible: settingsMgr.windowDisplayMode !== "windowed"

        opacity: floatHover.hovered ? 1.0 : 0.4
        Behavior on opacity { NumberAnimation { duration: Theme.animDurationNormal } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 2

            // Minimize
            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 24
                radius: Theme.shapeFull
                color: minArea.containsMouse ? Theme.surfaceContainerHighest : "transparent"
                LucideIcon {
                    anchors.centerIn: parent
                    name: "minimize"
                    size: 11
                    color: Theme.textPrimary
                }
                MouseArea {
                    id: minArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: window.showMinimized()
                }
            }

            // Restore to Windowed
            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 24
                radius: Theme.shapeFull
                color: restoreArea.containsMouse ? Theme.surfaceContainerHighest : "transparent"
                LucideIcon {
                    anchors.centerIn: parent
                    name: "app-window"
                    size: 11
                    color: Theme.textPrimary
                }
                MouseArea {
                    id: restoreArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settingsMgr.windowDisplayMode = "windowed"
                }
            }

            // Close
            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 24
                radius: Theme.shapeFull
                color: closeArea.containsMouse ? Theme.danger : "transparent"
                LucideIcon {
                    anchors.centerIn: parent
                    name: "x"
                    size: 11
                    color: closeArea.containsMouse ? Theme.onError : Theme.textPrimary
                }
                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: window.close()
                }
            }
        }

        HoverHandler {
            id: floatHover
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Material 3 Navigation Rail & Navigation Drawer
        Rectangle {
            id: sidebarRect
            property real expandProgress: window.sidebarMinimized ? 0.0 : 1.0
            Behavior on expandProgress {
                NumberAnimation {
                    duration: Theme.animDurationNormal
                    easing.type: Easing.OutCubic
                }
            }
            Layout.preferredWidth: Math.round(72 + (250 - 72) * expandProgress)
            Layout.fillHeight: true
            color: Theme.sidebarBg
            border.color: Theme.outlineVariant
            border.width: 1
            clip: true

            Item {
                anchors.fill: parent

                // Top section (Logo, Search, Divider, Nav items)
                Column {
                    anchors.top: parent.top
                    anchors.topMargin: 16
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 12

                    // 1. Logo & App Title (Anchored icon, smooth left-to-right fade)
                    Item {
                        width: parent.width
                        height: 36

                        Image {
                            id: logoImg
                            width: 30
                            height: 30
                            source: Theme.logoUrl
                            sourceSize.width: 60
                            sourceSize.height: 60
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            anchors.left: parent.left
                            anchors.leftMargin: 21
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.left: logoImg.right
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            transform: Translate { x: Math.round(-18 * (1.0 - sidebarRect.expandProgress)) }
                            opacity: Math.min(1.0, sidebarRect.expandProgress * 1.5)
                            visible: opacity > 0

                            Text {
                                text: "ColdManual"
                                font.family: Theme.fontSans
                                font.pixelSize: 16
                                font.bold: true
                                color: Theme.onSurface
                            }
                            Text {
                                text: "Offline Documentation"
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                                color: Theme.onSurfaceVariant
                            }
                        }
                    }

                    // 2. Material 3 Search Bar (Anchored icon, left-to-right text slide & fade)
                    Rectangle {
                        id: omniBtn
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        height: 40
                        radius: Theme.shapeFull
                        clip: true
                        color: omniArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                        border.color: omniArea.containsMouse ? Theme.outline : Theme.surfaceContainerHigh
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

                        LucideIcon {
                            id: searchIcon
                            name: "search"
                            size: 16
                            color: omniArea.containsMouse ? Theme.primary : Theme.onSurfaceVariant
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        }

                        Text {
                            anchors.left: searchIcon.right
                            anchors.leftMargin: 12
                            anchors.right: ctrlKBadge.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search symbols..."
                            font.family: Theme.fontSans
                            font.pixelSize: 13
                            color: Theme.onSurfaceVariant
                            elide: Text.ElideRight
                            transform: Translate { x: Math.round(-16 * (1.0 - sidebarRect.expandProgress)) }
                            opacity: Math.min(1.0, sidebarRect.expandProgress * 1.5)
                            visible: opacity > 0
                        }

                        Rectangle {
                            id: ctrlKBadge
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 44
                            height: 20
                            radius: Theme.shapeSmall
                            color: Theme.surfaceContainerHighest
                            opacity: Math.max(0.0, Math.min(1.0, (sidebarRect.expandProgress - 0.25) * 1.33))
                            visible: opacity > 0

                            Text {
                                anchors.centerIn: parent
                                text: "Ctrl+K"
                                font.family: Theme.fontSans
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.onSurfaceVariant
                            }
                        }

                        MouseArea {
                            id: omniArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: omniSearch.open()
                        }
                    }

                    // Tonal Divider
                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        height: 1
                        color: Theme.outlineVariant
                    }

                    // Nav Items (Material 3 Navigation Drawer & Rail)
                    Column {
                        width: parent.width
                        spacing: 4

                        // Tab 0: Reader
                        Item {
                            width: parent.width
                            height: 44

                            Rectangle {
                                id: tab0Pill
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                height: 40
                                radius: Theme.shapeFull
                                clip: true
                                color: (currentTab === 0) ? Theme.secondaryContainer :
                                       (navReaderArea.containsMouse ? Theme.surfaceContainerHighest : Theme.sidebarBg)

                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                                LucideIcon {
                                    id: tab0Icon
                                    name: "book-open"
                                    size: 18
                                    color: (currentTab === 0) ? Theme.onSecondaryContainer : Theme.onSurfaceVariant
                                    anchors.left: parent.left
                                    anchors.leftMargin: 15
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                }

                                Text {
                                    anchors.left: tab0Icon.right
                                    anchors.leftMargin: 14
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Reader"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 13
                                    font.bold: currentTab === 0
                                    color: (currentTab === 0) ? Theme.onSecondaryContainer : Theme.onSurface
                                    elide: Text.ElideRight
                                    transform: Translate { x: Math.round(-16 * (1.0 - sidebarRect.expandProgress)) }
                                    opacity: Math.min(1.0, sidebarRect.expandProgress * 1.5)
                                    visible: opacity > 0
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                }
                            }

                            MouseArea {
                                id: navReaderArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: currentTab = 0
                            }
                        }

                        // Tab 1: Browse Catalog
                        Item {
                            width: parent.width
                            height: 44
                            opacity: networkMgr.isOnline ? 1.0 : 0.5
                            Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }

                            Rectangle {
                                id: tab1Pill
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                height: 40
                                radius: Theme.shapeFull
                                clip: true
                                color: (currentTab === 1) ? Theme.secondaryContainer :
                                       (navCatalogArea.containsMouse ? Theme.surfaceContainerHighest : Theme.sidebarBg)

                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                                LucideIcon {
                                    id: tab1Icon
                                    name: "compass"
                                    size: 18
                                    color: (currentTab === 1) ? Theme.onSecondaryContainer : Theme.onSurfaceVariant
                                    anchors.left: parent.left
                                    anchors.leftMargin: 15
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                }

                                // Minimized offline dot
                                Rectangle {
                                    visible: !networkMgr.isOnline && sidebarRect.expandProgress < 0.3
                                    width: 7
                                    height: 7
                                    radius: 3.5
                                    color: Theme.warning
                                    anchors.top: tab1Icon.top
                                    anchors.right: tab1Icon.right
                                    anchors.topMargin: -3
                                    anchors.rightMargin: -3
                                }

                                Text {
                                    anchors.left: tab1Icon.right
                                    anchors.leftMargin: 14
                                    anchors.right: offlineBadge.left
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Browse Catalog"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 13
                                    font.bold: currentTab === 1
                                    color: (currentTab === 1) ? Theme.onSecondaryContainer : Theme.onSurface
                                    elide: Text.ElideRight
                                    transform: Translate { x: Math.round(-16 * (1.0 - sidebarRect.expandProgress)) }
                                    opacity: Math.min(1.0, sidebarRect.expandProgress * 1.5)
                                    visible: opacity > 0
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                }

                                Rectangle {
                                    id: offlineBadge
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 20
                                    radius: Theme.shapeFull
                                    width: offlineBadgeRow.implicitWidth + 12
                                    color: Theme.surfaceContainerHighest
                                    opacity: !networkMgr.isOnline ? Math.max(0.0, Math.min(1.0, (sidebarRect.expandProgress - 0.3) * 1.43)) : 0.0
                                    visible: opacity > 0

                                    RowLayout {
                                        id: offlineBadgeRow
                                        anchors.centerIn: parent
                                        spacing: 4
                                        LucideIcon {
                                            name: "wifi-off"
                                            size: 10
                                            color: Theme.onSurfaceVariant
                                        }
                                        Text {
                                            text: "Offline"
                                            font.family: Theme.fontSans
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: Theme.onSurfaceVariant
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: navCatalogArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: networkMgr.isOnline ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                                onClicked: {
                                    if (!networkMgr.isOnline) {
                                        showToast("Offline Mode", "Cannot open catalog while offline. Please connect to the internet.", "wifi-off")
                                        return
                                    }
                                    currentTab = 1
                                }
                            }
                        }

                        // Tab 2: Installed & Updates
                        Item {
                            width: parent.width
                            height: 44

                            Rectangle {
                                id: tab2Pill
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                height: 40
                                radius: Theme.shapeFull
                                clip: true
                                color: (currentTab === 2) ? Theme.secondaryContainer :
                                       (navInstArea.containsMouse ? Theme.surfaceContainerHighest : Theme.sidebarBg)

                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                                LucideIcon {
                                    id: tab2Icon
                                    name: "download"
                                    size: 18
                                    color: (currentTab === 2) ? Theme.onSecondaryContainer : Theme.onSurfaceVariant
                                    anchors.left: parent.left
                                    anchors.leftMargin: 15
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                }

                                // Minimized installed badge dot
                                Rectangle {
                                    visible: docsetMgr.installedCount > 0 && sidebarRect.expandProgress < 0.3
                                    width: 7
                                    height: 7
                                    radius: 3.5
                                    color: Theme.primary
                                    anchors.top: tab2Icon.top
                                    anchors.right: tab2Icon.right
                                    anchors.topMargin: -3
                                    anchors.rightMargin: -3
                                }

                                Text {
                                    anchors.left: tab2Icon.right
                                    anchors.leftMargin: 14
                                    anchors.right: instBadge.left
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Installed"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 13
                                    font.bold: currentTab === 2
                                    color: (currentTab === 2) ? Theme.onSecondaryContainer : Theme.onSurface
                                    elide: Text.ElideRight
                                    transform: Translate { x: Math.round(-16 * (1.0 - sidebarRect.expandProgress)) }
                                    opacity: Math.min(1.0, sidebarRect.expandProgress * 1.5)
                                    visible: opacity > 0
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                }

                                // Count badge (expanded)
                                Rectangle {
                                    id: instBadge
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.max(22, instBadgeText.implicitWidth + 10)
                                    height: 20
                                    radius: Theme.shapeFull
                                    color: (currentTab === 2) ? Theme.primary : Theme.surfaceContainerHighest
                                    opacity: Math.max(0.0, Math.min(1.0, (sidebarRect.expandProgress - 0.3) * 1.43))
                                    visible: opacity > 0

                                    Text {
                                        id: instBadgeText
                                        anchors.centerIn: parent
                                        text: docsetMgr.installedCount
                                        font.family: Theme.fontSans
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: (currentTab === 2) ? Theme.onPrimary : Theme.onSurfaceVariant
                                    }
                                }
                            }

                            MouseArea {
                                id: navInstArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: currentTab = 2
                            }
                        }

                        // Tab 3: Settings
                        Item {
                            width: parent.width
                            height: 44

                            Rectangle {
                                id: tab3Pill
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                height: 40
                                radius: Theme.shapeFull
                                clip: true
                                color: (currentTab === 3) ? Theme.secondaryContainer :
                                       (navSettingsArea.containsMouse ? Theme.surfaceContainerHighest : Theme.sidebarBg)

                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                                LucideIcon {
                                    id: tab3Icon
                                    name: "settings"
                                    size: 18
                                    color: (currentTab === 3) ? Theme.onSecondaryContainer : Theme.onSurfaceVariant
                                    anchors.left: parent.left
                                    anchors.leftMargin: 15
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                }

                                Text {
                                    anchors.left: tab3Icon.right
                                    anchors.leftMargin: 14
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Settings"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 13
                                    font.bold: currentTab === 3
                                    color: (currentTab === 3) ? Theme.onSecondaryContainer : Theme.onSurface
                                    elide: Text.ElideRight
                                    transform: Translate { x: Math.round(-16 * (1.0 - sidebarRect.expandProgress)) }
                                    opacity: Math.min(1.0, sidebarRect.expandProgress * 1.5)
                                    visible: opacity > 0
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                }
                            }

                            MouseArea {
                                id: navSettingsArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: currentTab = 3
                            }
                        }
                    }
                }

                // Bottom section (Arrow + Storage & Version)
                Column {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 14
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 10

                    // Arrow with Long Tail (toggles collapse/expand)
                    Item {
                        id: collapseArrowItem
                        width: parent.width
                        height: 26

                        // Dynamic SVG Arrow with adjustable line length + Lucide chevron
                        Image {
                            id: arrowSvgImg
                            anchors.fill: parent
                            visible: opacity > 0
                            opacity: Math.max(0.0, Math.min(1.0, (sidebarRect.expandProgress - 0.2) * 1.25))
                            smooth: true
                            mipmap: true
                            source: {
                                var w = Math.max(40, collapseArrowItem.width)
                                var h = collapseArrowItem.height
                                var colorHex = arrowMouseArea.containsMouse ? Theme.primary : Theme.onSurfaceVariant
                                var lineStart = 16
                                var arrowTipX = w - 16
                                var wingX = arrowTipX - 6
                                var midY = h / 2
                                var wingTopY = midY - 5
                                var wingBottomY = midY + 5
                                
                                var svg = "<svg xmlns='http://www.w3.org/2000/svg' width='" + w + "' height='" + h + "' viewBox='0 0 " + w + " " + h + "' fill='none'>" +
                                          "<path d='M" + lineStart + " " + midY + " H" + arrowTipX + "' stroke='" + colorHex + "' stroke-width='2.2' stroke-linecap='round' stroke-linejoin='round'/>" +
                                          "<path d='M" + wingX + " " + wingTopY + " L" + arrowTipX + " " + midY + " L" + wingX + " " + wingBottomY + "' stroke='" + colorHex + "' stroke-width='2.2' stroke-linecap='round' stroke-linejoin='round'/>" +
                                          "</svg>"
                                return "data:image/svg+xml;utf8," + encodeURIComponent(svg)
                            }
                        }

                        // Arrow Tip in minimized rail (centered Lucide chevron)
                        Image {
                            id: minArrowSvgImg
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            visible: opacity > 0
                            opacity: Math.max(0.0, Math.min(1.0, (0.5 - sidebarRect.expandProgress) * 2.0))
                            smooth: true
                            mipmap: true
                            source: {
                                var colorHex = arrowMouseArea.containsMouse ? Theme.primary : Theme.onSurfaceVariant
                                var svg = "<svg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='" + colorHex + "' stroke-width='2.2' stroke-linecap='round' stroke-linejoin='round'>" +
                                          "<path d='M9 18 L15 12 L9 6'/>" +
                                          "</svg>"
                                return "data:image/svg+xml;utf8," + encodeURIComponent(svg)
                            }
                        }

                        MouseArea {
                            id: arrowMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                window.sidebarMinimized = !window.sidebarMinimized
                            }
                        }
                    }

                    // Footer info (Storage & Version)
                    Item {
                        width: parent.width
                        height: 16

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Storage: " + docsetMgr.totalStorageUsage
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            color: Theme.onSurfaceVariant
                            transform: Translate { x: Math.round(-16 * (1.0 - sidebarRect.expandProgress)) }
                            opacity: Math.min(1.0, sidebarRect.expandProgress * 1.5)
                            visible: opacity > 0
                        }

                        Text {
                            text: "v1.0"
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            color: Theme.onSurfaceVariant
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: sidebarRect.expandProgress < 0.5 ? Math.round((sidebarRect.width - implicitWidth) / 2) : 16
                        }
                    }
                }
            }
        }


        // Main Content Views with Smooth Crossfade & Micro-Slide
        Item {
            id: mainContentContainer
            Layout.fillWidth: true
            Layout.fillHeight: true

            ReaderView {
                id: readerView
                anchors.fill: parent
                visible: opacity > 0.001
                opacity: (window.currentTab === 0) ? 1.0 : 0.0
                y: (window.currentTab === 0) ? 0 : 6
                Behavior on opacity { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Easing.OutQuad } }
                Behavior on y { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Theme.animEasingDecel } }
                onNavigateToCatalog: {
                    if (networkMgr.isOnline) {
                        window.currentTab = 1
                    } else {
                        showToast("Offline Mode", "Cannot open catalog while offline. Please connect to the internet.", "wifi-off")
                    }
                }
            }

            CatalogView {
                id: catalogView
                anchors.fill: parent
                visible: opacity > 0.001
                opacity: (window.currentTab === 1) ? 1.0 : 0.0
                y: (window.currentTab === 1) ? 0 : 6
                Behavior on opacity { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Easing.OutQuad } }
                Behavior on y { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Theme.animEasingDecel } }
                onOpenDocsetInReader: function(docsetId, docsetName) {
                    var info = docsetMgr.getInstalledDocset(docsetId)
                    if (info.indexPath) {
                        readerView.openDocument(docsetId, docsetName, info.indexPath, docsetName)
                    }
                    window.currentTab = 0
                }
            }

            InstalledView {
                id: installedView
                anchors.fill: parent
                visible: opacity > 0.001
                opacity: (window.currentTab === 2) ? 1.0 : 0.0
                y: (window.currentTab === 2) ? 0 : 6
                Behavior on opacity { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Easing.OutQuad } }
                Behavior on y { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Theme.animEasingDecel } }
                onOpenDocsetInReader: function(docsetId, docsetName) {
                    var info = docsetMgr.getInstalledDocset(docsetId)
                    if (info.indexPath) {
                        readerView.openDocument(docsetId, docsetName, info.indexPath, docsetName)
                    }
                    window.currentTab = 0
                }
                onNavigateToCatalog: {
                    if (networkMgr.isOnline) {
                        window.currentTab = 1
                    } else {
                        showToast("Offline Mode", "Cannot open catalog while offline. Please connect to the internet.", "wifi-off")
                    }
                }
            }

            SettingsView {
                id: settingsView
                anchors.fill: parent
                visible: opacity > 0.001
                opacity: (window.currentTab === 3) ? 1.0 : 0.0
                y: (window.currentTab === 3) ? 0 : 6
                Behavior on opacity { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Easing.OutQuad } }
                Behavior on y { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Theme.animEasingDecel } }
            }
        }
    }

    // Global Floating Omni-Search Modal
    OmniSearchModal {
        id: omniSearch
        anchors.fill: parent
        z: 9999
        onNavigateToItem: function(docsetId, docsetName, fullFilePath, title) {
            readerView.openDocument(docsetId, docsetName, fullFilePath, title)
            window.currentTab = 0
        }
    }

    // Global Floating Toast Notification
    Toast {
        id: toastNotification
    }

    // Minimalist App Loading Splash Screen
    Rectangle {
        id: startupSplash
        anchors.fill: parent
        z: 99998
        color: Theme.background
        visible: opacity > 0.001
        opacity: 1.0

        Behavior on opacity {
            NumberAnimation { duration: 280; easing.type: Easing.OutQuad }
        }

        Component.onCompleted: {
            if (window.visible) {
                splashDismissTimer.restart()
            }
        }

        // Prevent click-through while splash is active
        MouseArea {
            anchors.fill: parent
            enabled: startupSplash.visible
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 14

            Image {
                Layout.alignment: Qt.AlignHCenter
                width: 54
                height: 54
                source: Theme.logoUrl
                sourceSize.width: 108
                sourceSize.height: 108
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true

                // Breathing pulse on the emblem
                SequentialAnimation on scale {
                    running: startupSplash.visible
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.07; duration: 800; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 1.07; to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 2

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "ColdManual"
                    font.family: Theme.fontSans
                    font.pixelSize: 18
                    font.bold: true
                    color: Theme.onSurface
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Offline Documentation Browser"
                    font.family: Theme.fontSans
                    font.pixelSize: 11
                    color: Theme.onSurfaceVariant
                }
            }

            // Material 3 Indeterminate Linear Progress Indicator
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                width: 140
                height: 4
                radius: Theme.shapeFull
                color: Theme.surfaceContainerHighest
                clip: true

                Rectangle {
                    id: splashBar
                    width: 48
                    height: 4
                    radius: Theme.shapeFull
                    color: Theme.primary

                    SequentialAnimation on x {
                        running: startupSplash.visible
                        loops: Animation.Infinite
                        NumberAnimation { from: -48; to: 140; duration: 950; easing.type: Easing.InOutQuad }
                    }
                }
            }
        }

        Timer {
            id: splashDismissTimer
            interval: 420
            running: false
            repeat: false
            onTriggered: startupSplash.opacity = 0.0
        }
    }
}
