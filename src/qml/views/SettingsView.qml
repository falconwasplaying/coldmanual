import QtQuick
import QtQuick.Controls
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
                color: Theme.textPrimary
            }
            Text {
                text: "Configure storage location, update preferences, and appearance"
                font.pixelSize: 13
                color: Theme.textMuted
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width - 20
                spacing: 20

                // Storage Section
                Rectangle {
                    Layout.fillWidth: true
                    height: storageCol.implicitHeight + 28
                    radius: Theme.radiusMd
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        id: storageCol
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        RowLayout {
                            spacing: 8
                            LucideIcon {
                                name: "folder"
                                size: 16
                                color: Theme.accent
                            }
                            Text {
                                text: "Storage Location"
                                font.pixelSize: 15
                                font.bold: true
                                color: Theme.textPrimary
                            }
                        }

                        Text {
                            text: "Directory where downloaded documentation sets and SQLite indexes are stored."
                            font.pixelSize: 12
                            color: Theme.textMuted
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                radius: Theme.radiusSm
                                color: Theme.surfaceElevated
                                border.color: Theme.border
                                border.width: 1

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: Text.AlignVCenter
                                    text: settingsMgr.storagePath
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    color: Theme.textPrimary
                                    elide: Text.ElideMiddle
                                }
                            }

                            Rectangle {
                                width: openFolderRow.implicitWidth + 24
                                height: 36
                                radius: Theme.radiusSm
                                color: openFolderArea.containsMouse ? Theme.surfaceHover : Theme.surfaceElevated
                                border.color: Theme.border
                                border.width: 1

                                RowLayout {
                                    id: openFolderRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    LucideIcon {
                                        name: "external-link"
                                        size: 13
                                        color: Theme.textPrimary
                                    }
                                    Text {
                                        text: "Open Folder"
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: Theme.textPrimary
                                    }
                                }

                                MouseArea {
                                    id: openFolderArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        Qt.openUrlExternally("file:///" + settingsMgr.storagePath)
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Current storage footprint: " + docsetMgr.totalStorageUsage
                            font.pixelSize: 12
                            color: Theme.accent
                        }
                    }
                }

                // Automatic Updates Section
                Rectangle {
                    Layout.fillWidth: true
                    height: updatesCol.implicitHeight + 28
                    radius: Theme.radiusMd
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        id: updatesCol
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        RowLayout {
                            spacing: 8
                            LucideIcon {
                                name: "refresh-cw"
                                size: 16
                                color: Theme.accent
                            }
                            Text {
                                text: "Automatic Updates"
                                font.pixelSize: 15
                                font.bold: true
                                color: Theme.textPrimary
                            }
                        }

                        Text {
                            text: "ColdManual checks for new releases of libraries you have set to 'Latest Stable'."
                            font.pixelSize: 12
                            color: Theme.textMuted
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: "Enable Automatic Background Checks"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.textPrimary
                                }
                                Text {
                                    text: "Periodically check remote manifests and notify when updates exist"
                                    font.pixelSize: 11
                                    color: Theme.textMuted
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
                                font.pixelSize: 13
                                color: Theme.textPrimary
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

                // Window Display Mode Section
                Rectangle {
                    Layout.fillWidth: true
                    height: windowModeCol.implicitHeight + 28
                    radius: Theme.radiusMd
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        id: windowModeCol
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        RowLayout {
                            spacing: 8
                            LucideIcon {
                                name: "app-window"
                                size: 16
                                color: Theme.accent
                            }
                            Text {
                                text: "Window Display Mode"
                                font.pixelSize: 15
                                font.bold: true
                                color: Theme.textPrimary
                            }
                        }

                        Text {
                            text: "Select your preferred window presentation. You can also toggle fullscreen at any time using F11."
                            font.pixelSize: 12
                            color: Theme.textMuted
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
                                        return "Frameless window with custom controls"
                                    } else if (settingsMgr.windowDisplayMode === "fullscreen") {
                                        return "Distraction-free fullscreen view"
                                    } else {
                                        return "Standard operating system window"
                                    }
                                }
                                font.pixelSize: 12
                                color: Theme.textMuted
                            }
                        }
                    }
                }

                // Appearance & Reader Section
                Rectangle {
                    Layout.fillWidth: true
                    height: appearCol.implicitHeight + 28
                    radius: Theme.radiusMd
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        id: appearCol
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 14

                        RowLayout {
                            spacing: 8
                            LucideIcon {
                                name: "sparkles"
                                size: 16
                                color: Theme.accent
                            }
                            Text {
                                text: "Appearance & Typography"
                                font.pixelSize: 15
                                font.bold: true
                                color: Theme.textPrimary
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14

                            Text {
                                text: "Theme:"
                                font.pixelSize: 13
                                color: Theme.textPrimary
                            }

                            RowLayout {
                                spacing: 8

                                Rectangle {
                                    width: 90
                                    height: 32
                                    radius: Theme.radiusSm
                                    color: settingsMgr.themeMode === "dark" ? Theme.accent : Theme.surfaceElevated
                                    border.color: Theme.border
                                    border.width: 1

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        LucideIcon {
                                            name: "moon"
                                            size: 13
                                            color: settingsMgr.themeMode === "dark" ? Theme.textOnAccent : Theme.textPrimary
                                        }
                                        Text {
                                            text: "Dark"
                                            font.pixelSize: 12
                                            font.bold: settingsMgr.themeMode === "dark"
                                            color: settingsMgr.themeMode === "dark" ? Theme.textOnAccent : Theme.textPrimary
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: settingsMgr.themeMode = "dark"
                                    }
                                }

                                Rectangle {
                                    width: 90
                                    height: 32
                                    radius: Theme.radiusSm
                                    color: settingsMgr.themeMode === "light" ? Theme.accent : Theme.surfaceElevated
                                    border.color: Theme.border
                                    border.width: 1

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        LucideIcon {
                                            name: "sun"
                                            size: 13
                                            color: settingsMgr.themeMode === "light" ? Theme.textOnAccent : Theme.textPrimary
                                        }
                                        Text {
                                            text: "Light"
                                            font.pixelSize: 12
                                            font.bold: settingsMgr.themeMode === "light"
                                            color: settingsMgr.themeMode === "light" ? Theme.textOnAccent : Theme.textPrimary
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: settingsMgr.themeMode = "light"
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
                                    font.pixelSize: 13
                                    color: Theme.textPrimary
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: settingsMgr.readerFontSize + " px"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.accent
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

                // Reset Action
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: Theme.radiusMd
                    color: resetArea.containsMouse ? Theme.surfaceHover : Theme.surface
                    border.color: Theme.border
                    border.width: 1

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
                            font.pixelSize: 12
                            color: Theme.danger
                        }
                    }

                    MouseArea {
                        id: resetArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: settingsMgr.resetToDefaults()
                    }
                }
            }
        }
    }
}
