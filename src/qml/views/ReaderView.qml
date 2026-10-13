import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    property string currentDocsetId: ""
    property string currentDocsetName: ""
    property string currentFilePath: ""
    property string currentTitle: ""
    property var history: []
    property int historyIndex: -1
    property real zoomFactor: 1.0

    // Autoscroll / Scroll Lock state
    property bool autoScrollActive: false
    property real autoScrollOriginX: 0
    property real autoScrollOriginY: 0
    property real autoScrollCurrentX: 0
    property real autoScrollCurrentY: 0
    property real autoScrollPressTime: 0
    property bool autoScrollWasDragged: false

    function startAutoScroll(originX, originY) {
        if (!currentFilePath) return
        if (docScroll.contentHeight <= docScroll.height && docScroll.contentWidth <= docScroll.width) {
            return
        }
        autoScrollOriginX = originX
        autoScrollOriginY = originY
        autoScrollCurrentX = originX
        autoScrollCurrentY = originY
        autoScrollPressTime = Date.now()
        autoScrollWasDragged = false
        autoScrollActive = true
    }

    function stopAutoScroll() {
        autoScrollActive = false
    }

    function toggleAutoScroll(originX, originY) {
        if (autoScrollActive) {
            stopAutoScroll()
        } else {
            startAutoScroll(originX, originY)
        }
    }

    onVisibleChanged: {
        if (!visible) {
            stopAutoScroll()
        }
    }

    signal navigateToCatalog()

    function openDocument(docsetId, docsetName, fullFilePath, title) {
        stopAutoScroll()
        currentDocsetId = docsetId
        currentDocsetName = docsetName
        currentTitle = title ? title : "Documentation"

        // Update history
        if (historyIndex < history.length - 1) {
            history = history.slice(0, historyIndex + 1)
        }
        history.push({ docsetId: docsetId, docsetName: docsetName, filePath: fullFilePath, title: currentTitle })
        historyIndex = history.length - 1

        loadPage(fullFilePath)
        loadSymbolTypes()
    }

    function loadPage(path) {
        stopAutoScroll()
        currentFilePath = path
        var rawHtml = searchEngine.readFileContent(path)
        if (rawHtml.length > 0) {
            // Preprocess HTML for reader: strip web chrome, neutralize bright styles, inject theme CSS
            var styledHtml = searchEngine.prepareHtmlForReader(rawHtml, Theme.isDark)
            docArea.text = styledHtml
            docScroll.contentY = 0
        } else {
            docArea.text = "<div style='color: " + Theme.textMuted + "; padding: 40px; text-align: center;'>" +
                           "<h3>Document Not Found</h3><p>" + path + "</p></div>"
        }
    }

    Connections {
        target: Theme
        function onIsDarkChanged() {
            if (root.currentFilePath) {
                root.loadPage(root.currentFilePath)
            }
        }
    }

    function goBack() {
        if (historyIndex > 0) {
            historyIndex--
            var item = history[historyIndex]
            currentDocsetId = item.docsetId
            currentDocsetName = item.docsetName
            currentTitle = item.title
            loadPage(item.filePath)
        }
    }

    function goForward() {
        if (historyIndex < history.length - 1) {
            historyIndex++
            var item = history[historyIndex]
            currentDocsetId = item.docsetId
            currentDocsetName = item.docsetName
            currentTitle = item.title
            loadPage(item.filePath)
        }
    }

    function loadSymbolTypes() {
        if (!currentDocsetId) return
        var types = searchEngine.getSymbolTypes(currentDocsetId)
        symbolTypesModel.clear()
        var totalCount = 0
        for (var i = 0; i < types.length; ++i) {
            totalCount += types[i].count
        }
        symbolTypesModel.append({ type: "All", count: totalCount })
        for (var j = 0; j < types.length; ++j) {
            symbolTypesModel.append(types[j])
        }
        selectedSymbolType = "All"
        loadSymbols()
    }

    property string selectedSymbolType: "All"
    ListModel { id: symbolTypesModel }
    ListModel { id: symbolsListModel }

    function loadSymbols() {
        symbolsListModel.clear()
        if (!currentDocsetId) return

        var typeToQuery = (selectedSymbolType === "All") ? "" : selectedSymbolType
        var filterText = (typeof symbolSearchInput !== "undefined" && symbolSearchInput) ? symbolSearchInput.text : ""
        var results = searchEngine.getSymbolsFiltered(currentDocsetId, typeToQuery, filterText, 200)
        for (var i = 0; i < results.length; ++i) {
            symbolsListModel.append(results[i])
        }
    }

    // Main layout
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Left Sidebar: TOC / Symbols Tree
        Rectangle {
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            color: Theme.sidebarBg
            border.color: Theme.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // Docset Picker
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    DocLogo {
                        docId: root.currentDocsetId
                        size: 20
                        showBackground: false
                        visible: root.currentDocsetId !== ""
                    }

                    LucideIcon {
                        name: "book-open"
                        size: 14
                        color: Theme.accent
                        visible: root.currentDocsetId === ""
                    }

                    Text {
                        Layout.fillWidth: true
                        text: currentDocsetName ? currentDocsetName : "Select Documentation"
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                // Symbol Filter Input
                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: Theme.radiusSm
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        LucideIcon {
                            name: "search"
                            size: 11
                            color: Theme.textMuted
                        }

                        TextInput {
                            id: symbolSearchInput
                            Layout.fillWidth: true
                            font.pixelSize: 11
                            color: Theme.textPrimary
                            clip: true
                            onTextChanged: root.loadSymbols()

                            Text {
                                anchors.fill: parent
                                text: "Filter symbols..."
                                font.pixelSize: 11
                                color: Theme.textMuted
                                visible: !symbolSearchInput.text
                            }
                        }
                    }
                }

                // Symbol Categories (Horizontal Scrollable Filter Bar)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    spacing: 2

                    // Scroll Left Chevron
                    Rectangle {
                        width: 18
                        height: 24
                        radius: Theme.radiusSm
                        color: leftPillScrollArea.containsMouse ? Theme.surfaceHover : "transparent"
                        visible: categoryFlickable.contentWidth > categoryFlickable.width && categoryFlickable.contentX > 2
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 120 } }

                        LucideIcon {
                            anchors.centerIn: parent
                            name: "chevron-left"
                            size: 12
                            color: leftPillScrollArea.containsMouse ? Theme.accent : Theme.textMuted
                        }

                        MouseArea {
                            id: leftPillScrollArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                categoryScrollAnim.stop()
                                categoryScrollAnim.to = Math.max(0, categoryFlickable.contentX - 100)
                                categoryScrollAnim.start()
                            }
                        }
                    }

                    // Flickable Categories Scroller
                    Flickable {
                        id: categoryFlickable
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        contentWidth: categoriesRow.implicitWidth
                        contentHeight: 30
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        flickableDirection: Flickable.HorizontalFlick

                        NumberAnimation {
                            id: categoryScrollAnim
                            target: categoryFlickable
                            property: "contentX"
                            duration: 180
                            easing.type: Easing.OutCubic
                        }

                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: function(event) {
                                var delta = (event.angleDelta.y !== 0) ? event.angleDelta.y : event.angleDelta.x
                                categoryFlickable.contentX = Math.max(0, Math.min(categoryFlickable.contentWidth - categoryFlickable.width, categoryFlickable.contentX - delta))
                            }
                        }

                        Row {
                            id: categoriesRow
                            spacing: 6
                            Repeater {
                                model: symbolTypesModel
                                Rectangle {
                                    height: 26
                                    width: typeLabel.implicitWidth + 16
                                    radius: 13
                                    color: (selectedSymbolType === model.type) ? Theme.accent : (pillArea.containsMouse ? Theme.surfaceHover : Theme.surface)
                                    border.color: (selectedSymbolType === model.type) ? Theme.accent : Theme.border
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                                    Text {
                                        id: typeLabel
                                        anchors.centerIn: parent
                                        text: model.type + (model.count > 0 ? (" (" + model.count + ")") : "")
                                        font.pixelSize: 10
                                        font.bold: selectedSymbolType === model.type
                                        color: (selectedSymbolType === model.type) ? Theme.textOnAccent : Theme.textSecondary
                                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                                    }

                                    MouseArea {
                                        id: pillArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            selectedSymbolType = model.type
                                            root.loadSymbols()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Scroll Right Chevron
                    Rectangle {
                        width: 18
                        height: 24
                        radius: Theme.radiusSm
                        color: rightPillScrollArea.containsMouse ? Theme.surfaceHover : "transparent"
                        visible: categoryFlickable.contentWidth > categoryFlickable.width && categoryFlickable.contentX < (categoryFlickable.contentWidth - categoryFlickable.width - 2)
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 120 } }

                        LucideIcon {
                            anchors.centerIn: parent
                            name: "chevron-right"
                            size: 12
                            color: rightPillScrollArea.containsMouse ? Theme.accent : Theme.textMuted
                        }

                        MouseArea {
                            id: rightPillScrollArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                categoryScrollAnim.stop()
                                categoryScrollAnim.to = Math.min(categoryFlickable.contentWidth - categoryFlickable.width, categoryFlickable.contentX + 100)
                                categoryScrollAnim.start()
                            }
                        }
                    }
                }

                // Symbols List
                ListView {
                    id: symbolsList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: symbolsListModel
                    spacing: 2

                    ScrollBar.vertical: ScrollBar {
                        active: true
                    }

                    delegate: Rectangle {
                        width: symbolsList.width
                        height: 30
                        radius: Theme.radiusSm
                        color: symMouseArea.containsMouse ? Theme.surfaceHover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 6

                            Text {
                                text: model.name
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                color: Theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: symMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.openDocument(currentDocsetId, currentDocsetName, model.fullFilePath, model.name)
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "No symbols available"
                        font.pixelSize: 11
                        color: Theme.textMuted
                        visible: symbolsList.count === 0
                    }
                }
            }
        }

        // Right Pane: Document Viewer
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Reader Toolbar
            Rectangle {
                Layout.fillWidth: true
                height: 44
                color: Theme.surface
                border.color: Theme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    // Navigation buttons
                    RowLayout {
                        spacing: 4

                        Rectangle {
                            width: 28
                            height: 28
                            radius: Theme.radiusSm
                            color: backArea.containsMouse ? Theme.surfaceHover : "transparent"
                            opacity: historyIndex > 0 ? 1.0 : 0.4
                            scale: backArea.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                            LucideIcon {
                                anchors.centerIn: parent
                                name: "chevron-left"
                                size: 14
                                color: Theme.textPrimary
                            }

                            MouseArea {
                                id: backArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: historyIndex > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                enabled: historyIndex > 0
                                onClicked: root.goBack()
                            }
                        }

                        Rectangle {
                            width: 28
                            height: 28
                            radius: Theme.radiusSm
                            color: fwdArea.containsMouse ? Theme.surfaceHover : "transparent"
                            opacity: historyIndex < history.length - 1 ? 1.0 : 0.4
                            scale: fwdArea.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                            LucideIcon {
                                anchors.centerIn: parent
                                name: "chevron-right"
                                size: 14
                                color: Theme.textPrimary
                            }

                            MouseArea {
                                id: fwdArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: (historyIndex < history.length - 1) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                enabled: historyIndex < history.length - 1
                                onClicked: root.goForward()
                            }
                        }

                        Rectangle {
                            width: 28
                            height: 28
                            radius: Theme.radiusSm
                            color: reloadArea.containsMouse ? Theme.surfaceHover : "transparent"
                            scale: reloadArea.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                            LucideIcon {
                                anchors.centerIn: parent
                                name: "refresh-cw"
                                size: 13
                                color: Theme.textPrimary
                            }

                            MouseArea {
                                id: reloadArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (currentFilePath) loadPage(currentFilePath)
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 1
                        height: 20
                        color: Theme.border
                    }

                    // Title / breadcrumb
                    Text {
                        text: (currentDocsetName ? (currentDocsetName + " › ") : "") + (currentTitle ? currentTitle : "Offline Reader")
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // Zoom Controls
                    RowLayout {
                        spacing: 4

                        Rectangle {
                            width: 26
                            height: 26
                            radius: Theme.radiusSm
                            color: zoomOutArea.containsMouse ? Theme.surfaceHover : "transparent"
                            scale: zoomOutArea.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                            LucideIcon {
                                anchors.centerIn: parent
                                name: "zoom-out"
                                size: 13
                                color: Theme.textPrimary
                            }

                            MouseArea {
                                id: zoomOutArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    zoomFactor = Math.max(0.7, zoomFactor - 0.1)
                                }
                            }
                        }

                        Text {
                            text: Math.round(zoomFactor * 100) + "%"
                            font.pixelSize: 11
                            color: Theme.textMuted
                        }

                        Rectangle {
                            width: 26
                            height: 26
                            radius: Theme.radiusSm
                            color: zoomInArea.containsMouse ? Theme.surfaceHover : "transparent"
                            scale: zoomInArea.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                            LucideIcon {
                                anchors.centerIn: parent
                                name: "zoom-in"
                                size: 13
                                color: Theme.textPrimary
                            }

                            MouseArea {
                                id: zoomInArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    zoomFactor = Math.min(1.8, zoomFactor + 0.1)
                                }
                            }
                        }
                    }
                }
            }

            // Reader Document Surface
            Rectangle {
                id: readerSurface
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.readerBg
                clip: true

                Flickable {
                    id: docScroll
                    anchors.fill: parent
                    contentWidth: parent.width
                    contentHeight: docArea.height + 60
                    clip: true

                    ScrollBar.vertical: ScrollBar {
                        active: true
                    }

                    TextEdit {
                        id: docArea
                        width: parent.width - 60
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 24
                        readOnly: true
                        selectByMouse: true
                        textFormat: TextEdit.RichText
                        wrapMode: TextEdit.Wrap
                        color: Theme.textPrimary
                        baseUrl: currentFilePath ? ("file:///" + currentFilePath.substring(0, currentFilePath.lastIndexOf('/') + 1)) : ""
                        font.family: Theme.fontSans
                        font.pixelSize: Math.round(settingsMgr.readerFontSize * root.zoomFactor)

                        onLinkActivated: function(link) {
                            root.stopAutoScroll()
                            if (link.startsWith("http://") || link.startsWith("https://")) {
                                Qt.openUrlExternally(link)
                            } else if (link.startsWith("#")) {
                                // In-page anchor fragment (e.g. #Requirements)
                                // Do not treat as relative file path
                            } else {
                                // Relative anchor or file link
                                var dir = currentFilePath.substring(0, currentFilePath.lastIndexOf('/'))
                                var newPath = dir + "/" + link
                                root.openDocument(currentDocsetId, currentDocsetName, newPath, link)
                            }
                        }
                    }
                }

                // Middle Click Detector to activate Scroll Lock
                MouseArea {
                    id: middleClickDetector
                    anchors.fill: parent
                    z: 50
                    acceptedButtons: Qt.MiddleButton
                    cursorShape: root.autoScrollActive ? Qt.SizeAllCursor : Qt.ArrowCursor
                    onPressed: function(mouse) {
                        if (mouse.button === Qt.MiddleButton) {
                            root.toggleAutoScroll(mouse.x, mouse.y)
                        }
                    }
                }

                TapHandler {
                    target: readerSurface
                    acceptedButtons: Qt.MiddleButton
                    onTapped: function(eventPoint) {
                        root.toggleAutoScroll(eventPoint.position.x, eventPoint.position.y)
                    }
                }

                // Autoscroll Full Viewport Overlay (handles mouse movement & click-to-exit)
                MouseArea {
                    id: autoScrollOverlay
                    anchors.fill: parent
                    z: 998
                    visible: root.autoScrollActive
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: {
                        var dy = root.autoScrollCurrentY - root.autoScrollOriginY
                        return (Math.abs(dy) > 12) ? Qt.SizeVerCursor : Qt.SizeAllCursor
                    }

                    onPositionChanged: function(mouse) {
                        root.autoScrollCurrentX = mouse.x
                        root.autoScrollCurrentY = mouse.y
                        if (Math.abs(mouse.y - root.autoScrollOriginY) > 8 || Math.abs(mouse.x - root.autoScrollOriginX) > 8) {
                            root.autoScrollWasDragged = true
                        }
                    }

                    onPressed: function(mouse) {
                        if (Date.now() - root.autoScrollPressTime > 120) {
                            root.stopAutoScroll()
                        }
                    }

                    onReleased: function(mouse) {
                        if (mouse.button === Qt.MiddleButton && root.autoScrollWasDragged && (Date.now() - root.autoScrollPressTime > 200)) {
                            root.stopAutoScroll()
                        }
                    }

                    onWheel: function(wheel) {
                        root.stopAutoScroll()
                    }
                }

                // Scroll Lock HUD Indicator (anchor circle at middle click position)
                Item {
                    id: autoScrollIndicator
                    visible: root.autoScrollActive
                    z: 999
                    x: Math.round(root.autoScrollOriginX - width / 2)
                    y: Math.round(root.autoScrollOriginY - height / 2)
                    width: 38
                    height: 38

                    // Outer soft glow
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Theme.accent
                        opacity: 0.18
                        scale: 1.15
                    }

                    // Main circular badge
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Theme.isDark ? "#18181b" : "#ffffff"
                        border.color: (Math.abs(root.autoScrollCurrentY - root.autoScrollOriginY) > 12) ? Theme.accent : Theme.border
                        border.width: 1.5
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        // Up chevron
                        LucideIcon {
                            name: "chevron-up"
                            size: 13
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 2
                            color: (root.autoScrollCurrentY - root.autoScrollOriginY < -12) ? Theme.accent : Theme.textMuted
                            scale: (root.autoScrollCurrentY - root.autoScrollOriginY < -12) ? 1.2 : 1.0
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }

                        // Center deadzone dot
                        Rectangle {
                            anchors.centerIn: parent
                            width: 6
                            height: 6
                            radius: 3
                            color: (Math.abs(root.autoScrollCurrentY - root.autoScrollOriginY) <= 12) ? Theme.accent : Theme.textSecondary
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        // Down chevron
                        LucideIcon {
                            name: "chevron-down"
                            size: 13
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            color: (root.autoScrollCurrentY - root.autoScrollOriginY > 12) ? Theme.accent : Theme.textMuted
                            scale: (root.autoScrollCurrentY - root.autoScrollOriginY > 12) ? 1.2 : 1.0
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }
                    }
                }

                // Autoscroll Loop Timer (~60 FPS)
                Timer {
                    id: autoScrollTimer
                    interval: 16
                    repeat: true
                    running: root.autoScrollActive
                    onTriggered: {
                        if (!root.autoScrollActive) return

                        var dy = root.autoScrollCurrentY - root.autoScrollOriginY
                        var dx = root.autoScrollCurrentX - root.autoScrollOriginX
                        var deadzone = 12

                        // Vertical scrolling
                        if (Math.abs(dy) > deadzone) {
                            var distY = Math.abs(dy) - deadzone
                            var speedY = Math.sign(dy) * Math.min(50, Math.pow(distY / 10, 1.35) * 1.5)
                            var maxContentY = Math.max(0, docScroll.contentHeight - docScroll.height)
                            docScroll.contentY = Math.max(0, Math.min(maxContentY, docScroll.contentY + speedY))
                        }

                        // Horizontal scrolling (if document has horizontal overflow)
                        if (docScroll.contentWidth > docScroll.width && Math.abs(dx) > deadzone) {
                            var distX = Math.abs(dx) - deadzone
                            var speedX = Math.sign(dx) * Math.min(40, Math.pow(distX / 10, 1.35) * 1.5)
                            var maxContentX = Math.max(0, docScroll.contentWidth - docScroll.width)
                            docScroll.contentX = Math.max(0, Math.min(maxContentX, docScroll.contentX + speedX))
                        }
                    }
                }

                Shortcut {
                    sequence: "Esc"
                    enabled: root.autoScrollActive
                    onActivated: root.stopAutoScroll()
                }

                // Placeholder when no doc is loaded
                Item {
                    anchors.centerIn: parent
                    visible: !currentFilePath

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        LucideIcon {
                            Layout.alignment: Qt.AlignHCenter
                            name: "book-open"
                            size: 48
                            color: Theme.accent
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No Documentation Open"
                            font.pixelSize: 18
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Select a symbol from the left sidebar, press Ctrl+K to search, or browse libraries."
                            font.pixelSize: 13
                            color: Theme.textMuted
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 180
                            height: 36
                            radius: Theme.radiusMd
                            color: !networkMgr.isOnline ? Theme.surfaceElevated : (browseLibArea.containsMouse ? Theme.accentHover : Theme.accent)
                            border.color: !networkMgr.isOnline ? Theme.border : "transparent"
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                LucideIcon {
                                    visible: !networkMgr.isOnline
                                    name: "wifi-off"
                                    size: 13
                                    color: Theme.textMuted
                                }
                                Text {
                                    text: networkMgr.isOnline ? "Browse Libraries" : "Browse (Offline)"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: networkMgr.isOnline ? Theme.textOnAccent : Theme.textMuted
                                }
                            }

                            MouseArea {
                                id: browseLibArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: networkMgr.isOnline ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                                onClicked: root.navigateToCatalog()
                            }
                        }
                    }
                }
            }
        }
    }
}
