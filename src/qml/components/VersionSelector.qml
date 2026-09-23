import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Item {
    id: root

    property var versionsModel: []
    property string selectedVersion: "Latest Release"
    property string selectedText: "Latest Release"
    property bool isStableSelected: false
    property bool enabled: true

    signal versionSelected(string version, string text)

    implicitHeight: 28
    implicitWidth: 160

    // Main Closed Selector Box
    Rectangle {
        id: selectorBox
        anchors.fill: parent
        radius: Theme.radiusSm
        color: selectorMouseArea.containsMouse ? Theme.surfaceHover : Theme.surfaceElevated
        border.color: dropdownPopup.opened ? Theme.accent : Theme.border
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: root.selectedText ? root.selectedText : "Latest Release"
                font.pixelSize: 11
                color: Theme.textPrimary
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            // Green "Stable" badge in box if stable is selected
            Rectangle {
                visible: root.isStableSelected || root.selectedVersion === "Latest Stable" || root.selectedText === "Latest Stable"
                height: 16
                width: boxStableText.implicitWidth + 8
                radius: 2
                color: "#163824"
                border.color: "#22c55e"
                border.width: 1

                Text {
                    id: boxStableText
                    anchors.centerIn: parent
                    text: "Stable"
                    font.pixelSize: 8
                    font.bold: true
                    color: "#4ade80"
                }
            }

            LucideIcon {
                name: dropdownPopup.opened ? "chevron-up" : "chevron-down"
                size: 11
                color: Theme.textMuted
            }
        }

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

    // Floating Dropdown Popup
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

        background: Rectangle {
            radius: Theme.radiusMd
            color: Theme.surfaceElevated
            border.color: Theme.border
            border.width: 1

            // Drop shadow simulation
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                z: -1
                radius: Theme.radiusMd + 1
                color: "#20000000"
            }
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
                height: isDivider ? 9 : 30

                property bool isDivider: modelData && modelData.isDivider === true
                property bool isStable: modelData && modelData.isStable === true
                property string itemText: modelData && modelData.text !== undefined ? modelData.text : ""
                property string itemVersion: modelData && modelData.version !== undefined ? modelData.version : ""
                property bool isSelected: (root.selectedVersion === itemVersion) || (root.selectedText === itemText)

                // Divider Separator
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 8
                    height: 1
                    color: Theme.border
                    visible: parent.isDivider
                }

                // Clickable Item Row
                Rectangle {
                    anchors.fill: parent
                    visible: !parent.isDivider
                    radius: Theme.radiusSm
                    color: isSelected ? Theme.surfaceHover : (itemMouse.containsMouse ? Theme.surface : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: itemText
                            font.pixelSize: 11
                            font.bold: isSelected
                            color: isSelected ? Theme.accent : Theme.textPrimary
                            elide: Text.ElideRight
                        }

                        // Green "Stable" Tag
                        Rectangle {
                            visible: isStable
                            height: 18
                            width: stableLabel.implicitWidth + 8
                            radius: 3
                            color: "#163824"
                            border.color: "#22c55e"
                            border.width: 1

                            Text {
                                id: stableLabel
                                anchors.centerIn: parent
                                text: "Stable"
                                font.pixelSize: 9
                                font.bold: true
                                color: "#4ade80"
                            }
                        }

                        // Checkmark if selected
                        LucideIcon {
                            visible: isSelected
                            name: "check"
                            size: 12
                            color: Theme.accent
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
                            root.isStableSelected = isStable
                            root.versionSelected(itemVersion, itemText)
                            dropdownPopup.close()
                        }
                    }
                }
            }
        }
    }
}
