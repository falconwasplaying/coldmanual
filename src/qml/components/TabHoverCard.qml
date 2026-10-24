import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property string docsetId: ""
    property string docsetName: ""
    property string title: ""
    property string previewSnippet: ""
    property string iconName: "file-text"
    property string ramUsage: ""
    property bool showRam: true

    width: 270
    height: cardCol.implicitHeight + 20
    radius: Theme.shapeMedium
    color: Theme.isDark ? Theme.surfaceContainerHighest : "#ffffff"
    border.color: Theme.outlineVariant
    border.width: 1

    // Drop shadow simulation with subtle outer glow
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: parent.radius + 1
        color: "transparent"
        border.color: Theme.isDark ? "#40000000" : "#20000000"
        border.width: 1
        z: -1
    }

    ColumnLayout {
        id: cardCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // Header: Logo + Docset Name + RAM Badge
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            DocLogo {
                docId: root.docsetId
                size: 18
                showBackground: false
                visible: root.docsetId !== ""
            }

            LucideIcon {
                name: root.iconName ? root.iconName : "file-text"
                size: 14
                color: Theme.primary
                visible: root.docsetId === ""
            }

            Text {
                text: root.docsetName ? root.docsetName : "Documentation"
                font.family: Theme.fontSans
                font.pixelSize: 12
                font.bold: true
                color: Theme.textOnSurface
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // Real-time RAM Footprint Pill (Chrome Memory Saver Style)
            Rectangle {
                visible: root.showRam && root.ramUsage.length > 0
                Layout.preferredHeight: 20
                Layout.preferredWidth: ramText.implicitWidth + 14
                radius: Theme.shapeFull
                color: Theme.secondaryContainer

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    LucideIcon {
                        name: "cpu"
                        size: 10
                        color: Theme.textOnSecondaryContainer
                    }
                    Text {
                        id: ramText
                        text: root.ramUsage
                        font.family: Theme.fontSans
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textOnSecondaryContainer
                    }
                }
            }
        }

        // Title
        Text {
            Layout.fillWidth: true
            text: root.title ? root.title : "Untitled Document"
            font.family: Theme.fontSans
            font.pixelSize: 13
            font.bold: true
            color: Theme.textOnSurface
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        // Preview snippet / breadcrumb
        Text {
            Layout.fillWidth: true
            text: root.previewSnippet ? root.previewSnippet : "Offline cached documentation set"
            font.family: Theme.fontSans
            font.pixelSize: 11
            color: Theme.textOnSurfaceVariant
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.outlineVariant
        }

        // Footer Hint
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            LucideIcon {
                name: "mouse-pointer-click"
                size: 11
                color: Theme.textOnSurfaceVariant
            }

            Text {
                text: "Click tab to switch view"
                font.family: Theme.fontSans
                font.pixelSize: 10
                color: Theme.textOnSurfaceVariant
            }
        }
    }
}
