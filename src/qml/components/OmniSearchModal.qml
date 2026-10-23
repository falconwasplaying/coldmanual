import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
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
        anchors.topMargin: (root.opacity > 0.01) ? 60 : 36
        scale: (root.opacity > 0.01) ? 1.0 : 0.95
        radius: Theme.shapeExtraLarge
        color: Theme.surfaceContainerHigh
        border.color: Theme.outlineVariant
        border.width: 1

        Behavior on anchors.topMargin {
            NumberAnimation { duration: Theme.animDurationNormal; easing.type: Theme.animEasingDecel }
        }
        Behavior on scale {
            NumberAnimation { duration: Theme.animDurationNormal; easing.type: Theme.animEasingDecel }
        }

        // Consume mouse clicks inside card
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Search Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                LucideIcon {
                    name: "search"
                    size: 18
                    color: Theme.primary
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: "Search symbols, functions, types, guides across installed docs..."
                    placeholderTextColor: Theme.onSurfaceVariant
                    color: Theme.onSurface
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
                    width: 44
                    height: 24
                    radius: Theme.shapeFull
                    color: Theme.surfaceContainerHighest
                    Text {
                        anchors.centerIn: parent
                        text: "ESC"
                        font.family: Theme.fontSans
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.onSurfaceVariant
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.outlineVariant
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
                    height: 52
                    radius: Theme.shapeMedium
                    color: (resultsList.currentIndex === index) ? Theme.secondaryContainer :
                           (mouseArea.containsMouse ? Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.08) : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // Docset Logo
                        DocLogo {
                            docId: model.docsetId
                            size: 24
                            showBackground: false
                        }

                        // Type Badge (M3 Tonal Chip)
                        Rectangle {
                            width: Math.max(54, typeText.implicitWidth + 14)
                            height: 24
                            radius: Theme.shapeSmall
                            color: (resultsList.currentIndex === index) ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                            border.color: Theme.outlineVariant
                            border.width: 1

                            Text {
                                id: typeText
                                anchors.centerIn: parent
                                text: model.type ? model.type : "Doc"
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                                font.bold: true
                                color: (resultsList.currentIndex === index) ? Theme.onSecondaryContainer : Theme.primary
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
                                color: (resultsList.currentIndex === index) ? Theme.onSecondaryContainer : Theme.onSurface
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: model.docsetName + " • " + model.relativePath
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                                color: (resultsList.currentIndex === index) ? Theme.onSecondaryContainer : Theme.onSurfaceVariant
                                opacity: (resultsList.currentIndex === index) ? 0.8 : 1.0
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }
                        }

                        LucideIcon {
                            name: "chevron-right"
                            size: 16
                            color: Theme.onSecondaryContainer
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
                            color: Theme.primary
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Instant Symbol & Topic Lookup"
                            font.family: Theme.fontSans
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.onSurface
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Type any function, class, type, or module from your downloaded docs"
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            color: Theme.onSurfaceVariant
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
                            color: Theme.onSurfaceVariant
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No symbols found for \"" + searchEngine.query + "\""
                            font.family: Theme.fontSans
                            font.pixelSize: 14
                            color: Theme.onSurface
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Make sure you have downloaded the relevant framework in the Browse tab"
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            color: Theme.onSurfaceVariant
                        }
                    }
                }
            }

            // Footer tips
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.outlineVariant
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 14
                Text {
                    text: "↑↓ Navigate"
                    font.family: Theme.fontSans
                    font.pixelSize: 11
                    color: Theme.onSurfaceVariant
                }
                Text {
                    text: "↵ Select"
                    font.family: Theme.fontSans
                    font.pixelSize: 11
                    color: Theme.onSurfaceVariant
                }
                Text {
                    text: "ESC Close"
                    font.family: Theme.fontSans
                    font.pixelSize: 11
                    color: Theme.onSurfaceVariant
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: (searchEngine.resultCount > 0 ? (searchEngine.resultCount + " results") : "")
                    font.family: Theme.fontSans
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.primary
                }
            }
        }
    }
}
