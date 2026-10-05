import QtQuick
import QtQuick.Controls
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
    title: "ColdManual — Fast Offline Documentation Browser"
    color: Theme.background

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
        height: 30
        radius: 15
        color: Theme.surfaceElevated
        border.color: Theme.border
        border.width: 1
        visible: settingsMgr.windowDisplayMode !== "windowed"

        opacity: floatHover.hovered ? 1.0 : 0.35
        Behavior on opacity { NumberAnimation { duration: Theme.animDurationNormal } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 2

            // Minimize
            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 22
                radius: 4
                color: minArea.containsMouse ? Theme.surfaceHover : "transparent"
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
                Layout.preferredHeight: 22
                radius: 4
                color: restoreArea.containsMouse ? Theme.surfaceHover : "transparent"
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
                Layout.preferredHeight: 22
                radius: 4
                color: closeArea.containsMouse ? Theme.danger : "transparent"
                LucideIcon {
                    anchors.centerIn: parent
                    name: "x"
                    size: 11
                    color: closeArea.containsMouse ? "#ffffff" : Theme.textPrimary
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

        // Sidebar Navigation
        Rectangle {
            id: sidebarRect
            Layout.preferredWidth: window.sidebarMinimized ? 52 : 230
            Layout.fillHeight: true
            color: Theme.sidebarBg
            border.color: Theme.border
            border.width: 1
            clip: true

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Item {
                anchors.fill: parent

                // Top section (Logo, Search, Divider, Nav items)
                Column {
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 10

                    // 1. Logo
                    Item {
                        width: parent.width
                        height: 34

                        Image {
                            id: logoImg
                            width: 28
                            height: 28
                            source: Theme.logoUrl
                            sourceSize.width: 56
                            sourceSize.height: 56
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            anchors.verticalCenter: parent.verticalCenter
                            x: window.sidebarMinimized ? Math.round((parent.width - width) / 2) : 12
                            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        Column {
                            visible: !window.sidebarMinimized
                            anchors.left: logoImg.right
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: "ColdManual"
                                font.family: Theme.fontSans
                                font.pixelSize: 16
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "Offline Docs"
                                font.pixelSize: 10
                                color: Theme.textMuted
                            }
                        }
                    }

                    // 2. OmniSearch Button
                    Rectangle {
                        id: omniBtn
                        width: window.sidebarMinimized ? 36 : (parent.width - 20)
                        height: 34
                        radius: Theme.radiusMd
                        color: omniArea.containsMouse ? Theme.surfaceHover : Theme.surface
                        border.color: omniArea.containsMouse ? Theme.accent : Theme.border
                        border.width: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

                        LucideIcon {
                            id: searchIcon
                            name: "search"
                            size: 14
                            color: omniArea.containsMouse ? Theme.accent : Theme.textMuted
                            anchors.verticalCenter: parent.verticalCenter
                            x: window.sidebarMinimized ? Math.round((parent.width - size) / 2) : 10
                            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        Text {
                            visible: !window.sidebarMinimized
                            anchors.left: searchIcon.right
                            anchors.leftMargin: 8
                            anchors.right: ctrlKBadge.left
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search symbols..."
                            font.pixelSize: 12
                            color: Theme.textMuted
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            id: ctrlKBadge
                            visible: !window.sidebarMinimized
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 44
                            height: 18
                            radius: Theme.radiusSm
                            color: Theme.surfaceElevated

                            Text {
                                anchors.centerIn: parent
                                text: "Ctrl+K"
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.textMuted
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

                    // Divider
                    Rectangle {
                        width: window.sidebarMinimized ? (parent.width - 16) : (parent.width - 20)
                        height: 1
                        color: Theme.border
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // Nav Items
                    Column {
                        width: parent.width
                        spacing: 4

                        // Tab 0: Reader
                        Rectangle {
                            width: window.sidebarMinimized ? 38 : (parent.width - 16)
                            height: 38
                            radius: Theme.radiusSm
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: (currentTab === 0) ? Theme.accentDim : (navReaderArea.containsMouse ? Theme.surfaceHover : "transparent")
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                            // Active indicator pill
                            Rectangle {
                                visible: !window.sidebarMinimized
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: (currentTab === 0) ? 18 : 0
                                radius: 1.5
                                color: Theme.accent
                                opacity: (currentTab === 0) ? 1.0 : 0.0
                                Behavior on height { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Theme.animEasingDecel } }
                                Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                            }

                            LucideIcon {
                                id: tab0Icon
                                name: "book-open"
                                size: 16
                                color: (currentTab === 0) ? Theme.accent : Theme.textSecondary
                                anchors.verticalCenter: parent.verticalCenter
                                x: window.sidebarMinimized ? Math.round((parent.width - size) / 2) : 12
                                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            }

                            Text {
                                visible: !window.sidebarMinimized
                                anchors.left: tab0Icon.right
                                anchors.leftMargin: 10
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Reader"
                                font.pixelSize: 13
                                font.bold: currentTab === 0
                                color: (currentTab === 0) ? Theme.accent : Theme.textPrimary
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
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
                        Rectangle {
                            width: window.sidebarMinimized ? 38 : (parent.width - 16)
                            height: 38
                            radius: Theme.radiusSm
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: (currentTab === 1) ? Theme.accentDim : (navCatalogArea.containsMouse ? Theme.surfaceHover : "transparent")
                            opacity: networkMgr.isOnline ? 1.0 : 0.5
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }

                            // Active indicator pill
                            Rectangle {
                                visible: !window.sidebarMinimized
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: (currentTab === 1) ? 18 : 0
                                radius: 1.5
                                color: Theme.accent
                                opacity: (currentTab === 1) ? 1.0 : 0.0
                                Behavior on height { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Theme.animEasingDecel } }
                                Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                            }

                            LucideIcon {
                                id: tab1Icon
                                name: "compass"
                                size: 16
                                color: (currentTab === 1) ? Theme.accent : Theme.textSecondary
                                anchors.verticalCenter: parent.verticalCenter
                                x: window.sidebarMinimized ? Math.round((parent.width - size) / 2) : 12
                                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            }

                            // Minimized offline dot
                            Rectangle {
                                visible: window.sidebarMinimized && !networkMgr.isOnline
                                width: 6
                                height: 6
                                radius: 3
                                color: Theme.warning
                                anchors.top: tab1Icon.top
                                anchors.right: tab1Icon.right
                                anchors.topMargin: -2
                                anchors.rightMargin: -2
                            }

                            Text {
                                visible: !window.sidebarMinimized
                                anchors.left: tab1Icon.right
                                anchors.leftMargin: 10
                                anchors.right: offlineBadge.left
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Browse Catalog"
                                font.pixelSize: 13
                                font.bold: currentTab === 1
                                color: (currentTab === 1) ? Theme.accent : Theme.textPrimary
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            }

                            Rectangle {
                                id: offlineBadge
                                visible: !networkMgr.isOnline && !window.sidebarMinimized
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                height: 18
                                radius: 9
                                width: offlineBadgeRow.implicitWidth + 10
                                color: Theme.surfaceElevated
                                border.color: Theme.border
                                border.width: 1

                                RowLayout {
                                    id: offlineBadgeRow
                                    anchors.centerIn: parent
                                    spacing: 3
                                    LucideIcon {
                                        name: "wifi-off"
                                        size: 9
                                        color: Theme.textMuted
                                    }
                                    Text {
                                        text: "Offline"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: Theme.textMuted
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
                        Rectangle {
                            width: window.sidebarMinimized ? 38 : (parent.width - 16)
                            height: 38
                            radius: Theme.radiusSm
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: (currentTab === 2) ? Theme.accentDim : (navInstArea.containsMouse ? Theme.surfaceHover : "transparent")
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                            // Active indicator pill
                            Rectangle {
                                visible: !window.sidebarMinimized
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: (currentTab === 2) ? 18 : 0
                                radius: 1.5
                                color: Theme.accent
                                opacity: (currentTab === 2) ? 1.0 : 0.0
                                Behavior on height { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Theme.animEasingDecel } }
                                Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                            }

                            LucideIcon {
                                id: tab2Icon
                                name: "download"
                                size: 16
                                color: (currentTab === 2) ? Theme.accent : Theme.textSecondary
                                anchors.verticalCenter: parent.verticalCenter
                                x: window.sidebarMinimized ? Math.round((parent.width - size) / 2) : 12
                                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            }

                            // Minimized installed badge dot
                            Rectangle {
                                visible: window.sidebarMinimized && docsetMgr.installedCount > 0
                                width: 6
                                height: 6
                                radius: 3
                                color: Theme.accent
                                anchors.top: tab2Icon.top
                                anchors.right: tab2Icon.right
                                anchors.topMargin: -2
                                anchors.rightMargin: -2
                            }

                            Text {
                                visible: !window.sidebarMinimized
                                anchors.left: tab2Icon.right
                                anchors.leftMargin: 10
                                anchors.right: instBadge.left
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Installed"
                                font.pixelSize: 13
                                font.bold: currentTab === 2
                                color: (currentTab === 2) ? Theme.accent : Theme.textPrimary
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            }

                            // Count badge (expanded)
                            Rectangle {
                                id: instBadge
                                visible: !window.sidebarMinimized
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.max(20, instBadgeText.implicitWidth + 8)
                                height: 18
                                radius: 9
                                color: Theme.surfaceElevated

                                Text {
                                    id: instBadgeText
                                    anchors.centerIn: parent
                                    text: docsetMgr.installedCount
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Theme.textSecondary
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
                        Rectangle {
                            width: window.sidebarMinimized ? 38 : (parent.width - 16)
                            height: 38
                            radius: Theme.radiusSm
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: (currentTab === 3) ? Theme.accentDim : (navSettingsArea.containsMouse ? Theme.surfaceHover : "transparent")
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                            // Active indicator pill
                            Rectangle {
                                visible: !window.sidebarMinimized
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: (currentTab === 3) ? 18 : 0
                                radius: 1.5
                                color: Theme.accent
                                opacity: (currentTab === 3) ? 1.0 : 0.0
                                Behavior on height { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Theme.animEasingDecel } }
                                Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                            }

                            LucideIcon {
                                id: tab3Icon
                                name: "settings"
                                size: 16
                                color: (currentTab === 3) ? Theme.accent : Theme.textSecondary
                                anchors.verticalCenter: parent.verticalCenter
                                x: window.sidebarMinimized ? Math.round((parent.width - size) / 2) : 12
                                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            }

                            Text {
                                visible: !window.sidebarMinimized
                                anchors.left: tab3Icon.right
                                anchors.leftMargin: 10
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Settings"
                                font.pixelSize: 13
                                font.bold: currentTab === 3
                                color: (currentTab === 3) ? Theme.accent : Theme.textPrimary
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
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
                    anchors.bottomMargin: 10
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 8

                    // Arrow with Long Tail (toggles collapse/expand)
                    Item {
                        id: collapseArrowItem
                        width: parent.width
                        height: 22

                        // Tail: horizontal line right above storage & version
                        Rectangle {
                            id: arrowTail
                            visible: !window.sidebarMinimized
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: arrowHead.left
                            anchors.rightMargin: -4
                            anchors.verticalCenter: parent.verticalCenter
                            height: arrowMouseArea.containsMouse ? 2 : 1
                            color: arrowMouseArea.containsMouse ? Theme.accent : Theme.border
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            Behavior on height { NumberAnimation { duration: 100 } }
                        }

                        // Arrow Tip: chevron pointing right
                        LucideIcon {
                            id: arrowHead
                            name: "chevron-right"
                            size: 14
                            color: arrowMouseArea.containsMouse ? Theme.accent : (window.sidebarMinimized ? Theme.textSecondary : Theme.border)
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: window.sidebarMinimized ? undefined : parent.right
                            anchors.rightMargin: window.sidebarMinimized ? 0 : 10
                            anchors.horizontalCenter: window.sidebarMinimized ? parent.horizontalCenter : undefined
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
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
                            visible: !window.sidebarMinimized
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Storage: " + docsetMgr.totalStorageUsage
                            font.pixelSize: 11
                            color: Theme.textMuted
                        }

                        Text {
                            text: "v1.0"
                            font.pixelSize: 11
                            color: Theme.textMuted
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: window.sidebarMinimized ? undefined : parent.right
                            anchors.rightMargin: window.sidebarMinimized ? 0 : 12
                            anchors.horizontalCenter: window.sidebarMinimized ? parent.horizontalCenter : undefined
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
                    font.pixelSize: 17
                    font.bold: true
                    color: Theme.textPrimary
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Offline Documentation Browser"
                    font.pixelSize: 11
                    color: Theme.textMuted
                }
            }

            // Sleek micro-loader bar
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                width: 120
                height: 3
                radius: 1.5
                color: Theme.surfaceElevated
                clip: true

                Rectangle {
                    id: splashBar
                    width: 40
                    height: 3
                    radius: 1.5
                    color: Theme.accent

                    SequentialAnimation on x {
                        running: startupSplash.visible
                        loops: Animation.Infinite
                        NumberAnimation { from: -40; to: 120; duration: 950; easing.type: Easing.InOutQuad }
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
