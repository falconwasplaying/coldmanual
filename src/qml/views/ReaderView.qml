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

    signal navigateToCatalog()

    function openDocument(docsetId, docsetName, fullFilePath, title) {
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
        currentFilePath = path
        var rawHtml = searchEngine.readFileContent(path)
        if (rawHtml.length > 0) {
            // Apply lightweight CSS styles suitable for theme
            var styledHtml = injectThemeStyles(rawHtml)
            docArea.text = styledHtml
            docScroll.contentY = 0
        } else {
            docArea.text = "<div style='color: " + Theme.textMuted + "; padding: 40px; text-align: center;'>" +
                           "<h3>Document Not Found</h3><p>" + path + "</p></div>"
        }
    }

    function injectThemeStyles(html) {
        var isDark = Theme.isDark
        var bgColor = isDark ? "#141416" : "#ffffff"
        var textColor = isDark ? "#e4e4e7" : "#18181b"
        var linkColor = Theme.accent
        var codeBg = isDark ? "#1f1f23" : "#f1f5f9"
        var borderColor = isDark ? "#2e2e33" : "#e2e8f0"

        var styleHeader = "<style>" +
            "body { background-color: " + bgColor + "; color: " + textColor + "; font-family: Segoe UI, sans-serif; line-height: 1.6; padding: 24px; margin: 0; }" +
            "h1, h2, h3, h4, h5, h6 { color: " + (isDark ? "#ffffff" : "#09090b") + "; margin-top: 24px; margin-bottom: 12px; }" +
            "a { color: " + linkColor + "; text-decoration: none; }" +
            "a:hover { text-decoration: underline; }" +
            "code, pre { font-family: Cascadia Code, Consolas, monospace; background-color: " + codeBg + "; border-radius: 4px; padding: 2px 6px; }" +
            "pre { padding: 14px; overflow-x: auto; border: 1px solid " + borderColor + "; }" +
            "table { border-collapse: collapse; width: 100%; margin: 16px 0; }" +
            "th, td { border: 1px solid " + borderColor + "; padding: 8px 12px; text-align: left; }" +
            "th { background-color: " + (isDark ? "#1c1c20" : "#f8fafc") + "; }" +
            "</style>"

        // If html already has <head>, inject before </head>, else prepend
        var headIdx = html.indexOf("</head>")
        if (headIdx >= 0) {
            return html.substring(0, headIdx) + styleHeader + html.substring(headIdx)
        }
        return styleHeader + html
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
        symbolTypesModel.append({ type: "All", count: 0 })
        for (var i = 0; i < types.length; ++i) {
            symbolTypesModel.append(types[i])
        }
        if (symbolTypesModel.count > 0) {
            selectedSymbolType = "All"
            loadSymbols()
        }
    }

    property string selectedSymbolType: "All"
    ListModel { id: symbolTypesModel }
    ListModel { id: symbolsListModel }

    function loadSymbols() {
        symbolsListModel.clear()
        if (!currentDocsetId) return

        var typeToQuery = (selectedSymbolType === "All") ? "" : selectedSymbolType
        var results = searchEngine.getSymbolsByType(currentDocsetId, typeToQuery, 150)
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

                    LucideIcon {
                        name: "book-open"
                        size: 14
                        color: Theme.accent
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

                // Symbol Categories (Horizontal Scroll or Pills)
                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                    Row {
                        spacing: 6
                        Repeater {
                            model: symbolTypesModel
                            Rectangle {
                                height: 26
                                width: typeLabel.implicitWidth + 16
                                radius: 13
                                color: (selectedSymbolType === model.type) ? Theme.accent : Theme.surface
                                border.color: Theme.border
                                border.width: 1

                                Text {
                                    id: typeLabel
                                    anchors.centerIn: parent
                                    text: model.type + (model.count > 0 ? (" (" + model.count + ")") : "")
                                    font.pixelSize: 10
                                    font.bold: selectedSymbolType === model.type
                                    color: (selectedSymbolType === model.type) ? Theme.textOnAccent : Theme.textSecondary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        selectedSymbolType = model.type
                                        loadSymbols()
                                    }
                                }
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
                                enabled: historyIndex < history.length - 1
                                onClicked: root.goForward()
                            }
                        }

                        Rectangle {
                            width: 28
                            height: 28
                            radius: Theme.radiusSm
                            color: reloadArea.containsMouse ? Theme.surfaceHover : "transparent"

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
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.readerBg

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
                        font.family: Theme.fontSans
                        font.pixelSize: Math.round(settingsMgr.readerFontSize * root.zoomFactor)

                        onLinkActivated: function(link) {
                            if (link.startsWith("http://") || link.startsWith("https://")) {
                                Qt.openUrlExternally(link)
                            } else {
                                // Relative anchor or file link
                                var dir = currentFilePath.substring(0, currentFilePath.lastIndexOf('/'))
                                var newPath = dir + "/" + link
                                root.openDocument(currentDocsetId, currentDocsetName, newPath, link)
                            }
                        }
                    }
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
                            width: 170
                            height: 36
                            radius: Theme.radiusMd
                            color: browseLibArea.containsMouse ? Theme.accentHover : Theme.accent

                            Text {
                                anchors.centerIn: parent
                                text: "Browse Libraries"
                                font.pixelSize: 13
                                font.bold: true
                                color: Theme.textOnAccent
                            }

                            MouseArea {
                                id: browseLibArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.navigateToCatalog()
                            }
                        }
                    }
                }
            }
        }
    }
}
