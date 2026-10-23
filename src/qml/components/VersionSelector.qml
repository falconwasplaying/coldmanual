import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Item {
    id: root

    property var versionsModel: []
    property string selectedVersion: "Latest Release"
    property string selectedText: "Latest Release"
    property bool isLtsSelected: false
    property bool isEolSelected: false
    property bool enabled: true

    signal versionSelected(string version, string text)

    implicitHeight: 30
    implicitWidth: 160

    // Main Closed Selector Box (M3 Outlined Box)
    Rectangle {
        id: selectorBox
        anchors.fill: parent
        radius: Theme.shapeSmall
        color: selectorMouseArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
        border.color: dropdownPopup.opened ? Theme.primary : Theme.outlineVariant
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: root.selectedText ? root.selectedText : "Latest Release"
                font.family: Theme.fontSans
                font.pixelSize: 11
                color: Theme.onSurface
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            // Green "LTS" badge in box if LTS is selected
            Rectangle {
                visible: root.isLtsSelected || root.selectedVersion === "Latest LTS" || root.selectedText === "Latest LTS"
                height: 16
                width: boxLtsText.implicitWidth + 8
                radius: Theme.shapeExtraSmall
                color: Theme.successBg

                Text {
                    id: boxLtsText
                    anchors.centerIn: parent
                    text: "LTS"
                    font.family: Theme.fontSans
                    font.pixelSize: 8
                    font.bold: true
                    color: Theme.success
                }
            }

            // Red "EOL" badge in box if EOL is selected
            Rectangle {
                visible: root.isEolSelected
                height: 16
                width: boxEolText.implicitWidth + 8
                radius: Theme.shapeExtraSmall
                color: Theme.dangerBg

                Text {
                    id: boxEolText
                    anchors.centerIn: parent
                    text: "EOL"
                    font.family: Theme.fontSans
                    font.pixelSize: 8
                    font.bold: true
                    color: Theme.danger
                }
            }

            LucideIcon {
                id: chevronIcon
                name: "chevron-down"
                size: 12
                color: Theme.onSurfaceVariant
                rotation: dropdownPopup.opened ? 180 : 0
                Behavior on rotation {
                    NumberAnimation { duration: Theme.animDurationNormal; easing.type: Theme.animEasingDecel }
                }
            }
        }

        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

        MouseArea {
            id: selectorMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: root.enabled
            onClicked: {
                if (dropdownPopup.opened) {
                    dropdownPopup.close()
                } else {
                    dropdownPopup.open()
                }
            }
        }
    }

    // Floating Dropdown Popup (M3 Menu)
    Popup {
        id: dropdownPopup
        y: root.height + 4
        x: 0
        width: Math.max(root.width, 220)
        height: Math.min(260, (versionsListView.contentHeight > 0 ? versionsListView.contentHeight + 14 : 120))
        padding: 6
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside | Popup.CloseOnPressOutsideParent

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: Theme.animDurationFast; easing.type: Easing.OutQuad }
            NumberAnimation { property: "scale"; from: 0.96; to: 1.0; duration: Theme.animDurationNormal; easing.type: Theme.animEasingDecel }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 100; easing.type: Easing.InQuad }
        }

        background: Rectangle {
            radius: Theme.shapeMedium
            color: Theme.surfaceContainerHigh
            border.color: Theme.outlineVariant
            border.width: 1
        }

        contentItem: ListView {
            id: versionsListView
            clip: true
            model: root.versionsModel
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                active: true
                width: 6
            }

            delegate: Item {
                width: versionsListView.width
                height: isDivider ? 9 : 32

                property bool isDivider: modelData && modelData.isDivider === true
                property bool isLts: modelData && modelData.isLts === true
                property bool isEol: modelData && modelData.isEol === true
                property string itemText: modelData && modelData.text !== undefined ? modelData.text : ""
                property string itemVersion: modelData && modelData.version !== undefined ? modelData.version : ""
                property bool isSelected: (root.selectedVersion === itemVersion) || (root.selectedText === itemText)

                // Divider Separator
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 8
                    height: 1
                    color: Theme.outlineVariant
                    visible: parent.isDivider
                }

                // Clickable Item Row
                Rectangle {
                    anchors.fill: parent
                    visible: !parent.isDivider
                    radius: Theme.shapeSmall
                    color: isSelected ? Theme.secondaryContainer : (itemMouse.containsMouse ? Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.08) : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: itemText
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            font.bold: isSelected
                            color: isSelected ? Theme.onSecondaryContainer : Theme.onSurface
                            elide: Text.ElideRight
                        }

                        // LTS Badge
                        Rectangle {
                            visible: isLts
                            height: 16
                            width: ltsLabel.implicitWidth + 8
                            radius: Theme.shapeExtraSmall
                            color: Theme.successBg

                            Text {
                                id: ltsLabel
                                anchors.centerIn: parent
                                text: "LTS"
                                font.family: Theme.fontSans
                                font.pixelSize: 8
                                font.bold: true
                                color: Theme.success
                            }
                        }

                        // EOL Badge
                        Rectangle {
                            visible: isEol
                            height: 16
                            width: eolLabel.implicitWidth + 8
                            radius: Theme.shapeExtraSmall
                            color: Theme.dangerBg

                            Text {
                                id: eolLabel
                                anchors.centerIn: parent
                                text: "EOL"
                                font.family: Theme.fontSans
                                font.pixelSize: 8
                                font.bold: true
                                color: Theme.danger
                            }
                        }

                        // Checkmark if selected
                        LucideIcon {
                            visible: isSelected
                            name: "check"
                            size: 13
                            color: Theme.onSecondaryContainer
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedVersion = itemVersion
                            root.selectedText = itemText
                            root.isLtsSelected = isLts
                            root.isEolSelected = isEol
                            root.versionSelected(itemVersion, itemText)
                            dropdownPopup.close()
                        }
                    }
                }
            }
        }
    }
}
