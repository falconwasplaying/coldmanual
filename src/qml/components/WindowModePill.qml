import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root

    implicitWidth: 360
    implicitHeight: 38

    readonly property var modes: [
        { id: "windowed", label: "Windowed", icon: "app-window" },
        { id: "borderless", label: "Borderless", icon: "layout" },
        { id: "fullscreen", label: "Fullscreen", icon: "maximize" }
    ]

    readonly property int selectedIndex: {
        var m = settingsMgr.windowDisplayMode
        if (m === "borderless") return 1
        if (m === "fullscreen") return 2
        return 0 // "windowed"
    }

    property real itemWidth: (width - 8) / 3
    property bool animationsReady: false

    Component.onCompleted: {
        animationsReady = true
    }

    // Outer Pill Container
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceElevated
        border.color: Theme.border
        border.width: 1

        // Sliding Indicator Pill
        Rectangle {
            id: indicator
            x: 4 + root.selectedIndex * root.itemWidth
            y: 4
            width: root.itemWidth
            height: parent.height - 8
            radius: height / 2
            color: Theme.accent

            Behavior on x {
                enabled: root.animationsReady
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Three Interactive Option Segments
        Row {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 0

            Repeater {
                model: root.modes

                Item {
                    id: optionItem
                    width: root.itemWidth
                    height: parent.height

                    readonly property bool isSelected: root.selectedIndex === index

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        LucideIcon {
                            name: modelData.icon
                            size: 13
                            color: optionItem.isSelected ? Theme.textOnAccent : (mouseArea.containsMouse ? Theme.textPrimary : Theme.textMuted)
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        }

                        Text {
                            text: modelData.label
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            font.bold: optionItem.isSelected
                            color: optionItem.isSelected ? Theme.textOnAccent : (mouseArea.containsMouse ? Theme.textPrimary : Theme.textMuted)
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (settingsMgr.windowDisplayMode !== modelData.id) {
                                settingsMgr.windowDisplayMode = modelData.id
                            }
                        }
                    }
                }
            }
        }
    }
}
