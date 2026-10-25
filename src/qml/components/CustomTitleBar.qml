import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: root
    z: 1000

    property var tabsModel: null
    property int activeTabIndex: 0
    readonly property bool isMaximized: (typeof framelessHelper !== "undefined" && framelessHelper) ? framelessHelper.isMaximized : false

    signal selectTabRequested(int index)
    signal closeTabRequested(int index)
    signal newTabRequested()

    property int currentHoverIndex: -1

    function closeHoverCard() {
        hoverCardTimer.stop()
        hoverGraceTimer.stop()
        root.currentHoverIndex = -1
        tabHoverCard.close()
    }

    onCloseTabRequested: {
        root.closeHoverCard()
    }

    readonly property string currentRamUsage: (typeof settingsMgr !== "undefined" && settingsMgr) ? settingsMgr.processMemoryUsage : ""

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
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                onEntered: {
                    if (tabHoverCard.isOpen) {
                        root.closeHoverCard()
                    }
                }
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
                        property bool isHovered: tabMouseArea.containsMouse || closeBtnMouse.containsMouse
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

                        // Tab Hover Pill (fades opacity of constant color - prevents black interpolation glitch)
                        Rectangle {
                            id: tabHoverPill
                            anchors.fill: parent
                            radius: 8
                            color: Theme.surfaceContainerHigh
                            opacity: (!tabItem.isActive && tabItem.isHovered) ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                        }

                        // Active Tab Pill
                        Rectangle {
                            id: tabActivePill
                            anchors.fill: parent
                            radius: 8
                            color: Theme.surface
                            border.color: Theme.outlineVariant
                            border.width: 1
                            opacity: tabItem.isActive ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                        }

                        // Tab Content
                        Item {
                            anchors.fill: parent

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
                                    visible: tabItem.showRamOnTab && tabRamText.text.length > 0
                                    Layout.preferredHeight: 16
                                    Layout.preferredWidth: tabRamText.implicitWidth + 8
                                    radius: Theme.shapeFull
                                    color: Theme.secondaryContainer

                                    Text {
                                        id: tabRamText
                                        anchors.centerIn: parent
                                        text: {
                                            if (typeof model.ramUsage !== "undefined" && model.ramUsage.length > 0) {
                                                return model.ramUsage
                                            }
                                            if (typeof settingsMgr !== "undefined" && settingsMgr.getTabMemoryUsage) {
                                                var tId = (typeof model.tabId !== "undefined") ? model.tabId : ""
                                                var u = settingsMgr.getTabMemoryUsage(tId)
                                                if (u.length > 0) return u
                                                return settingsMgr.calculateTabMemoryUsage(model.pageType, model.filePath, 50)
                                            }
                                            return "5.0 MB"
                                        }
                                        font.family: Theme.fontSans
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: Theme.textOnSecondaryContainer
                                    }
                                }

                                // Close Button (X)
                                Item {
                                    id: closeBtn
                                    visible: tabItem.showCloseButton
                                    Layout.preferredWidth: 18
                                    Layout.preferredHeight: 18

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Theme.shapeFull
                                        color: Theme.surfaceContainerHighest
                                        opacity: closeBtnMouse.containsMouse ? 1.0 : 0.0
                                        Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                                    }

                                    LucideIcon {
                                        anchors.centerIn: parent
                                        name: "x"
                                        size: 10
                                        color: closeBtnMouse.containsMouse ? Theme.danger : Theme.textOnSurfaceVariant
                                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                    }

                                    MouseArea {
                                        id: closeBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.closeTabRequested(index)
                                        onEntered: {
                                            hoverGraceTimer.stop()
                                            if (settingsMgr.tabHoverPreviewEnabled) {
                                                var tX = tabItem.mapToItem(root, 0, 0).x
                                                if (tabHoverCard.isOpen) {
                                                    if (root.currentHoverIndex !== index) {
                                                        hoverCardTimer.stop()
                                                        root.showHoverCardForTab(index, tX, true)
                                                    }
                                                } else {
                                                    if (!hoverCardTimer.running || hoverCardTimer.targetIndex !== index) {
                                                        hoverCardTimer.targetIndex = index
                                                        hoverCardTimer.targetX = tX
                                                        hoverCardTimer.restart()
                                                    }
                                                }
                                            }
                                        }
                                        onExited: {
                                            if (tabMouseArea.containsMouse) return
                                            var tabPt = tabItem.mapFromItem(closeBtn, closeBtnMouse.mouseX, closeBtnMouse.mouseY)
                                            if (tabPt.x >= 0 && tabPt.x <= tabItem.width && tabPt.y >= 0 && tabPt.y <= tabItem.height) {
                                                return
                                            }
                                            hoverCardTimer.stop()
                                            if (tabHoverCard.isOpen && !hoverCardArea.containsMouse) {
                                                hoverGraceTimer.restart()
                                                if (cursorZoneTimer.running) {
                                                    cursorZoneTimer.triggered()
                                                }
                                            }
                                        }
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
                                    var tX = tabItem.mapToItem(root, 0, 0).x
                                    hoverGraceTimer.stop()
                                    if (tabHoverCard.isOpen) {
                                        if (root.currentHoverIndex !== index) {
                                            hoverCardTimer.stop()
                                            root.showHoverCardForTab(index, tX, true)
                                        }
                                    } else {
                                        if (!hoverCardTimer.running || hoverCardTimer.targetIndex !== index) {
                                            hoverCardTimer.targetIndex = index
                                            hoverCardTimer.targetX = tX
                                            hoverCardTimer.restart()
                                        }
                                    }
                                }
                            }

                            onExited: {
                                if (closeBtnMouse.containsMouse) return
                                if (tabMouseArea.mouseX >= 0 && tabMouseArea.mouseX <= tabItem.width &&
                                    tabMouseArea.mouseY >= 0 && tabMouseArea.mouseY <= tabItem.height) {
                                    return
                                }
                                hoverCardTimer.stop()
                                if (tabHoverCard.isOpen && !hoverCardArea.containsMouse) {
                                    hoverGraceTimer.restart()
                                    if (cursorZoneTimer.running) {
                                        cursorZoneTimer.triggered()
                                    }
                                }
                            }
                        }
                    }
                }

                // New Tab (+) Button
                Item {
                    width: 28
                    height: 28
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.shapeFull
                        color: Theme.surfaceContainerHighest
                        opacity: newTabMouse.containsMouse ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                    }

                    LucideIcon {
                        anchors.centerIn: parent
                        name: "plus"
                        size: 14
                        color: newTabMouse.containsMouse ? Theme.primary : Theme.textOnSurfaceVariant
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
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
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                onEntered: {
                    if (tabHoverCard.isOpen) {
                        root.closeHoverCard()
                    }
                }
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
                    strokeWidth: 1.8
                    color: Theme.textOnSurface
                }

                ToolTip.visible: minMouse.containsMouse
                ToolTip.delay: 800
                ToolTip.text: "Minimize"

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
                    name: root.isMaximized ? "window-restore" : "square"
                    size: 11
                    strokeWidth: 1.8
                    color: Theme.textOnSurface
                }

                ToolTip.visible: maxMouse.containsMouse
                ToolTip.delay: 800
                ToolTip.text: root.isMaximized ? "Restore Down" : "Maximize"

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
                    size: 11
                    strokeWidth: 1.8
                    color: closeWinMouse.containsMouse ? "#ffffff" : Theme.textOnSurface
                }

                ToolTip.visible: closeWinMouse.containsMouse
                ToolTip.delay: 800
                ToolTip.text: "Close"

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

    function getHoverCardData(targetIndex) {
        if (targetIndex >= 0 && root.tabsModel && targetIndex < root.tabsModel.count) {
            var item = root.tabsModel.get(targetIndex)
            var isReader = (item.pageType === "reader" || !item.pageType)
            var docId = (isReader && item.docsetId) ? item.docsetId : ""
            var docName = item.docsetName ? item.docsetName : (item.pageType ? item.pageType.toUpperCase() : "COLDMANUAL")
            var title = item.title ? item.title : "ColdManual"
            var snippet = item.previewSnippet ? item.previewSnippet : ""
            var icon = (item.pageType === "catalog") ? "compass" :
                       (item.pageType === "installed") ? "download" :
                       (item.pageType === "settings") ? "settings" :
                       (item.icon ? item.icon : "file-text")
            var tabMem = ""
            if (item.ramUsage && item.ramUsage.length > 0) {
                tabMem = item.ramUsage
            } else if (typeof settingsMgr !== "undefined" && settingsMgr.getTabMemoryUsage) {
                tabMem = settingsMgr.getTabMemoryUsage(item.tabId ? item.tabId : "")
                if (!tabMem || tabMem.length === 0) {
                    tabMem = settingsMgr.calculateTabMemoryUsage(item.pageType, item.filePath, 50)
                }
            }
            var ram = tabMem ? tabMem : "5.0 MB"
            var showRam = (typeof settingsMgr !== "undefined") && (settingsMgr.tabRamUsageMode === "preview" || settingsMgr.tabRamUsageMode === "both")
            return {
                docsetId: docId,
                docsetName: docName,
                title: title,
                previewSnippet: snippet,
                iconName: icon,
                ramUsage: ram,
                showRam: showRam
            }
        }
        return null
    }

    function showHoverCardForTab(targetIndex, targetX, animateSlide) {
        if (tabHoverCard.isOpen && root.currentHoverIndex === targetIndex) {
            return
        }

        var data = getHoverCardData(targetIndex)
        if (!data) return

        root.currentHoverIndex = targetIndex
        var cardX = Math.max(10, Math.min(root.width - tabHoverCard.width - 10, targetX))

        if (animateSlide && tabHoverCard.isOpen) {
            tabHoverCardXAnim.enabled = true
            tabHoverCard.x = cardX
            tabHoverCard.updateData(data, true)
        } else {
            tabHoverCardXAnim.enabled = false
            tabHoverCard.x = cardX
            tabHoverCard.updateData(data, false)
            tabHoverCard.open()
            tabHoverCardXAnim.enabled = true
        }
    }

    // Hover Card Initial Timer & Grace Period Timer
    Timer {
        id: hoverCardTimer
        interval: 350
        repeat: false
        property int targetIndex: -1
        property real targetX: 0

        onTriggered: {
            root.showHoverCardForTab(targetIndex, targetX, false)
        }
    }

    Timer {
        id: hoverGraceTimer
        interval: 350
        repeat: false
        onTriggered: {
            if (!hoverCardArea.containsMouse) {
                root.closeHoverCard()
            }
        }
    }

    // Cursor Range / Safe Zone Watcher
    // If the cursor leaves the tab strip (with padding) and the overview card (with padding),
    // immediately fade away the overview instead of waiting for the grace timer.
    Timer {
        id: cursorZoneTimer
        interval: 35
        repeat: true
        running: tabHoverCard.isOpen
        onTriggered: {
            if (!tabHoverCard.isOpen) return

            // 1. Tab strip zone bounds
            var tabsPos = tabsContainer.mapToItem(null, 0, 0)
            var tabPad = 16
            var tabsW = (tabsRow ? tabsRow.implicitWidth + 36 : 200)
            var tabX1 = tabsPos.x - tabPad
            var tabX2 = tabsPos.x + tabsW + tabPad
            var tabY1 = -tabPad
            var tabY2 = root.height + tabPad

            // 2. Card zone bounds
            var cardPos = tabHoverCard.mapToItem(null, 0, 0)
            var cardPad = 16
            var cardX1 = cardPos.x - cardPad
            var cardX2 = cardPos.x + tabHoverCard.width + cardPad
            var cardY1 = cardPos.y - cardPad
            var cardY2 = cardPos.y + tabHoverCard.height + cardPad

            if (typeof framelessHelper !== "undefined" && framelessHelper && framelessHelper.isCursorInHoverZone) {
                var inZone = framelessHelper.isCursorInHoverZone(tabX1, tabY1, tabX2, tabY2, cardX1, cardY1, cardX2, cardY2)
                if (!inZone) {
                    root.closeHoverCard()
                }
            }
        }
    }

    TabHoverCard {
        id: tabHoverCard
        y: root.height + 4
        z: 999999

        onIsOpenChanged: {
            if (!isOpen) {
                root.currentHoverIndex = -1
            }
        }

        Behavior on x {
            id: tabHoverCardXAnim
            enabled: false
            NumberAnimation {
                duration: 240
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            id: hoverCardArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                hoverGraceTimer.stop()
            }
            onExited: {
                hoverGraceTimer.restart()
            }
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
