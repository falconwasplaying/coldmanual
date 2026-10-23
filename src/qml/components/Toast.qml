import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property string title: ""
    property string message: ""
    property string iconName: "wifi-off"
    property int duration: 4000
    property bool showing: false

    function show(t, m, icon, dur) {
        title = t || ""
        message = m || ""
        iconName = icon || "wifi-off"
        duration = dur || 4000
        showing = true
        dismissTimer.restart()
    }

    function dismiss() {
        showing = false
        dismissTimer.stop()
    }

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: showing ? 24 : -80
    z: 999999

    implicitWidth: Math.min(parent ? parent.width - 48 : 440, Math.max(340, contentRow.implicitWidth + 36))
    height: 56
    radius: Theme.shapeSmall
    color: Theme.inverseSurface
    border.color: Theme.outlineVariant
    border.width: 1

    opacity: showing ? 1.0 : 0.0
    visible: opacity > 0.001

    Behavior on anchors.bottomMargin {
        NumberAnimation { duration: Theme.animDurationNormal; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: Theme.animDurationNormal; easing.type: Easing.OutQuad }
    }

    Timer {
        id: dismissTimer
        interval: root.duration
        onTriggered: root.dismiss()
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: dismissTimer.stop()
        onExited: if (root.showing) dismissTimer.restart()
    }

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        spacing: 12

        Rectangle {
            width: 32
            height: 32
            radius: Theme.shapeFull
            color: Theme.primaryContainer
            LucideIcon {
                anchors.centerIn: parent
                name: root.iconName
                size: 16
                color: Theme.onPrimaryContainer
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: root.title
                font.family: Theme.fontSans
                font.pixelSize: 13
                font.bold: true
                color: Theme.inverseOnSurface
                visible: root.title.length > 0
            }

            Text {
                text: root.message
                font.family: Theme.fontSans
                font.pixelSize: 12
                color: Theme.inverseOnSurface
                opacity: 0.85
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // Close button
        Rectangle {
            width: 28
            height: 28
            radius: Theme.shapeFull
            color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            LucideIcon {
                anchors.centerIn: parent
                name: "x"
                size: 14
                color: Theme.inverseOnSurface
            }
            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.dismiss()
            }
        }
    }
}
