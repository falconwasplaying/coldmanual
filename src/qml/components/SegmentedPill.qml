import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root

    property var options: []
    property string currentValue: ""
    signal valueSelected(string value)

    implicitHeight: 36
    implicitWidth: 360

    readonly property int selectedIndex: {
        if (!options || options.length === 0) return 0
        for (var i = 0; i < options.length; ++i) {
            if (options[i].id === currentValue) {
                return i
            }
        }
        return 0
    }

    readonly property real itemWidth: (width - 8) / Math.max(1, (options ? options.length : 1))
    property bool animationsReady: false

    Component.onCompleted: {
        animationsReady = true
    }

    // Outer Capsule Container
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceContainerHigh
        border.color: Theme.outlineVariant
        border.width: 1

        // Animated Sliding Indicator Pill
        Rectangle {
            id: indicator
            x: 4 + root.selectedIndex * root.itemWidth
            y: 4
            width: root.itemWidth
            height: parent.height - 8
            radius: height / 2
            color: Theme.secondaryContainer

            Behavior on x {
                enabled: root.animationsReady
                NumberAnimation {
                    duration: Theme.animDurationNormal
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Option Segments
        Row {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 0

            Repeater {
                model: root.options

                Item {
                    id: optionItem
                    width: root.itemWidth
                    height: parent.height

                    readonly property bool isSelected: root.selectedIndex === index

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: (modelData.icon && modelData.icon.length > 0) ? 6 : 0

                        LucideIcon {
                            name: modelData.icon ? modelData.icon : ""
                            size: 13
                            visible: modelData.icon !== undefined && modelData.icon !== ""
                            Layout.preferredWidth: visible ? 13 : 0
                            Layout.preferredHeight: visible ? 13 : 0
                            color: optionItem.isSelected ? Theme.textOnSecondaryContainer : (mouseArea.containsMouse ? Theme.textOnSurface : Theme.textOnSurfaceVariant)
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        }

                        Text {
                            text: modelData.label
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            font.bold: optionItem.isSelected
                            color: optionItem.isSelected ? Theme.textOnSecondaryContainer : (mouseArea.containsMouse ? Theme.textOnSurface : Theme.textOnSurfaceVariant)
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.currentValue !== modelData.id) {
                                root.valueSelected(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
