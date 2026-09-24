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

    Component.onCompleted: {
        if (docsetMgr.installedCount > 0) {
            currentTab = 0
            var firstDoc = docsetMgr.getInstalledDocset(docsetMgr.data(docsetMgr.index(0), 1).toString())
            if (firstDoc.indexPath) {
                readerView.openDocument(firstDoc.id, firstDoc.name, firstDoc.indexPath, firstDoc.name)
            }
        } else {
            currentTab = 1
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
        onActivated: currentTab = 1
    }
    Shortcut {
        sequence: "Ctrl+3"
        onActivated: currentTab = 2
    }
    Shortcut {
        sequence: "Ctrl+,"
        onActivated: currentTab = 3
    }
    Shortcut {
        sequence: "F11"
        onActivated: {
            if (window.visibility === Window.FullScreen) {
                window.visibility = Window.Windowed
            } else {
                window.visibility = Window.FullScreen
            }
        }
    }

    onClosing: function(close) {
        var stateStr = "normal"
        if (window.visibility === Window.Maximized) {
            stateStr = "maximized"
        } else if (window.visibility === Window.FullScreen) {
            stateStr = "fullscreen"
        }
        settingsMgr.saveWindowGeometry(window.x, window.y, window.width, window.height, stateStr)
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar Navigation
        Rectangle {
            Layout.preferredWidth: 230
            Layout.fillHeight: true
            color: Theme.sidebarBg
            border.color: Theme.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // Logo
                RowLayout {
                    spacing: 10
                    Rectangle {
                        width: 34
                        height: 34
                        radius: Theme.radiusSm
                        color: Theme.accent

                        LucideIcon {
                            anchors.centerIn: parent
                            name: "snowflake"
                            size: 18
                            color: "#ffffff"
                        }
                    }

                    ColumnLayout {
                        spacing: 0
                        Text {
                            text: "ColdManual"
                            font.family: Theme.fontSans
                            font.pixelSize: 17
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

                // Omni-Search Trigger Button
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: Theme.radiusMd
                    color: omniArea.containsMouse ? Theme.surfaceHover : Theme.surface
                    border.color: Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        LucideIcon {
                            name: "search"
                            size: 13
                            color: Theme.textMuted
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Search symbols..."
                            font.pixelSize: 12
                            color: Theme.textMuted
                        }

                        Rectangle {
                            width: 48
                            height: 20
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
                    }

                    MouseArea {
                        id: omniArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: omniSearch.open()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                // Nav Items
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    // Tab 0: Reader
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: Theme.radiusSm
                        color: (currentTab === 0) ? Theme.accentDim : (navReaderArea.containsMouse ? Theme.surfaceHover : "transparent")
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                        // Active Indicator Pill
                        Rectangle {
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

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            LucideIcon {
                                name: "book-open"
                                size: 15
                                color: (currentTab === 0) ? Theme.accent : Theme.textSecondary
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Reader"
                                font.pixelSize: 13
                                font.bold: currentTab === 0
                                color: (currentTab === 0) ? Theme.accent : Theme.textPrimary
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
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: Theme.radiusSm
                        color: (currentTab === 1) ? Theme.accentDim : (navCatalogArea.containsMouse ? Theme.surfaceHover : "transparent")
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                        // Active Indicator Pill
                        Rectangle {
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

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            LucideIcon {
                                name: "compass"
                                size: 15
                                color: (currentTab === 1) ? Theme.accent : Theme.textSecondary
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Browse Catalog"
                                font.pixelSize: 13
                                font.bold: currentTab === 1
                                color: (currentTab === 1) ? Theme.accent : Theme.textPrimary
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            }
                        }

                        MouseArea {
                            id: navCatalogArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: currentTab = 1
                        }
                    }

                    // Tab 2: Installed & Updates
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: Theme.radiusSm
                        color: (currentTab === 2) ? Theme.accentDim : (navInstArea.containsMouse ? Theme.surfaceHover : "transparent")
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                        // Active Indicator Pill
                        Rectangle {
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

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            LucideIcon {
                                name: "download"
                                size: 15
                                color: (currentTab === 2) ? Theme.accent : Theme.textSecondary
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Installed"
                                font.pixelSize: 13
                                font.bold: currentTab === 2
                                color: (currentTab === 2) ? Theme.accent : Theme.textPrimary
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            }

                            // Count badge
                            Rectangle {
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
                        Layout.fillWidth: true
                        height: 38
                        radius: Theme.radiusSm
                        color: (currentTab === 3) ? Theme.accentDim : (navSettingsArea.containsMouse ? Theme.surfaceHover : "transparent")
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                        // Active Indicator Pill
                        Rectangle {
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

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            LucideIcon {
                                name: "settings"
                                size: 15
                                color: (currentTab === 3) ? Theme.accent : Theme.textSecondary
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Settings"
                                font.pixelSize: 13
                                font.bold: currentTab === 3
                                color: (currentTab === 3) ? Theme.accent : Theme.textPrimary
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

                Item { Layout.fillHeight: true }

                // Sidebar Footer info
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Storage: " + docsetMgr.totalStorageUsage
                        font.pixelSize: 11
                        color: Theme.textMuted
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "v1.0"
                        font.pixelSize: 11
                        color: Theme.textMuted
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
                onNavigateToCatalog: window.currentTab = 1
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
                onNavigateToCatalog: window.currentTab = 1
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

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 48
                height: 48
                radius: Theme.radiusMd
                color: Theme.accent

                LucideIcon {
                    anchors.centerIn: parent
                    name: "snowflake"
                    size: 26
                    color: "#ffffff"
                }

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
