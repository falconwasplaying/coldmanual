import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    signal openDocsetInReader(string docsetId, string docsetName)

    Component.onCompleted: {
        if (catalogMgr.totalItems === 0 && networkMgr.isOnline) {
            catalogMgr.refreshCatalog()
        }
    }

    Connections {
        target: networkMgr
        function onIsOnlineChanged() {
            if (networkMgr.isOnline && catalogMgr.totalItems === 0) {
                catalogMgr.refreshCatalog()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingMd

        // Header & Search
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingMd

            ColumnLayout {
                spacing: 2
                Text {
                    text: "Browse Documentation"
                    font.family: Theme.fontSans
                    font.pixelSize: 22
                    font.bold: true
                    color: Theme.textPrimary
                }
                Text {
                    text: "Download offline documentation for your favorite languages and frameworks"
                    font.pixelSize: 13
                    color: Theme.textMuted
                }
            }

            Item { Layout.fillWidth: true }

            // Material 3 Search Input
            Rectangle {
                width: 280
                height: 42
                radius: Theme.shapeFull
                color: Theme.surfaceContainerHigh
                border.color: searchInput.activeFocus ? Theme.primary : Theme.outlineVariant
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    LucideIcon {
                        name: "search"
                        size: 15
                        color: searchInput.activeFocus ? Theme.primary : Theme.textOnSurfaceVariant
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: Theme.fontSans
                        font.pixelSize: 13
                        color: Theme.textOnSurface
                        clip: true
                        onTextChanged: catalogMgr.searchQuery = text

                        Text {
                            anchors.fill: parent
                            text: "Filter languages..."
                            font.family: Theme.fontSans
                            font.pixelSize: 13
                            color: Theme.textOnSurfaceVariant
                            visible: !searchInput.text && !searchInput.activeFocus
                        }
                    }

                    LucideIcon {
                        name: "x"
                        size: 14
                        color: Theme.textOnSurfaceVariant
                        visible: searchInput.text.length > 0
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: searchInput.text = ""
                        }
                    }
                }
            }

            // Material 3 Refresh Button (Tonal Icon Button)
            Rectangle {
                width: 42
                height: 42
                radius: Theme.shapeFull
                color: refreshArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                border.color: Theme.outlineVariant
                border.width: 1
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                LucideIcon {
                    id: refreshIcon
                    anchors.centerIn: parent
                    name: "refresh-cw"
                    size: 16
                    color: Theme.primary
                    rotation: 0

                    RotationAnimation on rotation {
                        running: catalogMgr.isRefreshing
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 800
                    }
                }

                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: catalogMgr.refreshCatalog()
                }
            }
        }

        // Material 3 Filter Chips
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: catalogMgr.categories

                Rectangle {
                    readonly property bool isSelected: catalogMgr.selectedCategory === modelData
                    height: 32
                    radius: Theme.shapeSmall
                    width: catRow.implicitWidth + 24
                    color: isSelected ? Theme.secondaryContainer :
                           (catArea.containsMouse ? Qt.rgba(Theme.textOnSurface.r, Theme.textOnSurface.g, Theme.textOnSurface.b, 0.08) : Theme.surfaceContainerLow)
                    border.color: isSelected ? "transparent" : Theme.outlineVariant
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

                    RowLayout {
                        id: catRow
                        anchors.centerIn: parent
                        spacing: 6

                        LucideIcon {
                            visible: parent.parent.isSelected
                            name: "check"
                            size: 13
                            color: Theme.textOnSecondaryContainer
                        }

                        Text {
                            text: modelData
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            font.bold: parent.parent.isSelected
                            color: parent.parent.isSelected ? Theme.textOnSecondaryContainer : Theme.textOnSurfaceVariant
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        }
                    }

                    MouseArea {
                        id: catArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: catalogMgr.selectedCategory = modelData
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: catalogMgr.totalItems + " available"
                font.family: Theme.fontSans
                font.pixelSize: 12
                color: Theme.textOnSurfaceVariant
            }
        }

        // Loading State when refreshing with 0 items
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: catalogMgr.totalItems === 0 && catalogMgr.isRefreshing

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16

                LucideIcon {
                    Layout.alignment: Qt.AlignHCenter
                    name: "refresh-cw"
                    size: 32
                    color: Theme.accent
                    rotation: 0

                    RotationAnimation on rotation {
                        running: catalogMgr.isRefreshing
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 800
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Connecting to ColdManual database feed..."
                    font.family: Theme.fontSans
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.textPrimary
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Fetching the latest docset catalog directly from coldmanual-db"
                    font.pixelSize: 12
                    color: Theme.textMuted
                }
            }
        }

        // Empty State when 0 items in catalog and not refreshing
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: catalogGrid.count === 0 && !catalogMgr.isRefreshing

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                LucideIcon {
                    Layout.alignment: Qt.AlignHCenter
                    name: "book-open"
                    size: 48
                    color: Theme.textMuted
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: searchInput.text.length > 0 ? "No documentation matches found" : "No documentation available"
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.textPrimary
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: searchInput.text.length > 0 ? "Try adjusting your search or category filter." : "The documentation catalog is currently empty."
                    font.pixelSize: 13
                    color: Theme.textMuted
                }
            }
        }

        // Catalog Grid
        GridView {
            id: catalogGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: catalogGrid.count > 0
            clip: true
            cellWidth: Math.max(340, (width - 10) / Math.max(1, Math.floor(width / 340)))
            cellHeight: 228
            model: catalogMgr

            ScrollBar.vertical: ScrollBar {
                active: true
            }

            delegate: Item {
                width: catalogGrid.cellWidth
                height: catalogGrid.cellHeight

                // Material 3 Outlined / Elevated Card
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: Theme.shapeLarge
                    color: cardHoverArea.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow
                    border.color: cardHoverArea.containsMouse ? Theme.primary : Theme.outlineVariant
                    border.width: 1
                    scale: cardHoverArea.containsMouse ? 1.015 : 1.0
                    y: cardHoverArea.containsMouse ? -2 : 0

                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }
                    Behavior on scale { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Theme.animEasingDecel } }
                    Behavior on y { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Theme.animEasingDecel } }

                    MouseArea {
                        id: cardHoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        // Top Row: Official Logo + Name + Category Tag
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            DocLogo {
                                docId: (model.icon && model.icon !== "") ? model.icon : model.id
                                logoSource: model.logoUrl || ""
                                category: model.category || ""
                                size: 38
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: model.name
                                    font.family: Theme.fontSans
                                    font.pixelSize: 15
                                    font.bold: true
                                    color: Theme.textOnSurface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: model.category
                                    font.family: Theme.fontSans
                                    font.pixelSize: 11
                                    color: Theme.textOnSurfaceVariant
                                }
                            }

                            // Installed badge if applicable (M3 Tonal Chip)
                            Rectangle {
                                visible: model.isInstalled
                                height: 22
                                width: instRow.implicitWidth + 14
                                radius: Theme.shapeSmall
                                color: Theme.successBg

                                RowLayout {
                                    id: instRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    LucideIcon {
                                        name: "check"
                                        size: 11
                                        color: Theme.success
                                    }

                                    Text {
                                        text: model.installedVersion
                                        font.family: Theme.fontSans
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.success
                                    }
                                }
                            }
                        }

                        // Description
                        Text {
                            text: model.description
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            color: Theme.textOnSurfaceVariant
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }

                        // Version selector row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Version:"
                                font.family: Theme.fontSans
                                font.pixelSize: 12
                                color: Theme.textOnSurfaceVariant
                            }

                            VersionSelector {
                                id: versionPicker
                                Layout.fillWidth: true
                                versionsModel: model.versions
                                enabled: !model.isDownloading
                            }
                        }

                        // Download progress or action buttons
                        Item {
                            Layout.fillWidth: true
                            height: 34

                            // Downloading state
                            RowLayout {
                                anchors.fill: parent
                                visible: model.isDownloading
                                spacing: 8

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    ProgressBar {
                                        Layout.fillWidth: true
                                        value: model.downloadProgress
                                        background: Rectangle {
                                            implicitHeight: 6
                                            radius: Theme.shapeFull
                                            color: Theme.surfaceContainerHighest
                                        }
                                        contentItem: Item {
                                            implicitHeight: 6
                                            Rectangle {
                                                width: parent.width * model.downloadProgress
                                                height: parent.height
                                                radius: Theme.shapeFull
                                                color: Theme.primary
                                                Behavior on width {
                                                    NumberAnimation { duration: 160; easing.type: Theme.animEasingDecel }
                                                }
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: Math.round(model.downloadProgress * 100) + "%"
                                            font.family: Theme.fontSans
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: Theme.primary
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: model.downloadSpeed
                                            font.family: Theme.fontSans
                                            font.pixelSize: 10
                                            color: Theme.textOnSurfaceVariant
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: Theme.shapeFull
                                    color: cancelArea.containsMouse ? Theme.errorContainer : Theme.surfaceContainerHighest
                                    scale: cancelArea.pressed ? 0.92 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 80 } }
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                                    LucideIcon {
                                        anchors.centerIn: parent
                                        name: "x"
                                        size: 12
                                        color: Theme.danger
                                    }

                                    MouseArea {
                                        id: cancelArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: downloader.cancelDownload(model.id)
                                    }
                                }
                            }

                            // Normal / Installed State Buttons (Material 3 Buttons)
                            RowLayout {
                                anchors.fill: parent
                                visible: !model.isDownloading
                                spacing: 8

                                // Update Available button (M3 Warning Pill)
                                Rectangle {
                                    visible: model.isInstalled && model.updateAvailable
                                    Layout.fillWidth: true
                                    height: 34
                                    radius: Theme.shapeFull
                                    color: updateArea.containsMouse ? Theme.warning : Theme.warningBg
                                    border.color: Theme.warning
                                    border.width: 1
                                    scale: updateArea.pressed ? 0.96 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 80 } }
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        LucideIcon {
                                            name: "zap"
                                            size: 13
                                            color: updateArea.containsMouse ? "#000000" : Theme.warning
                                        }
                                        Text {
                                            text: "Update Available"
                                            font.family: Theme.fontSans
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: updateArea.containsMouse ? "#000000" : Theme.warning
                                        }
                                    }

                                    MouseArea {
                                        id: updateArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: docsetMgr.installDocset(model.id, "Latest Stable")
                                    }
                                }

                                // Install / Reinstall button (M3 Filled / Tonal Button)
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 34
                                    radius: Theme.shapeFull
                                    color: {
                                        if (model.isInstalled) {
                                            return instBtnArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                                        } else {
                                            return instBtnArea.containsMouse ? Theme.accentHover : Theme.primary
                                        }
                                    }
                                    border.color: model.isInstalled ? Theme.outlineVariant : "transparent"
                                    border.width: model.isInstalled ? 1 : 0
                                    scale: instBtnArea.pressed ? 0.96 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 80 } }
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        LucideIcon {
                                            name: model.isInstalled ? "refresh-cw" : "download"
                                            size: 13
                                            color: model.isInstalled ? Theme.textOnSurface : Theme.textOnPrimary
                                        }
                                        Text {
                                            text: model.isInstalled ? "Reinstall" : "Download & Install"
                                            font.family: Theme.fontSans
                                            font.pixelSize: 12
                                            font.bold: !model.isInstalled
                                            color: model.isInstalled ? Theme.textOnSurface : Theme.textOnPrimary
                                        }
                                    }

                                    MouseArea {
                                        id: instBtnArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            docsetMgr.installDocset(model.id, versionPicker.selectedVersion)
                                        }
                                    }
                                }

                                // Read button if installed (M3 Tonal Icon Button)
                                Rectangle {
                                    visible: model.isInstalled
                                    width: 38
                                    height: 34
                                    radius: Theme.shapeFull
                                    color: readBtnArea.containsMouse ? Theme.surfaceContainerHighest : Theme.secondaryContainer
                                    border.color: Theme.outlineVariant
                                    border.width: 1
                                    scale: readBtnArea.pressed ? 0.94 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 80 } }
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                                    LucideIcon {
                                        anchors.centerIn: parent
                                        name: "book-open"
                                        size: 14
                                        color: Theme.textOnSecondaryContainer
                                    }

                                    MouseArea {
                                        id: readBtnArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.openDocsetInReader(model.id, model.name)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Offline Overlay State
    Rectangle {
        id: offlineOverlay
        anchors.fill: parent
        color: Theme.background
        visible: !networkMgr.isOnline
        z: 100

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16
            width: Math.min(parent.width - 64, 460)

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 64
                height: 64
                radius: 32
                color: Theme.surfaceElevated
                border.color: Theme.border
                border.width: 1

                LucideIcon {
                    anchors.centerIn: parent
                    name: "wifi-off"
                    size: 28
                    color: Theme.textMuted
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Catalog Unavailable Offline"
                font.family: Theme.fontSans
                font.pixelSize: 18
                font.bold: true
                color: Theme.textPrimary
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "An active internet connection is required to browse the documentation catalog and download manuals."
                font.pixelSize: 13
                color: Theme.textSecondary
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                width: retryRow.implicitWidth + 32
                height: 38
                radius: Theme.radiusMd
                color: retryArea.containsMouse ? Theme.accentHover : Theme.accent
                scale: retryArea.pressed ? 0.96 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                RowLayout {
                    id: retryRow
                    anchors.centerIn: parent
                    spacing: 8

                    LucideIcon {
                        name: "refresh-cw"
                        size: 14
                        color: Theme.textOnAccent
                        rotation: 0

                        RotationAnimation on rotation {
                            running: networkMgr.isChecking
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 800
                        }
                    }

                    Text {
                        text: networkMgr.isChecking ? "Checking Connection..." : "Check Connection"
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.textOnAccent
                    }
                }

                MouseArea {
                    id: retryArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !networkMgr.isChecking
                    onClicked: networkMgr.checkConnectivity()
                }
            }
        }
    }
}
