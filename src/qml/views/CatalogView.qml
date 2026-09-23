import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    signal openDocsetInReader(string docsetId, string docsetName)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingMd

        // Header & Search
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingMd

            ColumnLayout {
                spacing: 2
                Text {
                    text: "Browse Documentation"
                    font.family: Theme.fontSans
                    font.pixelSize: 22
                    font.bold: true
                    color: Theme.textPrimary
                }
                Text {
                    text: "Download offline documentation for your favorite languages and frameworks"
                    font.pixelSize: 13
                    color: Theme.textMuted
                }
            }

            Item { Layout.fillWidth: true }

            // Search input
            Rectangle {
                width: 260
                height: 38
                radius: Theme.radiusMd
                color: Theme.surface
                border.color: searchInput.activeFocus ? Theme.borderFocus : Theme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    LucideIcon {
                        name: "search"
                        size: 13
                        color: Theme.textMuted
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: Theme.fontSans
                        font.pixelSize: 13
                        color: Theme.textPrimary
                        clip: true
                        onTextChanged: catalogMgr.searchQuery = text

                        Text {
                            anchors.fill: parent
                            text: "Filter languages..."
                            font.pixelSize: 13
                            color: Theme.textMuted
                            visible: !searchInput.text && !searchInput.activeFocus
                        }
                    }

                    LucideIcon {
                        name: "x"
                        size: 12
                        color: Theme.textMuted
                        visible: searchInput.text.length > 0
                        MouseArea {
                            anchors.fill: parent
                            onClicked: searchInput.text = ""
                        }
                    }
                }
            }

            // Refresh Button
            Rectangle {
                width: 38
                height: 38
                radius: Theme.radiusMd
                color: refreshArea.containsMouse ? Theme.surfaceHover : Theme.surface
                border.color: Theme.border
                border.width: 1

                LucideIcon {
                    anchors.centerIn: parent
                    name: "refresh-cw"
                    size: 14
                    color: Theme.textPrimary
                }

                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: catalogMgr.refreshCatalog()
                }
            }
        }

        // Category Filter Pills
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: catalogMgr.categories

                Rectangle {
                    height: 28
                    radius: 14
                    width: catText.implicitWidth + 24
                    color: (catalogMgr.selectedCategory === modelData) ? Theme.accent :
                           (catArea.containsMouse ? Theme.surfaceHover : Theme.surface)
                    border.color: (catalogMgr.selectedCategory === modelData) ? Theme.accent : Theme.border
                    border.width: 1

                    Text {
                        id: catText
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 12
                        font.bold: catalogMgr.selectedCategory === modelData
                        color: (catalogMgr.selectedCategory === modelData) ? Theme.textOnAccent : Theme.textSecondary
                    }

                    MouseArea {
                        id: catArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: catalogMgr.selectedCategory = modelData
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: catalogMgr.totalItems + " available"
                font.pixelSize: 12
                color: Theme.textMuted
            }
        }

        // Catalog Grid
        GridView {
            id: catalogGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: Math.max(340, (width - 10) / Math.max(1, Math.floor(width / 340)))
            cellHeight: 215
            model: catalogMgr

            ScrollBar.vertical: ScrollBar {
                active: true
            }

            delegate: Item {
                width: catalogGrid.cellWidth
                height: catalogGrid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: Theme.radiusMd
                    color: Theme.surface
                    border.color: cardHoverArea.containsMouse ? Theme.accent : Theme.border
                    border.width: 1

                    MouseArea {
                        id: cardHoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        // Top Row: Icon + Name + Category Tag
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                width: 36
                                height: 36
                                radius: Theme.radiusSm
                                color: Theme.surfaceElevated
                                border.color: Theme.border
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: model.name ? model.name.substring(0, 2).toUpperCase() : "??"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.accent
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: model.name
                                    font.pixelSize: 15
                                    font.bold: true
                                    color: Theme.textPrimary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: model.category
                                    font.pixelSize: 11
                                    color: Theme.textMuted
                                }
                            }

                            // Installed badge if applicable
                            Rectangle {
                                visible: model.isInstalled
                                height: 22
                                width: instRow.implicitWidth + 14
                                radius: Theme.radiusSm
                                color: Theme.successBg

                                RowLayout {
                                    id: instRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    LucideIcon {
                                        name: "check"
                                        size: 11
                                        color: Theme.success
                                    }

                                    Text {
                                        text: model.installedVersion
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.success
                                    }
                                }
                            }
                        }

                        // Description
                        Text {
                            text: model.description
                            font.pixelSize: 12
                            color: Theme.textSecondary
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }

                        // Version selector row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Version:"
                                font.pixelSize: 12
                                color: Theme.textMuted
                            }

                            ComboBox {
                                id: versionPicker
                                Layout.fillWidth: true
                                model: model.versions
                                currentIndex: 0
                                enabled: !model.isDownloading

                                background: Rectangle {
                                    implicitHeight: 28
                                    radius: Theme.radiusSm
                                    color: Theme.surfaceElevated
                                    border.color: Theme.border
                                    border.width: 1
                                }

                                contentItem: Text {
                                    leftPadding: 8
                                    text: versionPicker.displayText
                                    font.pixelSize: 11
                                    color: Theme.textPrimary
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // Download progress or action buttons
                        Item {
                            Layout.fillWidth: true
                            height: 32

                            // Downloading state
                            RowLayout {
                                anchors.fill: parent
                                visible: model.isDownloading
                                spacing: 8

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    ProgressBar {
                                        Layout.fillWidth: true
                                        value: model.downloadProgress
                                        background: Rectangle {
                                            implicitHeight: 6
                                            radius: 3
                                            color: Theme.surfaceElevated
                                        }
                                        contentItem: Item {
                                            implicitHeight: 6
                                            Rectangle {
                                                width: parent.width * model.downloadProgress
                                                height: parent.height
                                                radius: 3
                                                color: Theme.accent
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: Math.round(model.downloadProgress * 100) + "%"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: Theme.accent
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: model.downloadSpeed
                                            font.pixelSize: 10
                                            color: Theme.textMuted
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: 13
                                    color: cancelArea.containsMouse ? Theme.dangerBg : Theme.surfaceElevated

                                    LucideIcon {
                                        anchors.centerIn: parent
                                        name: "x"
                                        size: 11
                                        color: Theme.danger
                                    }

                                    MouseArea {
                                        id: cancelArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: downloader.cancelDownload(model.id)
                                    }
                                }
                            }

                            // Normal / Installed State Buttons
                            RowLayout {
                                anchors.fill: parent
                                visible: !model.isDownloading
                                spacing: 8

                                // Update Available button
                                Rectangle {
                                    visible: model.isInstalled && model.updateAvailable
                                    Layout.fillWidth: true
                                    height: 30
                                    radius: Theme.radiusSm
                                    color: updateArea.containsMouse ? Theme.warning : Theme.warningBg
                                    border.color: Theme.warning
                                    border.width: 1

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        LucideIcon {
                                            name: "zap"
                                            size: 12
                                            color: updateArea.containsMouse ? "#000000" : Theme.warning
                                        }
                                        Text {
                                            text: "Update Available"
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: updateArea.containsMouse ? "#000000" : Theme.warning
                                        }
                                    }

                                    MouseArea {
                                        id: updateArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: docsetMgr.installDocset(model.id, "Latest Stable")
                                    }
                                }

                                // Install / Reinstall button
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 30
                                    radius: Theme.radiusSm
                                    color: instBtnArea.containsMouse ? Theme.accentHover : (model.isInstalled ? Theme.surfaceElevated : Theme.accent)
                                    border.color: model.isInstalled ? Theme.border : Theme.accent
                                    border.width: 1

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        LucideIcon {
                                            name: model.isInstalled ? "refresh-cw" : "download"
                                            size: 13
                                            color: model.isInstalled ? Theme.textPrimary : Theme.textOnAccent
                                        }
                                        Text {
                                            text: model.isInstalled ? "Reinstall" : "Download & Install"
                                            font.pixelSize: 12
                                            font.bold: !model.isInstalled
                                            color: model.isInstalled ? Theme.textPrimary : Theme.textOnAccent
                                        }
                                    }

                                    MouseArea {
                                        id: instBtnArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            docsetMgr.installDocset(model.id, versionPicker.currentText)
                                        }
                                    }
                                }

                                // Read button if installed
                                Rectangle {
                                    visible: model.isInstalled
                                    width: 34
                                    height: 30
                                    radius: Theme.radiusSm
                                    color: readBtnArea.containsMouse ? Theme.surfaceHover : Theme.surfaceElevated
                                    border.color: Theme.border
                                    border.width: 1

                                    LucideIcon {
                                        anchors.centerIn: parent
                                        name: "book-open"
                                        size: 13
                                        color: Theme.textPrimary
                                    }

                                    MouseArea {
                                        id: readBtnArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            root.openDocsetInReader(model.id, model.name)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
