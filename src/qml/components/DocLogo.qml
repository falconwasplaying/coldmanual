import QtQuick
import ".."

Item {
    id: root

    property string docId: ""
    property string category: "Languages"
    property string logoSource: ""
    property int size: 36
    property int radius: Theme.radiusSm
    property bool showBackground: true

    implicitWidth: size
    implicitHeight: size

    function resolveLogo() {
        if (logoSource && logoSource !== "") return logoSource
        if (!docId || docId === "") return ""
        if (docId.startsWith("http://") || docId.startsWith("https://") || docId.startsWith("file:///")) {
            return docId
        }
        if (typeof docsetMgr !== "undefined" && docsetMgr) {
            var downloaded = docsetMgr.getLogoPath(docId)
            if (downloaded && downloaded !== "") return downloaded
        }
        if (typeof docCatalogMgr !== "undefined" && docCatalogMgr) {
            var catLogo = docCatalogMgr.getLogoUrl(docId)
            if (catLogo && catLogo !== "") return catLogo
        }
        return "https://raw.githubusercontent.com/falconwasplaying/coldmanual-db/main/logos/" + docId.toLowerCase().trim() + ".svg"
    }

    readonly property string resolvedLogo: resolveLogo()

    Connections {
        target: (typeof docCatalogMgr !== "undefined" && docCatalogMgr) ? docCatalogMgr : null
        function onLogoReady(id, path) {
            if (id === root.docId) {
                logoImg.source = ""
                logoImg.source = path
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.showBackground ? Theme.surfaceElevated : "transparent"
        border.color: root.showBackground ? Theme.border : "transparent"
        border.width: root.showBackground ? 1 : 0

        // Official Logo Image (downloaded docset, local db, local cache, or remote CDN)
        Image {
            id: logoImg
            anchors.fill: parent
            anchors.margins: root.showBackground ? Math.max(2, Math.round(root.size * 0.12)) : 0
            sourceSize.width: root.size * 2
            sourceSize.height: root.size * 2
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: root.resolvedLogo !== "" && status !== Image.Error
            source: root.resolvedLogo
        }

        // Clean Lucide Icon when uninstalled or before doc download
        LucideIcon {
            anchors.centerIn: parent
            visible: !logoImg.visible
            size: Math.round(root.size * 0.52)
            color: Theme.accent
            name: {
                var cat = root.category ? root.category.toLowerCase() : ""
                if (cat.indexOf("lang") !== -1) return "code-2"
                if (cat.indexOf("front") !== -1) return "layout"
                if (cat.indexOf("back") !== -1) return "server"
                if (cat.indexOf("data") !== -1) return "database"
                if (cat.indexOf("devops") !== -1 || cat.indexOf("tool") !== -1) return "box"
                return "book-open"
            }
        }
    }
}
