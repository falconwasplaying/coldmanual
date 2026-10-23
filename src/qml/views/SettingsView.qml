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
                color: Theme.onSurface
            }
            Text {
                text: "Configure storage location, update preferences, and appearance"
                font.family: Theme.fontSans
                font.pixelSize: 13
                color: Theme.onSurfaceVariant
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
                                color: Theme.onSurface
                            }
                        }

                        Text {
                            text: "Directory where downloaded documentation sets and SQLite indexes are stored."
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            color: Theme.onSurfaceVariant
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
                                    color: Theme.onSurface
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
                                        color: Theme.onSurface
                                    }
                                    Text {
                                        text: "Open Folder"
                                        font.family: Theme.fontSans
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: Theme.onSurface
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
                                color: Theme.onSurface
                            }
                        }

                        Text {
                            text: "ColdManual checks for new releases of libraries you have set to 'Latest Stable'."
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            color: Theme.onSurfaceVariant
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: "Enable Automatic Background Checks"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.onSurface
                                }
                                Text {
                                    text: "Periodically check remote manifests and notify when updates exist"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 11
                                    color: Theme.onSurfaceVariant
                                }
                            }

                            Switch {
                                checked: settingsMgr.autoUpdateEnabled
                                onToggled: settingsMgr.autoUpdateEnabled = checked
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            enabled: settingsMgr.autoUpdateEnabled

                            Text {
                                text: "Check Frequency:"
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                                color: Theme.onSurface
                            }

                            ComboBox {
                                id: intervalCombo
                                model: ["Every 6 Hours", "Every 12 Hours", "Daily (24 Hours)", "Weekly (168 Hours)"]
                                currentIndex: {
                                    var h = settingsMgr.checkIntervalHours
                                    if (h <= 6) return 0
                                    if (h <= 12) return 1
                                    if (h <= 24) return 2
                                    return 3
                                }
                                onActivated: function(index) {
                                    if (index === 0) settingsMgr.checkIntervalHours = 6
                                    else if (index === 1) settingsMgr.checkIntervalHours = 12
                                    else if (index === 2) settingsMgr.checkIntervalHours = 24
                                    else if (index === 3) settingsMgr.checkIntervalHours = 168
                                }
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
                                color: Theme.onSurface
                            }
                        }

                        Text {
                            text: "Select your preferred window presentation. You can also toggle fullscreen at any time using F11."
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            color: Theme.onSurfaceVariant
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
                                color: Theme.onSurfaceVariant
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
                                color: Theme.onSurface
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14

                            Text {
                                text: "Theme:"
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                                color: Theme.onSurface
                            }

                            // Material 3 Segmented Theme Selector
                            Rectangle {
                                width: 196
                                height: 36
                                radius: Theme.shapeFull
                                color: Theme.surfaceContainerHigh
                                border.color: Theme.outlineVariant
                                border.width: 1

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    spacing: 2

                                    // Dark segment
                                    Rectangle {
                                        width: (parent.width - 2) / 2
                                        height: parent.height
                                        radius: Theme.shapeFull
                                        color: settingsMgr.themeMode === "dark" ? Theme.secondaryContainer : "transparent"
                                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            LucideIcon {
                                                name: "moon"
                                                size: 13
                                                color: settingsMgr.themeMode === "dark" ? Theme.onSecondaryContainer : Theme.onSurfaceVariant
                                            }
                                            Text {
                                                text: "Dark"
                                                font.family: Theme.fontSans
                                                font.pixelSize: 12
                                                font.bold: settingsMgr.themeMode === "dark"
                                                color: settingsMgr.themeMode === "dark" ? Theme.onSecondaryContainer : Theme.onSurfaceVariant
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: settingsMgr.themeMode = "dark"
                                        }
                                    }

                                    // Light segment
                                    Rectangle {
                                        width: (parent.width - 2) / 2
                                        height: parent.height
                                        radius: Theme.shapeFull
                                        color: settingsMgr.themeMode === "light" ? Theme.secondaryContainer : "transparent"
                                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            LucideIcon {
                                                name: "sun"
                                                size: 13
                                                color: settingsMgr.themeMode === "light" ? Theme.onSecondaryContainer : Theme.onSurfaceVariant
                                            }
                                            Text {
                                                text: "Light"
                                                font.family: Theme.fontSans
                                                font.pixelSize: 12
                                                font.bold: settingsMgr.themeMode === "light"
                                                color: settingsMgr.themeMode === "light" ? Theme.onSecondaryContainer : Theme.onSurfaceVariant
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: settingsMgr.themeMode = "light"
                                        }
                                    }
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
                                    color: Theme.onSurface
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
