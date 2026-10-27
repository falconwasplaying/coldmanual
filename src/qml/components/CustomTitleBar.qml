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

    function closeTab(index) {
        if (!root.tabsModel || index < 0 || index >= root.tabsModel.count) return
        root.closeHoverCard()
        var target = tabsRepeater.itemAt(index)
        if (target && !target.isClosing && target.closeWithAnimation) {
            target.closeWithAnimation()
            return
        }
        root.closeTabRequested(index)
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

    // App Logo & Branding (Left)
    Item {
        id: logoItem
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 44
        z: 2

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

    // Tabs & Header Area (Brave Tab Strip Architecture)
    Item {
        id: tabsArea
        anchors.left: logoItem.right
        anchors.right: windowControls.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        clip: true

        // Brave Tab Sizing & Rapid-Close State
        property real lockedTabWidth: 0

        readonly property real currentTabWidth: {
            var normal = getNormalTabWidth()
            if (lockedTabWidth > 0 && tabsMouseTracker.containsMouse) {
                return Math.min(lockedTabWidth, normal)
            }
            return normal
        }

        function getNormalTabWidth() {
            if (!root.tabsModel || root.tabsModel.count <= 0) return 220
            var count = root.tabsModel.count
            var btnW = (count > 25) ? 24 : 28
            var avail = Math.max(40, tabsArea.width - btnW - 8)
            var sp = (count > 20) ? 0 : ((count > 10) ? 1 : 2)
            var totalNeeded = count * 220 + (count - 1) * sp
            if (totalNeeded <= avail) return 220
            return Math.max(10, Math.floor((avail - (count - 1) * sp) / count))
        }

        // Mouse Tracker for Rapid-Close Lock
        MouseArea {
            id: tabsMouseTracker
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: tabsRow.width + 12
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            z: -1
            onExited: {
                tabsArea.lockedTabWidth = 0
            }
        }

        Row {
            id: tabsRow
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: (root.tabsModel && root.tabsModel.count > 20) ? 0 : ((root.tabsModel && root.tabsModel.count > 10) ? 1 : 2)

            Repeater {
                id: tabsRepeater
                model: root.tabsModel

                delegate: Item {
                    id: tabItem
                    property string savedTabId: (typeof model.tabId !== "undefined") ? model.tabId : ""
                    property real visualWidth: 0
                    width: visualWidth
                    height: 32
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    z: isActive ? 2 : 1
                    opacity: 1.0

                    property bool isActive: index === root.activeTabIndex
                    property bool isHovered: tabMouseArea.containsMouse || (closeBtn.visible && closeBtnMouse.containsMouse)
                    property bool isClosing: false

                    // Progressive Shrinking Modes (Brave Tab Shrink Logic)
                    readonly property bool isIconOnly: visualWidth < 72
                    readonly property int iconSize: {
                        if (visualWidth >= 36) return 16
                        return Math.max(8, Math.min(16, Math.floor(visualWidth * 0.48)))
                    }
                    readonly property int lucideSize: {
                        if (visualWidth >= 36) return 13
                        return Math.max(7, Math.min(13, Math.floor(visualWidth * 0.40)))
                    }
                    readonly property real lucideStrokeWidth: (iconSize <= 10) ? 1.5 : 2.0

                    property bool showCloseButton: {
                        if (isClosing || isIconOnly) return false
                        var mode = settingsMgr.tabCloseButtonMode
                        if (mode === "always") return true
                        if (mode === "never") return false
                        if (visualWidth < 95 && !isActive) return false
                        return isHovered || isActive
                    }

                    property bool showRamOnTab: {
                        if (visualWidth < 160) return false
                        var mode = settingsMgr.tabRamUsageMode
                        return mode === "tab" || mode === "both"
                    }

                    // Opening Animation: Write itself in from left to right with ease out (like Brave)
                    NumberAnimation {
                        id: openAnim
                        target: tabItem
                        property: "visualWidth"
                        from: 0
                        to: tabsArea.currentTabWidth
                        duration: 170
                        easing.type: Easing.OutCubic
                    }

                    // Closing Animation: Erase tab from right to left like Brave, sibling tabs slide smoothly
                    ParallelAnimation {
                        id: closeAnim
                        NumberAnimation {
                            target: tabItem
                            property: "visualWidth"
                            to: 0
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: tabItem
                            property: "opacity"
                            to: 0
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                        onFinished: {
                            var targetIdx = -1
                            if (root.tabsModel && tabItem.savedTabId.length > 0) {
                                for (var i = 0; i < root.tabsModel.count; ++i) {
                                    var m = root.tabsModel.get(i)
                                    if (m && m.tabId === tabItem.savedTabId) {
                                        targetIdx = i
                                        break
                                    }
                                }
                            }
                            if (targetIdx < 0) targetIdx = index
                            if (targetIdx >= 0 && root.tabsModel && targetIdx < root.tabsModel.count) {
                                root.closeTabRequested(targetIdx)
                            }
                        }
                    }

                    function closeWithAnimation() {
                        if (isClosing) return
                        isClosing = true
                        tabItem.enabled = false
                        root.closeHoverCard()
                        if (tabsMouseTracker.containsMouse && tabsArea.currentTabWidth < 220) {
                            tabsArea.lockedTabWidth = tabsArea.currentTabWidth
                        }
                        closeAnim.start()
                    }

                    Binding on visualWidth {
                        when: !openAnim.running && !closeAnim.running
                        value: tabsArea.currentTabWidth
                    }

                    Behavior on visualWidth {
                        enabled: !openAnim.running && !closeAnim.running
                        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                    }

                    Component.onCompleted: {
                        openAnim.start()
                    }

                    // Active Tab Pill (Brave Elevated Dark/Light Styling)
                    Rectangle {
                        id: tabActivePill
                        anchors.fill: parent
                        radius: Math.max(3, Math.min(8, Math.floor(tabItem.visualWidth / 3)))
                        color: Theme.isDark ? "#282a2f" : "#ffffff"
                        border.color: Theme.isDark ? "#3e424a" : "#c2c7cf"
                        border.width: 1
                        opacity: tabItem.isActive ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                    }

                    // Tab Hover Pill (Smooth fade on inactive hover)
                    Rectangle {
                        id: tabHoverPill
                        anchors.fill: parent
                        radius: Math.max(3, Math.min(8, Math.floor(tabItem.visualWidth / 3)))
                        color: Theme.isDark ? "#23262c" : "#e4e7ed"
                        opacity: (!tabItem.isActive && tabItem.isHovered && !tabItem.isClosing) ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                    }

                    // Brave Tab Separator Line (between adjacent inactive tabs)
                    Rectangle {
                        id: tabSeparator
                        width: 1
                        height: 16
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.outlineVariant
                        opacity: {
                            if (tabItem.visualWidth < 22) return 0.0
                            if (tabItem.isActive || tabItem.isHovered || tabItem.isClosing) return 0.0
                            if (index >= root.tabsModel.count - 1) return 0.0
                            if (index + 1 === root.activeTabIndex) return 0.0
                            var nextItem = tabsRepeater.itemAt(index + 1)
                            if (nextItem && (nextItem.isHovered || nextItem.isActive)) return 0.0
                            return 0.35
                        }
                        Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                    }

                    // Tab Content
                    Item {
                        id: tabContent
                        anchors.fill: parent
                        clip: true

                        // Centered / Left-aligned Icon
                        Item {
                            id: iconContainer
                            width: tabItem.isIconOnly ? tabItem.iconSize : 16
                            height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: tabItem.isIconOnly ? undefined : parent.left
                            anchors.leftMargin: tabItem.isIconOnly ? 0 : (tabItem.visualWidth < 100 ? 5 : 8)
                            anchors.horizontalCenter: tabItem.isIconOnly ? parent.horizontalCenter : undefined

                            DocLogo {
                                anchors.centerIn: parent
                                docId: (model.pageType === "reader" || !model.pageType) && model.docsetId ? model.docsetId : ""
                                size: tabItem.iconSize
                                showBackground: false
                                visible: (model.pageType === "reader" || !model.pageType) && model.docsetId && model.docsetId !== ""
                            }

                            LucideIcon {
                                anchors.centerIn: parent
                                name: {
                                    if (model.pageType === "catalog") return "compass"
                                    if (model.pageType === "installed") return "download"
                                    if (model.pageType === "settings") return "settings"
                                    if (model.icon && model.icon.length > 0) return model.icon
                                    return "file-text"
                                }
                                size: tabItem.lucideSize
                                strokeWidth: tabItem.lucideStrokeWidth
                                color: tabItem.isActive ? Theme.primary : Theme.textOnSurfaceVariant
                                visible: !((model.pageType === "reader" || !model.pageType) && model.docsetId && model.docsetId !== "")
                            }
                        }

                        // Document Title (visible only when not icon-only, elides right)
                        Text {
                            id: tabTitleText
                            visible: !tabItem.isIconOnly
                            anchors.left: iconContainer.right
                            anchors.leftMargin: 6
                            anchors.right: (closeBtn.visible ? closeBtn.left : (tabRamBadge.visible ? tabRamBadge.left : parent.right))
                            anchors.rightMargin: (closeBtn.visible ? 4 : (tabRamBadge.visible ? 4 : 8))
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.title ? model.title : "New Tab"
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            font.bold: tabItem.isActive
                            color: tabItem.isActive ? Theme.textOnSurface : Theme.textOnSurfaceVariant
                            elide: Text.ElideRight
                        }

                        // Tab RAM Footprint Badge
                        Rectangle {
                            id: tabRamBadge
                            visible: !tabItem.isIconOnly && tabItem.showRamOnTab && tabRamText.text.length > 0
                            anchors.right: (closeBtn.visible ? closeBtn.left : parent.right)
                            anchors.rightMargin: (closeBtn.visible ? 4 : 6)
                            anchors.verticalCenter: parent.verticalCenter
                            height: 16
                            width: tabRamText.implicitWidth + 8
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
                            visible: !tabItem.isIconOnly && tabItem.showCloseButton
                            opacity: (tabItem.isActive || tabItem.isHovered) ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18

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
                                onClicked: tabItem.closeWithAnimation()
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
                                tabItem.closeWithAnimation()
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

                    ToolTip.visible: tabItem.isIconOnly && tabMouseArea.containsMouse && !tabHoverCard.isOpen
                    ToolTip.delay: 350
                    ToolTip.text: model.title ? model.title : "New Tab"
                }
            }

            // New Tab (+) Button
            Item {
                id: newTabBtn
                width: (root.tabsModel && root.tabsModel.count > 25) ? 24 : 28
                height: width
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

            onWidthChanged: updateFramelessHitTest()
        }

        // Draggable Empty Space across the rest of the tab area
        Item {
            id: dragArea
            anchors.left: tabsRow.right
            anchors.leftMargin: 4
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                onEntered: {
                    if (tabHoverCard.isOpen) root.closeHoverCard()
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
    }

    // Window Controls (Right: Minimize, Maximize/Restore, Close)
    Row {
        id: windowControls
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 138
        spacing: 0
        z: 2

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
            var tabsPos = tabsArea.mapToItem(null, 0, 0)
            var tabPad = 16
            var tabsW = (tabsRow ? tabsRow.width + 16 : 200)
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
            var tabsEnd = tabsStart + (tabsRow ? tabsRow.width + 8 : 200.0)
            framelessHelper.updateTabsWidth(tabsStart, tabsEnd)
        }
    }

    Component.onCompleted: {
        updateFramelessHitTest()
    }
}
