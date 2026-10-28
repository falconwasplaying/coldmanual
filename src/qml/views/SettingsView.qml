import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import ".."
import "../components"

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingMd

        // Header
        ColumnLayout {
            spacing: 2
            Text {
                text: "Settings"
                font.family: Theme.fontSans
                font.pixelSize: 22
                font.bold: true
                color: Theme.textOnSurface
            }
            Text {
                text: "Configure storage location, update preferences, and appearance"
                font.family: Theme.fontSans
                font.pixelSize: 13
                color: Theme.textOnSurfaceVariant
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.outlineVariant
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width - 20
                spacing: 20

                // Storage Section (Material 3 Card)
                Rectangle {
                    Layout.fillWidth: true
                    height: storageCol.implicitHeight + 28
                    radius: Theme.shapeLarge
                    color: Theme.surfaceContainerLow
                    border.color: Theme.outlineVariant
                    border.width: 1

                    ColumnLayout {
                        id: storageCol
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        RowLayout {
                            spacing: 8
                            LucideIcon {
                                name: "folder"
                                size: 16
                                color: Theme.primary
                            }
                            Text {
                                text: "Storage Location"
                                font.family: Theme.fontSans
                                font.pixelSize: 15
                                font.bold: true
                                color: Theme.textOnSurface
                            }
                        }

                        Text {
                            text: "Directory where downloaded documentation sets and SQLite indexes are stored."
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            color: Theme.textOnSurfaceVariant
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                height: 38
                                radius: Theme.shapeSmall
                                color: Theme.surfaceContainerHigh
                                border.color: Theme.outlineVariant
                                border.width: 1

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    verticalAlignment: Text.AlignVCenter
                                    text: settingsMgr.storagePath
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    color: Theme.textOnSurface
                                    elide: Text.ElideMiddle
                                }
                            }

                            // Material 3 Tonal Button: Open Folder
                            Rectangle {
                                width: openFolderRow.implicitWidth + 28
                                height: 38
                                radius: Theme.shapeFull
                                color: openFolderArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                                border.color: Theme.outlineVariant
                                border.width: 1

                                RowLayout {
                                    id: openFolderRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    LucideIcon {
                                        name: "external-link"
                                        size: 13
                                        color: Theme.textOnSurface
                                    }
                                    Text {
                                        text: "Open Folder"
                                        font.family: Theme.fontSans
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: Theme.textOnSurface
                                    }
                                }

                                MouseArea {
                                    id: openFolderArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Qt.openUrlExternally("file:///" + settingsMgr.storagePath)
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Current storage footprint: " + docsetMgr.totalStorageUsage
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.primary
                        }
                    }
                }

                // Automatic Updates Section (Material 3 Card)
                Rectangle {
                    Layout.fillWidth: true
                    height: updatesCol.implicitHeight + 28
                    radius: Theme.shapeLarge
                    color: Theme.surfaceContainerLow
                    border.color: Theme.outlineVariant
                    border.width: 1

                    ColumnLayout {
                        id: updatesCol
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        RowLayout {
                            spacing: 8
                            LucideIcon {
                                name: "refresh-cw"
                                size: 16
                                color: Theme.primary
                            }
                            Text {
                                text: "Automatic Updates"
                                font.family: Theme.fontSans
                                font.pixelSize: 15
                                font.bold: true
                                color: Theme.textOnSurface
                            }
                        }

                        Text {
                            text: "ColdManual checks for new releases of libraries you have set to 'Latest Stable'."
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            color: Theme.textOnSurfaceVariant
                        }

                        // 1. Enable Automatic Background Checks
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: Math.max(autoCheckCol.implicitHeight, autoCheckSwitch.height)

                            ColumnLayout {
                                id: autoCheckCol
                                anchors.left: parent.left
                                anchors.right: autoCheckSwitch.left
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: "Enable Automatic Background Checks"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.textOnSurface
                                }
                                Text {
                                    text: "Periodically check remote manifests and notify when updates exist"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 11
                                    color: Theme.textOnSurfaceVariant
                                }
                            }

                            ToggleSwitch {
                                id: autoCheckSwitch
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                checked: settingsMgr.autoUpdateEnabled
                                onToggled: function(val) {
                                    settingsMgr.autoUpdateEnabled = val
                                }
                            }
                        }

                        // 2. Check Frequency (Segmented Pill)
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            opacity: settingsMgr.autoUpdateEnabled ? 1.0 : 0.4
                            enabled: settingsMgr.autoUpdateEnabled
                            Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }

                            Text {
                                text: "Check Frequency:"
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                                font.bold: true
                                color: Theme.textOnSurface
                            }

                            SegmentedPill {
                                width: 440
                                height: 36
                                currentValue: {
                                    var h = settingsMgr.checkIntervalHours
                                    if (h <= 6) return "6"
                                    if (h <= 12) return "12"
                                    if (h <= 24) return "24"
                                    return "168"
                                }
                                options: [
                                    { id: "6", label: "Every 6 Hours" },
                                    { id: "12", label: "Every 12 Hours" },
                                    { id: "24", label: "Daily" },
                                    { id: "168", label: "Weekly" }
                                ]
                                onValueSelected: function(val) {
                                    settingsMgr.checkIntervalHours = parseInt(val)
                                }
                            }

                            Text {
                                text: {
                                    var h = settingsMgr.checkIntervalHours
                                    if (h <= 6) return "Checks for documentation updates every 6 hours in the background"
                                    if (h <= 12) return "Checks for documentation updates every 12 hours in the background"
                                    if (h <= 24) return "Checks for documentation updates once a day (every 24 hours) in the background"
                                    return "Checks for documentation updates once a week (every 7 days) in the background"
                                }
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                                color: Theme.textOnSurfaceVariant
                            }
                        }
                    }
                }

                // Window Display Mode Section (Material 3 Card)
                Rectangle {
                    Layout.fillWidth: true
                    height: windowModeCol.implicitHeight + 28
                    radius: Theme.shapeLarge
                    color: Theme.surfaceContainerLow
                    border.color: Theme.outlineVariant
                    border.width: 1

                    ColumnLayout {
                        id: windowModeCol
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        RowLayout {
                            spacing: 8
                            LucideIcon {
                                name: "app-window"
                                size: 16
                                color: Theme.primary
                            }
                            Text {
                                text: "Window Display Mode"
                                font.family: Theme.fontSans
                                font.pixelSize: 15
                                font.bold: true
                                color: Theme.textOnSurface
                            }
                        }

                        Text {
                            text: "Select your preferred window presentation. You can also toggle fullscreen at any time using F11."
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            color: Theme.textOnSurfaceVariant
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14

                            WindowModePill {
                                id: windowModePill
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: {
                                    if (settingsMgr.windowDisplayMode === "borderless") {
                                        return "Frameless window covering the entire screen"
                                    } else if (settingsMgr.windowDisplayMode === "fullscreen") {
                                        return "Distraction-free fullscreen view"
                                    } else {
                                        return "Standard operating system window"
                                    }
                                }
                                font.family: Theme.fontSans
                                font.pixelSize: 12
                                color: Theme.textOnSurfaceVariant
                            }
                        }
                    }
                }

                // Browser Tabs & Title Bar Section (Material 3 Card)
                Rectangle {
                    Layout.fillWidth: true
                    height: tabSettingsCol.implicitHeight + 28
                    radius: Theme.shapeLarge
                    color: Theme.surfaceContainerLow
                    border.color: Theme.outlineVariant
                    border.width: 1

                    ColumnLayout {
                        id: tabSettingsCol
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 14

                        RowLayout {
                            spacing: 8
                            LucideIcon {
                                name: "layout"
                                size: 16
                                color: Theme.primary
                            }
                            Text {
                                text: "Browser Tabs & Title Bar"
                                font.family: Theme.fontSans
                                font.pixelSize: 15
                                font.bold: true
                                color: Theme.textOnSurface
                            }
                        }

                        Text {
                            text: "Customize tab close buttons, floating hover preview cards, and live memory usage."
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            color: Theme.textOnSurfaceVariant
                        }

                        // 1. Close Button (X) Mode
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "Tab Close Button (\"X\") Visibility:"
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                                font.bold: true
                                color: Theme.textOnSurface
                            }

                            SegmentedPill {
                                width: 380
                                height: 36
                                currentValue: settingsMgr.tabCloseButtonMode
                                options: [
                                    { id: "hover", label: "On Hover" },
                                    { id: "always", label: "Always Show" },
                                    { id: "never", label: "Hidden" }
                                ]
                                onValueSelected: function(val) {
                                    settingsMgr.tabCloseButtonMode = val
                                }
                            }
                        }

                        // 2. Tab Hover Preview Card
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: Math.max(hoverCardCol.implicitHeight, hoverCardSwitch.height)

                            ColumnLayout {
                                id: hoverCardCol
                                anchors.left: parent.left
                                anchors.right: hoverCardSwitch.left
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: "Enable Tab Hover Preview Cards"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.textOnSurface
                                }
                                Text {
                                    text: "Shows a floating card preview with document title, section, and memory when hovering over a tab"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 11
                                    color: Theme.textOnSurfaceVariant
                                }
                            }

                            ToggleSwitch {
                                id: hoverCardSwitch
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                checked: settingsMgr.tabHoverPreviewEnabled
                                onToggled: function(val) {
                                    settingsMgr.tabHoverPreviewEnabled = val
                                }
                            }
                        }

                        // 3. Memory (RAM) Usage Mode
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            RowLayout {
                                spacing: 8
                                Text {
                                    text: "Memory (RAM) Footprint Display:"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.textOnSurface
                                }

                                Rectangle {
                                    Layout.preferredHeight: 22
                                    Layout.preferredWidth: ramBadgeRow.implicitWidth + 14
                                    radius: Theme.shapeFull
                                    color: Theme.secondaryContainer

                                    RowLayout {
                                        id: ramBadgeRow
                                        anchors.centerIn: parent
                                        spacing: 5

                                        LucideIcon {
                                            name: "activity"
                                            size: 11
                                            color: Theme.textOnSecondaryContainer
                                        }

                                        Text {
                                            text: "Total: " + settingsMgr.processMemoryUsage
                                            font.family: Theme.fontSans
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: Theme.textOnSecondaryContainer
                                        }
                                    }
                                }
                            }

                            SegmentedPill {
                                width: 480
                                height: 36
                                currentValue: settingsMgr.tabRamUsageMode
                                options: [
                                    { id: "preview", label: "Hover Card" },
                                    { id: "tab", label: "On Tab" },
                                    { id: "both", label: "Both" },
                                    { id: "none", label: "Hidden" }
                                ]
                                onValueSelected: function(val) {
                                    settingsMgr.tabRamUsageMode = val
                                }
                            }

                            Text {
                                text: "Tabs display individual memory usage (Chrome Memory Saver style). Total application working set is shown above."
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                                color: Theme.textOnSurfaceVariant
                            }
                        }
                    }
                }

                // Appearance & Reader Section (Material 3 Card)
                Rectangle {
                    Layout.fillWidth: true
                    height: appearCol.implicitHeight + 28
                    radius: Theme.shapeLarge
                    color: Theme.surfaceContainerLow
                    border.color: Theme.outlineVariant
                    border.width: 1

                    ColumnLayout {
                        id: appearCol
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 14

                        RowLayout {
                            spacing: 8
                            LucideIcon {
                                name: "sparkles"
                                size: 16
                                color: Theme.primary
                            }
                            Text {
                                text: "Appearance & Typography"
                                font.family: Theme.fontSans
                                font.pixelSize: 15
                                font.bold: true
                                color: Theme.textOnSurface
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14

                            Text {
                                text: "Theme:"
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                                color: Theme.textOnSurface
                            }

                            SegmentedPill {
                                width: 220
                                height: 36
                                currentValue: settingsMgr.themeMode
                                options: [
                                    { id: "dark", label: "Dark", icon: "moon" },
                                    { id: "light", label: "Light", icon: "sun" }
                                ]
                                onValueSelected: function(val) {
                                    settingsMgr.themeMode = val
                                }
                            }
                        }

                        // Reader Font Size
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Reader Base Font Size:"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 13
                                    color: Theme.textOnSurface
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: settingsMgr.readerFontSize + " px"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.primary
                                }
                            }

                            Slider {
                                Layout.fillWidth: true
                                from: 11
                                to: 24
                                stepSize: 1
                                value: settingsMgr.readerFontSize
                                onMoved: settingsMgr.readerFontSize = Math.round(value)
                            }
                        }
                    }
                }

                // Reset Action Card
                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: Theme.shapeLarge
                    color: resetArea.containsMouse ? Theme.errorContainer : Theme.surfaceContainerLow
                    border.color: resetArea.containsMouse ? Theme.danger : Theme.outlineVariant
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        LucideIcon {
                            name: "rotate-ccw"
                            size: 14
                            color: Theme.danger
                        }
                        Text {
                            text: "Reset All Settings to Defaults"
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.danger
                        }
                    }

                    MouseArea {
                        id: resetArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsMgr.resetToDefaults()
                    }
                }
            }
        }
    }
}
