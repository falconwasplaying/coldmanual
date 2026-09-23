import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "views"
import "components"

ApplicationWindow {
    id: window
    visible: true
    width: 1200
    height: 800
    minimumWidth: 960
    minimumHeight: 640
    title: "ColdManual — Fast Offline Documentation Browser"
    color: Theme.background

    property int currentTab: 1 // Default to Browse Catalog on first run if no docs, or Reader

    Component.onCompleted: {
        if (docsetMgr.installedCount > 0) {
            currentTab = 0
            var firstDoc = docsetMgr.getInstalledDocset(docsetMgr.data(docsetMgr.index(0), 1).toString())
            if (firstDoc.indexPath) {
                readerView.openDocument(firstDoc.id, firstDoc.name, firstDoc.indexPath, firstDoc.name)
            }
        } else {
            currentTab = 1
        }
    }

    // Keyboard Shortcuts
    Shortcut {
        sequences: ["Ctrl+K", "Ctrl+P"]
        onActivated: omniSearch.open()
    }
    Shortcut {
        sequence: "Ctrl+1"
        onActivated: currentTab = 0
    }
    Shortcut {
        sequence: "Ctrl+2"
        onActivated: currentTab = 1
    }
    Shortcut {
        sequence: "Ctrl+3"
        onActivated: currentTab = 2
    }
    Shortcut {
        sequence: "Ctrl+,"
        onActivated: currentTab = 3
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar Navigation
        Rectangle {
            Layout.preferredWidth: 230
            Layout.fillHeight: true
            color: Theme.sidebarBg
            border.color: Theme.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // Logo
                RowLayout {
                    spacing: 10
                    Rectangle {
                        width: 34
                        height: 34
                        radius: Theme.radiusSm
                        color: Theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: "❄"
                            font.pixelSize: 18
                            color: "#ffffff"
                        }
                    }

                    ColumnLayout {
                        spacing: 0
                        Text {
                            text: "ColdManual"
                            font.family: Theme.fontSans
                            font.pixelSize: 17
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Text {
                            text: "Offline Docs"
                            font.pixelSize: 10
                            color: Theme.textMuted
                        }
                    }
                }

                // Omni-Search Trigger Button
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: Theme.radiusMd
                    color: omniArea.containsMouse ? Theme.surfaceHover : Theme.surface
                    border.color: Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: "🔍"
                            font.pixelSize: 12
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Search symbols..."
                            font.pixelSize: 12
                            color: Theme.textMuted
                        }

                        Rectangle {
                            width: 48
                            height: 20
                            radius: Theme.radiusSm
                            color: Theme.surfaceElevated
                            Text {
                                anchors.centerIn: parent
                                text: "Ctrl+K"
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.textMuted
                            }
                        }
                    }

                    MouseArea {
                        id: omniArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: omniSearch.open()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                // Nav Items
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    // Tab 0: Reader
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: Theme.radiusSm
                        color: (currentTab === 0) ? Theme.accentDim : (navReaderArea.containsMouse ? Theme.surfaceHover : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: "📖"
                                font.pixelSize: 14
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Reader"
                                font.pixelSize: 13
                                font.bold: currentTab === 0
                                color: (currentTab === 0) ? Theme.accent : Theme.textPrimary
                            }
                        }

                        MouseArea {
                            id: navReaderArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: currentTab = 0
                        }
                    }

                    // Tab 1: Browse Catalog
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: Theme.radiusSm
                        color: (currentTab === 1) ? Theme.accentDim : (navCatalogArea.containsMouse ? Theme.surfaceHover : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: "🌐"
                                font.pixelSize: 14
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Browse Catalog"
                                font.pixelSize: 13
                                font.bold: currentTab === 1
                                color: (currentTab === 1) ? Theme.accent : Theme.textPrimary
                            }
                        }

                        MouseArea {
                            id: navCatalogArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: currentTab = 1
                        }
                    }

                    // Tab 2: Installed & Updates
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: Theme.radiusSm
                        color: (currentTab === 2) ? Theme.accentDim : (navInstArea.containsMouse ? Theme.surfaceHover : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: "📥"
                                font.pixelSize: 14
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Installed"
                                font.pixelSize: 13
                                font.bold: currentTab === 2
                                color: (currentTab === 2) ? Theme.accent : Theme.textPrimary
                            }

                            // Count badge
                            Rectangle {
                                width: Math.max(20, instBadgeText.implicitWidth + 8)
                                height: 18
                                radius: 9
                                color: Theme.surfaceElevated

                                Text {
                                    id: instBadgeText
                                    anchors.centerIn: parent
                                    text: docsetMgr.installedCount
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Theme.textSecondary
                                }
                            }
                        }

                        MouseArea {
                            id: navInstArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: currentTab = 2
                        }
                    }

                    // Tab 3: Settings
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: Theme.radiusSm
                        color: (currentTab === 3) ? Theme.accentDim : (navSettingsArea.containsMouse ? Theme.surfaceHover : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: "⚙️"
                                font.pixelSize: 14
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Settings"
                                font.pixelSize: 13
                                font.bold: currentTab === 3
                                color: (currentTab === 3) ? Theme.accent : Theme.textPrimary
                            }
                        }

                        MouseArea {
                            id: navSettingsArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: currentTab = 3
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Sidebar Footer info
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Storage: " + docsetMgr.totalStorageUsage
                        font.pixelSize: 11
                        color: Theme.textMuted
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "v1.0"
                        font.pixelSize: 11
                        color: Theme.textMuted
                    }
                }
            }
        }

        // Main Content Views
        StackLayout {
            id: mainStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: window.currentTab

            ReaderView {
                id: readerView
                onNavigateToCatalog: window.currentTab = 1
            }

            CatalogView {
                id: catalogView
                onOpenDocsetInReader: function(docsetId, docsetName) {
                    var info = docsetMgr.getInstalledDocset(docsetId)
                    if (info.indexPath) {
                        readerView.openDocument(docsetId, docsetName, info.indexPath, docsetName)
                    }
                    window.currentTab = 0
                }
            }

            InstalledView {
                id: installedView
                onOpenDocsetInReader: function(docsetId, docsetName) {
                    var info = docsetMgr.getInstalledDocset(docsetId)
                    if (info.indexPath) {
                        readerView.openDocument(docsetId, docsetName, info.indexPath, docsetName)
                    }
                    window.currentTab = 0
                }
                onNavigateToCatalog: window.currentTab = 1
            }

            SettingsView {
                id: settingsView
            }
        }
    }

    // Global Floating Omni-Search Modal
    OmniSearchModal {
        id: omniSearch
        anchors.fill: parent
        z: 9999
        onNavigateToItem: function(docsetId, docsetName, fullFilePath, title) {
            readerView.openDocument(docsetId, docsetName, fullFilePath, title)
            window.currentTab = 0
        }
    }
}
