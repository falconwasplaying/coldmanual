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

    implicitWidth: Math.min(parent ? parent.width - 48 : 420, Math.max(340, contentRow.implicitWidth + 36))
    height: 54
    radius: Theme.radiusMd
    color: Theme.surfaceElevated
    border.color: Theme.border
    border.width: 1

    opacity: showing ? 1.0 : 0.0
    visible: opacity > 0.001

    Behavior on anchors.bottomMargin {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
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
            radius: 16
            color: Theme.accentDim
            LucideIcon {
                anchors.centerIn: parent
                name: root.iconName
                size: 16
                color: Theme.accent
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
                color: Theme.textPrimary
                visible: root.title.length > 0
            }

            Text {
                text: root.message
                font.family: Theme.fontSans
                font.pixelSize: 11
                color: Theme.textSecondary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // Close button
        Rectangle {
            width: 26
            height: 26
            radius: 13
            color: closeMouse.containsMouse ? Theme.surfaceHover : "transparent"
            LucideIcon {
                anchors.centerIn: parent
                name: "x"
                size: 13
                color: Theme.textMuted
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
