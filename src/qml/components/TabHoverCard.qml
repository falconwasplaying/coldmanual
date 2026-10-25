import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
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

    property bool isOpen: false
    property real blurAmount: 0.0
    property real contentOpacity: 1.0
    property real yOffset: 6.0
    property var pendingData: null

    width: 270
    height: cardCol.implicitHeight + 24
    radius: Theme.shapeMedium
    color: Theme.isDark ? Theme.surfaceContainerHighest : "#ffffff"
    border.color: Theme.outlineVariant
    border.width: 1

    opacity: 0.0
    visible: opacity > 0.001

    transform: Translate {
        y: root.yOffset
    }

    Behavior on height {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

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

    function open() {
        isOpen = true
        fadeAnim.stop()
        fadeAnim.toOpacity = 1.0
        fadeAnim.toYOffset = 0.0
        fadeAnim.start()
    }

    function close() {
        isOpen = false
        fadeAnim.stop()
        fadeAnim.toOpacity = 0.0
        fadeAnim.toYOffset = 4.0
        fadeAnim.start()
    }

    ParallelAnimation {
        id: fadeAnim
        property real toOpacity: 0.0
        property real toYOffset: 0.0

        NumberAnimation {
            target: root
            property: "opacity"
            to: fadeAnim.toOpacity
            duration: fadeAnim.toOpacity > 0 ? 180 : 150
            easing.type: fadeAnim.toOpacity > 0 ? Easing.OutCubic : Easing.InCubic
        }
        NumberAnimation {
            target: root
            property: "yOffset"
            to: fadeAnim.toYOffset
            duration: fadeAnim.toOpacity > 0 ? 180 : 150
            easing.type: fadeAnim.toOpacity > 0 ? Easing.OutCubic : Easing.InCubic
        }
    }

    function updateData(data, shouldAnimate) {
        if (!data) return
        if (!shouldAnimate) {
            blurTransitionAnim.stop()
            root.blurAmount = 0.0
            root.contentOpacity = 1.0
            applyData(data)
            return
        }

        pendingData = data
        blurTransitionAnim.restart()
    }

    function applyData(data) {
        if (!data) return
        root.docsetId = (data.docsetId !== undefined) ? data.docsetId : ""
        root.docsetName = (data.docsetName !== undefined) ? data.docsetName : ""
        root.title = (data.title !== undefined) ? data.title : ""
        root.previewSnippet = (data.previewSnippet !== undefined) ? data.previewSnippet : ""
        root.iconName = (data.iconName !== undefined) ? data.iconName : "file-text"
        root.ramUsage = (data.ramUsage !== undefined) ? data.ramUsage : ""
        root.showRam = (data.showRam !== undefined) ? data.showRam : true
    }

    SequentialAnimation {
        id: blurTransitionAnim

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "blurAmount"
                to: 0.8
                duration: 110
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "contentOpacity"
                to: 0.25
                duration: 110
                easing.type: Easing.OutQuad
            }
        }

        ScriptAction {
            script: {
                root.applyData(root.pendingData)
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "blurAmount"
                to: 0.0
                duration: 130
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "contentOpacity"
                to: 1.0
                duration: 130
                easing.type: Easing.OutQuad
            }
        }
    }

    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: 12
        opacity: root.contentOpacity

        layer.enabled: root.blurAmount > 0.01
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blurAmount
            blurMax: 20
        }

        ColumnLayout {
            id: cardCol
            anchors.fill: parent
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
                    Layout.preferredHeight: 18
                    Layout.preferredWidth: ramText.implicitWidth + 14
                    radius: Theme.shapeFull
                    color: Theme.secondaryContainer

                    Text {
                        id: ramText
                        anchors.centerIn: parent
                        text: root.ramUsage
                        font.family: Theme.fontSans
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textOnSecondaryContainer
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
}
