import QtQuick
import ".."

Item {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 46
    implicitHeight: 26

    // Track Capsule
    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.primary : (mouseArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
        border.color: root.checked ? Theme.primary : (mouseArea.containsMouse ? Theme.outline : Theme.outlineVariant)
        border.width: 1.5

        Behavior on color {
            ColorAnimation { duration: Theme.animDurationFast }
        }
        Behavior on border.color {
            ColorAnimation { duration: Theme.animDurationFast }
        }

        // Animated Knob
        Rectangle {
            id: knob
            width: parent.height - 8
            height: width
            radius: height / 2
            y: 4
            x: root.checked ? (parent.width - width - 4) : 4
            color: "#ffffff"
            border.color: root.checked ? Theme.primary : (Theme.isDark ? "#3e424a" : "#c2c7cf")
            border.width: 0.5

            scale: mouseArea.pressed ? 0.92 : (mouseArea.containsMouse ? 1.05 : 1.0)

            Behavior on x {
                NumberAnimation {
                    duration: Theme.animDurationFast + 40
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation { duration: Theme.animDurationFast }
            }
            Behavior on border.color {
                ColorAnimation { duration: Theme.animDurationFast }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked
            root.toggled(root.checked)
        }
    }
}
