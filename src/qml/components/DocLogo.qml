import QtQuick
import ".."

Item {
    id: root

    property string docId: "code"
    property int size: 36
    property int radius: Theme.radiusSm
    property bool showBackground: true

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.showBackground ? Theme.surfaceElevated : "transparent"
        border.color: root.showBackground ? Theme.border : "transparent"
        border.width: root.showBackground ? 1 : 0

        Image {
            id: logoImg
            anchors.fill: parent
            anchors.margins: root.showBackground ? Math.max(2, Math.round(root.size * 0.12)) : 0
            sourceSize.width: root.size * 2
            sourceSize.height: root.size * 2
            fillMode: Image.PreserveAspectFit
            smooth: true
            source: {
                if (!root.docId || root.docId === "") return "qrc:/logos/code.svg"
                if (root.docId.startsWith("http://") || root.docId.startsWith("https://") || root.docId.startsWith("file:///") || root.docId.startsWith("qrc:/")) {
                    return root.docId
                }
                var cleanId = root.docId.toLowerCase().trim()
                return "qrc:/logos/" + cleanId + ".svg"
            }
            onStatusChanged: {
                if (status === Image.Error && source !== "qrc:/logos/code.svg") {
                    source = "qrc:/logos/code.svg"
                }
            }
        }
    }
}
