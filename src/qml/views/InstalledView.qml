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
                    color: Theme.onSurface
                }
                Text {
                    text: docsetMgr.installedCount + " libraries installed • " + docsetMgr.totalStorageUsage + " on disk"
                    font.family: Theme.fontSans
                    font.pixelSize: 13
                    color: Theme.onSurfaceVariant
                }
            }

            Item { Layout.fillWidth: true }

            // Material 3 Tonal Button: Check Updates
            Rectangle {
                width: checkText.implicitWidth + 36
                height: 38
                radius: Theme.shapeFull
                color: checkArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                border.color: Theme.outlineVariant
                border.width: 1
                scale: checkArea.pressed ? 0.96 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    LucideIcon {
                        name: "refresh-cw"
                        size: 14
                        color: Theme.primary
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
                        font.family: Theme.fontSans
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.onSurface
                    }
                }

                MouseArea {
                    id: checkArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: networkMgr.isOnline ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                    enabled: !docsetMgr.isCheckingUpdates
                    onClicked: {
                        if (!networkMgr.isOnline) {
                            window.showToast("Offline Mode", "Cannot check for updates while offline.", "wifi-off")
                            return
                        }
                        docsetMgr.checkForUpdates()
                    }
                }
            }

            // Material 3 Filled Button: Update All
            Rectangle {
                width: updateAllRow.implicitWidth + 28
                height: 38
                radius: Theme.shapeFull
                color: updateAllArea.containsMouse ? Theme.accentHover : Theme.primary
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
                        size: 14
                        color: Theme.onPrimary
                    }
                    Text {
                        text: "Update All"
                        font.family: Theme.fontSans
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.onPrimary
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
            color: Theme.outlineVariant
        }

        // Installed List
        ListView {
            id: installedList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: docsetMgr
            spacing: 12

            ScrollBar.vertical: ScrollBar {
                active: true
            }

            // Material 3 Outlined / Elevated Card Delegate
            delegate: Rectangle {
                id: cardItem
                width: installedList.width
                height: 88
                radius: Theme.shapeLarge
                color: cardArea.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow
                border.color: cardArea.containsMouse ? Theme.primary : Theme.outlineVariant
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
                                font.family: Theme.fontSans
                                font.pixelSize: 16
                                font.bold: true
                                color: Theme.onSurface
                            }

                            Rectangle {
                                height: 22
                                width: verText.implicitWidth + 12
                                radius: Theme.shapeSmall
                                color: Theme.surfaceContainerHighest

                                Text {
                                    id: verText
                                    anchors.centerIn: parent
                                    text: "v" + model.installedVersion
                                    font.family: Theme.fontSans
                                    font.pixelSize: 10
                                    color: Theme.onSurfaceVariant
                                }
                            }

                            Rectangle {
                                height: 22
                                width: sizeText.implicitWidth + 12
                                radius: Theme.shapeSmall
                                color: Theme.surfaceContainerHighest

                                Text {
                                    id: sizeText
                                    anchors.centerIn: parent
                                    text: model.sizeFormatted
                                    font.family: Theme.fontSans
                                    font.pixelSize: 10
                                    color: Theme.onSurfaceVariant
                                }
                            }

                            // Update Available Alert (M3 Warning Chip)
                            Rectangle {
                                visible: model.updateAvailable
                                height: 22
                                width: alertRow.implicitWidth + 14
                                radius: Theme.shapeSmall
                                color: Theme.warningBg
                                border.color: Theme.warning
                                border.width: 1

                                RowLayout {
                                    id: alertRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    LucideIcon {
                                        name: "zap"
                                        size: 11
                                        color: Theme.warning
                                    }
                                    Text {
                                        text: "v" + model.availableVersion + " Available"
                                        font.family: Theme.fontSans
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.warning
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Installed: " + model.installedAt + " • Last checked: " + model.lastChecked
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            color: Theme.onSurfaceVariant
                        }
                    }

                    // Auto-update latest toggle
                    RowLayout {
                        spacing: 8

                        Text {
                            text: "Auto-update latest"
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            color: model.trackLatest ? Theme.onSurface : Theme.onSurfaceVariant
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
                            width: updateRow.implicitWidth + 18
                            height: 34
                            radius: Theme.shapeFull
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
                                    size: 12
                                    color: updateNowArea.containsMouse ? "#000000" : Theme.warning
                                }
                                Text {
                                    text: "Update Now"
                                    font.family: Theme.fontSans
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

                        // Open Reader (M3 Filled Button)
                        Rectangle {
                            width: 124
                            height: 34
                            radius: Theme.shapeFull
                            color: readArea.containsMouse ? Theme.accentHover : Theme.primary
                            scale: readArea.pressed ? 0.95 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                LucideIcon {
                                    name: "book-open"
                                    size: 14
                                    color: Theme.onPrimary
                                }
                                Text {
                                    text: "Open Reader"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.onPrimary
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

                        // Delete (M3 Tonal Icon Button)
                        Rectangle {
                            width: 34
                            height: 34
                            radius: Theme.shapeFull
                            color: delArea.containsMouse ? Theme.errorContainer : Theme.surfaceContainerHighest
                            border.color: Theme.outlineVariant
                            border.width: 1
                            scale: delArea.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                            LucideIcon {
                                anchors.centerIn: parent
                                name: "trash-2"
                                size: 14
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
                        color: Theme.primary
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No documentation sets installed yet"
                        font.family: Theme.fontSans
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.onSurface
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Visit the Browse tab to download offline docs for languages and frameworks."
                        font.family: Theme.fontSans
                        font.pixelSize: 13
                        color: Theme.onSurfaceVariant
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 200
                        height: 40
                        radius: Theme.shapeFull
                        color: !networkMgr.isOnline ? Theme.surfaceContainerHigh : (browseBtnArea.containsMouse ? Theme.accentHover : Theme.primary)
                        border.color: !networkMgr.isOnline ? Theme.outlineVariant : "transparent"
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            LucideIcon {
                                visible: !networkMgr.isOnline
                                name: "wifi-off"
                                size: 14
                                color: Theme.onSurfaceVariant
                            }
                            Text {
                                text: networkMgr.isOnline ? "Browse Documentation" : "Browse (Offline)"
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                                font.bold: true
                                color: networkMgr.isOnline ? Theme.onPrimary : Theme.onSurfaceVariant
                            }
                        }

                        MouseArea {
                            id: browseBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: networkMgr.isOnline ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                            onClicked: root.navigateToCatalog()
                        }
                    }
                }
            }
        }
    }
}
