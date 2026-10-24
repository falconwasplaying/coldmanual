import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property var tabsModel: null
    property int activeTabIndex: 0
    readonly property bool isMaximized: (typeof framelessHelper !== "undefined" && framelessHelper) ? framelessHelper.isMaximized : false

    signal selectTabRequested(int index)
    signal closeTabRequested(int index)
    signal newTabRequested()

    height: 40
    color: Theme.surfaceContainerLow

    // Bottom border dividing titlebar from content
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.outlineVariant
        z: 10
    }

    RowLayout {
        id: titleBarRow
        anchors.fill: parent
        spacing: 0

        // App Logo & Branding (Left)
        Item {
            Layout.preferredWidth: 44
            Layout.fillHeight: true

            Image {
                anchors.centerIn: parent
                source: "qrc:/resources/cmi.svg"
                sourceSize.width: 20
                sourceSize.height: 20
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onDoubleClicked: {
                    if (typeof framelessHelper !== "undefined" && framelessHelper) {
                        framelessHelper.toggleMaximize()
                    }
                }
                onPressed: {
                    if (typeof window !== "undefined" && window.startSystemMove) {
                        window.startSystemMove()
                    }
                }
            }
        }

        // Tabs Strip & New Tab Button
        Item {
            id: tabsContainer
            Layout.fillHeight: true
            Layout.preferredWidth: Math.min(root.width - 200, tabsRow.implicitWidth + 36)
            clip: true

            Row {
                id: tabsRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: root.tabsModel

                    delegate: Item {
                        id: tabItem
                        width: Math.max(110, Math.min(200, (tabsContainer.width - 44) / Math.max(1, (root.tabsModel ? root.tabsModel.count : 1))))
                        height: 32

                        property bool isActive: index === root.activeTabIndex
                        property bool isHovered: tabMouseArea.containsMouse
                        property bool showCloseButton: {
                            var mode = settingsMgr.tabCloseButtonMode
                            if (mode === "always") return true
                            if (mode === "never") return false
                            return isHovered || isActive
                        }
                        property bool showRamOnTab: {
                            var mode = settingsMgr.tabRamUsageMode
                            return mode === "tab" || mode === "both"
                        }

                        // Tab Pill / Container
                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: tabItem.isActive ? Theme.surface :
                                   (tabItem.isHovered ? Theme.surfaceContainerHigh : "transparent")
                            border.color: tabItem.isActive ? Theme.outlineVariant : "transparent"
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 6
                                spacing: 6

                                // Doc Logo / Icon
                                DocLogo {
                                    docId: (model.pageType === "reader" || !model.pageType) && model.docsetId ? model.docsetId : ""
                                    size: 16
                                    showBackground: false
                                    visible: (model.pageType === "reader" || !model.pageType) && model.docsetId && model.docsetId !== ""
                                }

                                LucideIcon {
                                    name: {
                                        if (model.pageType === "catalog") return "compass"
                                        if (model.pageType === "installed") return "download"
                                        if (model.pageType === "settings") return "settings"
                                        if (model.icon && model.icon.length > 0) return model.icon
                                        return "file-text"
                                    }
                                    size: 13
                                    color: tabItem.isActive ? Theme.primary : Theme.textOnSurfaceVariant
                                    visible: !((model.pageType === "reader" || !model.pageType) && model.docsetId && model.docsetId !== "")
                                }

                                // Document Title
                                Text {
                                    Layout.fillWidth: true
                                    text: model.title ? model.title : "New Tab"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 12
                                    font.bold: tabItem.isActive
                                    color: tabItem.isActive ? Theme.textOnSurface : Theme.textOnSurfaceVariant
                                    elide: Text.ElideRight
                                }

                                // Tab RAM Footprint Badge
                                Rectangle {
                                    visible: tabItem.showRamOnTab && (typeof settingsMgr !== "undefined" && settingsMgr.processMemoryUsage.length > 0)
                                    Layout.preferredHeight: 16
                                    Layout.preferredWidth: tabRamText.implicitWidth + 8
                                    radius: Theme.shapeFull
                                    color: Theme.secondaryContainer

                                    Text {
                                        id: tabRamText
                                        anchors.centerIn: parent
                                        text: (typeof settingsMgr !== "undefined") ? settingsMgr.processMemoryUsage : ""
                                        font.family: Theme.fontSans
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: Theme.textOnSecondaryContainer
                                    }
                                }

                                // Close Button (X)
                                Rectangle {
                                    id: closeBtn
                                    visible: tabItem.showCloseButton
                                    Layout.preferredWidth: 18
                                    Layout.preferredHeight: 18
                                    radius: Theme.shapeFull
                                    color: closeBtnMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                                    LucideIcon {
                                        anchors.centerIn: parent
                                        name: "x"
                                        size: 10
                                        color: closeBtnMouse.containsMouse ? Theme.danger : Theme.textOnSurfaceVariant
                                    }

                                    MouseArea {
                                        id: closeBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.closeTabRequested(index)
                                    }
                                }
                            }
                        }

                        // Tab Selection & Middle Click Mouse Area
                        MouseArea {
                            id: tabMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            z: -1

                            onClicked: function(mouse) {
                                if (mouse.button === Qt.MiddleButton) {
                                    root.closeTabRequested(index)
                                } else {
                                    root.selectTabRequested(index)
                                }
                            }

                            onEntered: {
                                if (settingsMgr.tabHoverPreviewEnabled) {
                                    hoverCardTimer.targetIndex = index
                                    hoverCardTimer.targetX = tabItem.mapToItem(root, 0, 0).x
                                    hoverCardTimer.restart()
                                }
                            }

                            onExited: {
                                hoverCardTimer.stop()
                                if (!hoverCardArea.containsMouse) {
                                    tabHoverCard.visible = false
                                }
                            }
                        }
                    }
                }

                // New Tab (+) Button
                Rectangle {
                    width: 28
                    height: 28
                    anchors.verticalCenter: parent.verticalCenter
                    radius: Theme.shapeFull
                    color: newTabMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                    LucideIcon {
                        anchors.centerIn: parent
                        name: "plus"
                        size: 14
                        color: newTabMouse.containsMouse ? Theme.primary : Theme.textOnSurfaceVariant
                    }

                    MouseArea {
                        id: newTabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.newTabRequested()
                    }

                    ToolTip.visible: newTabMouse.containsMouse
                    ToolTip.delay: 400
                    ToolTip.text: "New Tab (Ctrl+T)"
                }
            }

            onWidthChanged: updateFramelessHitTest()
        }

        // Draggable Empty Space (Takes all remaining width)
        Item {
            id: dragSpacer
            Layout.fillWidth: true
            Layout.fillHeight: true

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onDoubleClicked: {
                    if (typeof framelessHelper !== "undefined" && framelessHelper) {
                        framelessHelper.toggleMaximize()
                    }
                }
                onPressed: {
                    if (typeof window !== "undefined" && window.startSystemMove) {
                        window.startSystemMove()
                    }
                }
            }
        }

        // Window Controls (Right: Minimize, Maximize/Restore, Close)
        Row {
            id: windowControls
            Layout.preferredWidth: 138
            Layout.fillHeight: true
            spacing: 0

            // Minimize
            Rectangle {
                width: 46
                height: 40
                color: minMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                LucideIcon {
                    anchors.centerIn: parent
                    name: "minus"
                    size: 11
                    color: Theme.textOnSurface
                }

                MouseArea {
                    id: minMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof framelessHelper !== "undefined" && framelessHelper) {
                            framelessHelper.showMinimized()
                        } else if (typeof window !== "undefined" && window.showMinimized) {
                            window.showMinimized()
                        }
                    }
                }
            }

            // Maximize / Restore
            Rectangle {
                width: 46
                height: 40
                color: maxMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                LucideIcon {
                    anchors.centerIn: parent
                    name: root.isMaximized ? "copy" : "square"
                    size: 11
                    color: Theme.textOnSurface
                }

                MouseArea {
                    id: maxMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof framelessHelper !== "undefined" && framelessHelper) {
                            framelessHelper.toggleMaximize()
                        } else if (typeof window !== "undefined") {
                            if (window.visibility === Window.Maximized) window.showNormal()
                            else window.showMaximized()
                        }
                    }
                }
            }

            // Close (Windows & Material 3 Red on hover)
            Rectangle {
                width: 46
                height: 40
                color: closeWinMouse.containsMouse ? "#e81123" : "transparent"

                LucideIcon {
                    anchors.centerIn: parent
                    name: "x"
                    size: 12
                    color: closeWinMouse.containsMouse ? "#ffffff" : Theme.textOnSurface
                }

                MouseArea {
                    id: closeWinMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof framelessHelper !== "undefined" && framelessHelper) {
                            framelessHelper.close()
                        } else if (typeof window !== "undefined" && window.close) {
                            window.close()
                        }
                    }
                }
            }
        }
    }

    // Hover Card Timer & Popup
    Timer {
        id: hoverCardTimer
        interval: 350
        repeat: false
        property int targetIndex: -1
        property real targetX: 0

        onTriggered: {
            if (targetIndex >= 0 && root.tabsModel && targetIndex < root.tabsModel.count) {
                var item = root.tabsModel.get(targetIndex)
                var isReader = (item.pageType === "reader" || !item.pageType)
                tabHoverCard.docsetId = (isReader && item.docsetId) ? item.docsetId : ""
                tabHoverCard.docsetName = item.docsetName ? item.docsetName : (item.pageType ? item.pageType.toUpperCase() : "COLDMANUAL")
                tabHoverCard.title = item.title ? item.title : "ColdManual"
                tabHoverCard.previewSnippet = item.previewSnippet ? item.previewSnippet : ""
                tabHoverCard.iconName = (item.pageType === "catalog") ? "compass" :
                                        (item.pageType === "installed") ? "download" :
                                        (item.pageType === "settings") ? "settings" :
                                        (item.icon ? item.icon : "file-text")
                tabHoverCard.ramUsage = (typeof settingsMgr !== "undefined") ? settingsMgr.processMemoryUsage : ""
                tabHoverCard.showRam = (typeof settingsMgr !== "undefined") && (settingsMgr.tabRamUsageMode === "preview" || settingsMgr.tabRamUsageMode === "both")
                
                // Position card safely within window bounds
                var cardX = Math.max(10, Math.min(root.width - tabHoverCard.width - 10, targetX))
                tabHoverCard.x = cardX
                tabHoverCard.visible = true
            }
        }
    }

    TabHoverCard {
        id: tabHoverCard
        y: root.height + 4
        z: 999999
        visible: false

        MouseArea {
            id: hoverCardArea
            anchors.fill: parent
            hoverEnabled: true
            onExited: tabHoverCard.visible = false
        }
    }

    function updateFramelessHitTest() {
        if (typeof framelessHelper !== "undefined" && framelessHelper) {
            var tabsStart = 44.0
            var tabsEnd = tabsStart + (tabsRow ? tabsRow.implicitWidth + 36 : 200.0)
            framelessHelper.updateTabsWidth(tabsStart, tabsEnd)
        }
    }

    Component.onCompleted: {
        updateFramelessHitTest()
    }
}
