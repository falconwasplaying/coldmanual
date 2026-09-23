import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Item {
    id: root
    anchors.fill: parent
    visible: opacity > 0
    opacity: 0

    Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
    }

    signal navigateToItem(string docsetId, string docsetName, string fullFilePath, string title)

    function open() {
        searchField.text = ""
        searchEngine.query = ""
        opacity = 1
        searchField.forceActiveFocus()
    }

    function close() {
        opacity = 0
        searchField.focus = false
    }

    // Backdrop
    Rectangle {
        anchors.fill: parent
        color: "#90000000"
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // Modal Card
    Rectangle {
        id: modalCard
        width: Math.min(parent.width - 40, 680)
        height: Math.min(parent.height - 80, 520)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 60
        radius: Theme.radiusLg
        color: Theme.surface
        border.color: Theme.border
        border.width: 1

        // Consume mouse clicks inside card
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // Search Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                LucideIcon {
                    name: "search"
                    size: 16
                    color: Theme.accent
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: "Search symbols, functions, types, guides across installed docs..."
                    placeholderTextColor: Theme.textMuted
                    color: Theme.textPrimary
                    font.family: Theme.fontSans
                    font.pixelSize: 15
                    background: Rectangle {
                        color: "transparent"
                    }
                    onTextChanged: {
                        searchEngine.query = text
                    }
                    Keys.onEscapePressed: root.close()
                    Keys.onDownPressed: {
                        if (resultsList.count > 0) {
                            resultsList.currentIndex = Math.min(resultsList.currentIndex + 1, resultsList.count - 1)
                        }
                    }
                    Keys.onUpPressed: {
                        if (resultsList.count > 0) {
                            resultsList.currentIndex = Math.max(resultsList.currentIndex - 1, 0)
                        }
                    }
                    Keys.onReturnPressed: {
                        if (resultsList.currentIndex >= 0 && resultsList.currentIndex < resultsList.count) {
                            var item = searchEngine.getResult(resultsList.currentIndex)
                            root.navigateToItem(item.docsetId, item.docsetName, item.fullFilePath, item.name)
                            root.close()
                        }
                    }
                }

                Rectangle {
                    width: 38
                    height: 22
                    radius: Theme.radiusSm
                    color: Theme.surfaceHover
                    Text {
                        anchors.centerIn: parent
                        text: "ESC"
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textMuted
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            // Results List
            ListView {
                id: resultsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: searchEngine
                spacing: 4

                ScrollBar.vertical: ScrollBar {
                    active: true
                }

                delegate: Rectangle {
                    id: delegateItem
                    width: resultsList.width
                    height: 48
                    radius: Theme.radiusSm
                    color: (resultsList.currentIndex === index || mouseArea.containsMouse) ? Theme.surfaceHover : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        // Docset Logo
                        DocLogo {
                            docId: model.docsetId
                            size: 22
                            showBackground: false
                        }

                        // Type Badge
                        Rectangle {
                            width: Math.max(50, typeText.implicitWidth + 12)
                            height: 22
                            radius: Theme.radiusSm
                            color: {
                                var t = model.type.toLowerCase()
                                if (t.indexOf("func") >= 0 || t.indexOf("method") >= 0) return "#1e3a5f"
                                if (t.indexOf("class") >= 0 || t.indexOf("struct") >= 0) return "#3b1e5f"
                                if (t.indexOf("type") >= 0 || t.indexOf("enum") >= 0) return "#1e4d3f"
                                if (t.indexOf("guide") >= 0 || t.indexOf("module") >= 0) return "#4d3e1e"
                                return Theme.surfaceElevated
                            }

                            Text {
                                id: typeText
                                anchors.centerIn: parent
                                text: model.type ? model.type : "Doc"
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.accent
                            }
                        }

                        // Symbol Name & Docset
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: model.name
                                font.family: Theme.fontMono
                                font.pixelSize: 13
                                font.bold: true
                                color: Theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: model.docsetName + " • " + model.relativePath
                                font.pixelSize: 11
                                color: Theme.textMuted
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }
                        }

                        LucideIcon {
                            name: "chevron-right"
                            size: 14
                            color: Theme.accent
                            visible: resultsList.currentIndex === index
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            resultsList.currentIndex = index
                            var item = searchEngine.getResult(index)
                            root.navigateToItem(item.docsetId, item.docsetName, item.fullFilePath, item.name)
                            root.close()
                        }
                    }
                }

                // Empty / Placeholder state
                Item {
                    anchors.centerIn: parent
                    visible: resultsList.count === 0 && searchEngine.query.length === 0
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        LucideIcon {
                            Layout.alignment: Qt.AlignHCenter
                            name: "zap"
                            size: 32
                            color: Theme.accent
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Instant Symbol & Topic Lookup"
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.textSecondary
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Type any function, class, type, or module from your downloaded docs"
                            font.pixelSize: 12
                            color: Theme.textMuted
                        }
                    }
                }

                Item {
                    anchors.centerIn: parent
                    visible: resultsList.count === 0 && searchEngine.query.length > 0
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        LucideIcon {
                            Layout.alignment: Qt.AlignHCenter
                            name: "search"
                            size: 32
                            color: Theme.textMuted
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No symbols found for \"" + searchEngine.query + "\""
                            font.pixelSize: 14
                            color: Theme.textSecondary
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Make sure you have downloaded the relevant framework in the Browse tab"
                            font.pixelSize: 12
                            color: Theme.textMuted
                        }
                    }
                }
            }

            // Footer tips
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 14
                Text {
                    text: "↑↓ Navigate"
                    font.pixelSize: 11
                    color: Theme.textMuted
                }
                Text {
                    text: "↵ Select"
                    font.pixelSize: 11
                    color: Theme.textMuted
                }
                Text {
                    text: "ESC Close"
                    font.pixelSize: 11
                    color: Theme.textMuted
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: (searchEngine.resultCount > 0 ? (searchEngine.resultCount + " results") : "")
                    font.pixelSize: 11
                    color: Theme.accent
                }
            }
        }
    }
}
