import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    signal openDocsetInReader(string docsetId, string docsetName)
    signal navigateToCatalog()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingMd

        // Header Row
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingMd

            ColumnLayout {
                spacing: 2
                Text {
                    text: "Installed Documentation"
                    font.family: Theme.fontSans
                    font.pixelSize: 22
                    font.bold: true
                    color: Theme.textPrimary
                }
                Text {
                    text: docsetMgr.installedCount + " libraries installed • " + docsetMgr.totalStorageUsage + " on disk"
                    font.pixelSize: 13
                    color: Theme.textMuted
                }
            }

            Item { Layout.fillWidth: true }

            // Check Updates Button
            Rectangle {
                width: checkText.implicitWidth + 34
                height: 36
                radius: Theme.radiusMd
                color: checkArea.containsMouse ? Theme.surfaceHover : Theme.surface
                border.color: Theme.border
                border.width: 1
                scale: checkArea.pressed ? 0.96 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    LucideIcon {
                        name: "refresh-cw"
                        size: 13
                        color: Theme.textPrimary
                        rotation: 0

                        RotationAnimation on rotation {
                            running: docsetMgr.isCheckingUpdates
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 800
                        }
                    }
                    Text {
                        id: checkText
                        text: docsetMgr.isCheckingUpdates ? "Checking..." : "Check for Updates"
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.textPrimary
                    }
                }

                MouseArea {
                    id: checkArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !docsetMgr.isCheckingUpdates
                    onClicked: docsetMgr.checkForUpdates()
                }
            }

            // Update All Button
            Rectangle {
                width: updateAllRow.implicitWidth + 24
                height: 36
                radius: Theme.radiusMd
                color: updateAllArea.containsMouse ? Theme.accentHover : Theme.accent
                visible: docsetMgr.installedCount > 0
                scale: updateAllArea.pressed ? 0.96 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                RowLayout {
                    id: updateAllRow
                    anchors.centerIn: parent
                    spacing: 6
                    LucideIcon {
                        name: "download"
                        size: 13
                        color: Theme.textOnAccent
                    }
                    Text {
                        text: "Update All"
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.textOnAccent
                    }
                }

                MouseArea {
                    id: updateAllArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: docsetMgr.updateAll()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
        }

        // Installed List
        ListView {
            id: installedList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: docsetMgr
            spacing: 10

            ScrollBar.vertical: ScrollBar {
                active: true
            }

            delegate: Rectangle {
                id: cardItem
                width: installedList.width
                height: 84
                radius: Theme.radiusMd
                color: cardArea.containsMouse ? Theme.surfaceHover : Theme.surface
                border.color: cardArea.containsMouse ? Theme.accent : Theme.border
                border.width: 1
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

                MouseArea {
                    id: cardArea
                    anchors.fill: parent
                    hoverEnabled: true
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 16

                    // Official Logo Badge
                    DocLogo {
                        docId: model.id
                        logoSource: model.logoPath || ""
                        size: 44
                    }

                    // Info Column
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            spacing: 8
                            Text {
                                text: model.name
                                font.pixelSize: 16
                                font.bold: true
                                color: Theme.textPrimary
                            }

                            Rectangle {
                                height: 20
                                width: verText.implicitWidth + 10
                                radius: Theme.radiusSm
                                color: Theme.surfaceElevated

                                Text {
                                    id: verText
                                    anchors.centerIn: parent
                                    text: "v" + model.installedVersion
                                    font.pixelSize: 10
                                    color: Theme.textSecondary
                                }
                            }

                            Rectangle {
                                height: 20
                                width: sizeText.implicitWidth + 10
                                radius: Theme.radiusSm
                                color: Theme.surfaceElevated

                                Text {
                                    id: sizeText
                                    anchors.centerIn: parent
                                    text: model.sizeFormatted
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                }
                            }

                            // Update Available Alert
                            Rectangle {
                                visible: model.updateAvailable
                                height: 20
                                width: alertRow.implicitWidth + 14
                                radius: Theme.radiusSm
                                color: Theme.warningBg
                                border.color: Theme.warning
                                border.width: 1

                                RowLayout {
                                    id: alertRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    LucideIcon {
                                        name: "zap"
                                        size: 10
                                        color: Theme.warning
                                    }
                                    Text {
                                        text: "v" + model.availableVersion + " Available"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.warning
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Installed: " + model.installedAt + " • Last checked: " + model.lastChecked
                            font.pixelSize: 11
                            color: Theme.textMuted
                        }
                    }

                    // Auto-update latest toggle
                    RowLayout {
                        spacing: 8

                        Text {
                            text: "Auto-update latest"
                            font.pixelSize: 12
                            color: model.trackLatest ? Theme.textPrimary : Theme.textMuted
                        }

                        Switch {
                            checked: model.trackLatest
                            onToggled: {
                                docsetMgr.setTrackLatest(model.id, checked)
                            }
                        }
                    }

                    // Action buttons
                    RowLayout {
                        spacing: 8

                        // Update Now Button (if update available)
                        Rectangle {
                            visible: model.updateAvailable
                            width: updateRow.implicitWidth + 16
                            height: 32
                            radius: Theme.radiusSm
                            color: updateNowArea.containsMouse ? Theme.warning : Theme.warningBg
                            border.color: Theme.warning
                            border.width: 1
                            scale: updateNowArea.pressed ? 0.95 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                            RowLayout {
                                id: updateRow
                                anchors.centerIn: parent
                                spacing: 4
                                LucideIcon {
                                    name: "download"
                                    size: 11
                                    color: updateNowArea.containsMouse ? "#000000" : Theme.warning
                                }
                                Text {
                                    text: "Update Now"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: updateNowArea.containsMouse ? "#000000" : Theme.warning
                                }
                            }

                            MouseArea {
                                id: updateNowArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: docsetMgr.updateDocset(model.id)
                            }
                        }

                        // Open Reader
                        Rectangle {
                            width: 116
                            height: 32
                            radius: Theme.radiusSm
                            color: readArea.containsMouse ? Theme.accentHover : Theme.accent
                            scale: readArea.pressed ? 0.95 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                LucideIcon {
                                    name: "book-open"
                                    size: 13
                                    color: Theme.textOnAccent
                                }
                                Text {
                                    text: "Open Reader"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.textOnAccent
                                }
                            }

                            MouseArea {
                                id: readArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openDocsetInReader(model.id, model.name)
                            }
                        }

                        // Delete
                        Rectangle {
                            width: 32
                            height: 32
                            radius: Theme.radiusSm
                            color: delArea.containsMouse ? Theme.dangerBg : Theme.surfaceElevated
                            border.color: Theme.border
                            border.width: 1
                            scale: delArea.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                            LucideIcon {
                                anchors.centerIn: parent
                                name: "trash-2"
                                size: 13
                                color: Theme.danger
                            }

                            MouseArea {
                                id: delArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: docsetMgr.removeDocset(model.id)
                            }
                        }
                    }
                }
            }

            // Empty state
            Item {
                anchors.centerIn: parent
                visible: installedList.count === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    LucideIcon {
                        Layout.alignment: Qt.AlignHCenter
                        name: "library"
                        size: 48
                        color: Theme.accent
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No documentation sets installed yet"
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Visit the Browse tab to download offline docs for languages and frameworks."
                        font.pixelSize: 13
                        color: Theme.textMuted
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 180
                        height: 36
                        radius: Theme.radiusMd
                        color: browseBtnArea.containsMouse ? Theme.accentHover : Theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: "Browse Documentation"
                            font.pixelSize: 13
                            font.bold: true
                            color: Theme.textOnAccent
                        }

                        MouseArea {
                            id: browseBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.navigateToCatalog()
                        }
                    }
                }
            }
        }
    }
}
