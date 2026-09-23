import QtQuick

Item {
    id: root

    property string name: "snowflake"
    property color color: "#ffffff"
    property int size: 16
    property real strokeWidth: 2.0

    implicitWidth: size
    implicitHeight: size

    readonly property var iconPaths: ({
        "book-open": "<path d=\"M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z\"/><path d=\"M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z\"/>",
        "compass": "<circle cx=\"12\" cy=\"12\" r=\"10\"/><polygon points=\"16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76\"/>",
        "globe": "<circle cx=\"12\" cy=\"12\" r=\"10\"/><path d=\"M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20\"/><path d=\"M2 12h20\"/>",
        "download": "<path d=\"M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4\"/><polyline points=\"7 10 12 15 17 10\"/><line x1=\"12\" x2=\"12\" y1=\"15\" y2=\"3\"/>",
        "inbox": "<polyline points=\"22 12 16 12 14 15 10 15 8 12 2 12\"/><path d=\"M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z\"/>",
        "settings": "<path d=\"M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z\"/><circle cx=\"12\" cy=\"12\" r=\"3\"/>",
        "search": "<circle cx=\"11\" cy=\"11\" r=\"8\"/><line x1=\"21\" x2=\"16.65\" y1=\"21\" y2=\"16.65\"/>",
        "refresh-cw": "<path d=\"M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8\"/><path d=\"M21 3v5h-5\"/><path d=\"M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16\"/><path d=\"M8 16H3v5\"/>",
        "chevron-left": "<polyline points=\"15 18 9 12 15 6\"/>",
        "chevron-right": "<polyline points=\"9 18 15 12 9 6\"/>",
        "chevron-down": "<polyline points=\"6 9 12 15 18 9\"/>",
        "trash-2": "<path d=\"M3 6h18\"/><path d=\"M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6\"/><path d=\"M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2\"/><line x1=\"10\" x2=\"10\" y1=\"11\" y2=\"17\"/><line x1=\"14\" x2=\"14\" y1=\"11\" y2=\"17\"/>",
        "plus": "<line x1=\"12\" y1=\"5\" x2=\"12\" y2=\"19\"/><line x1=\"5\" y1=\"12\" x2=\"19\" y2=\"12\"/>",
        "minus": "<line x1=\"5\" y1=\"12\" x2=\"19\" y2=\"12\"/>",
        "zoom-in": "<circle cx=\"11\" cy=\"11\" r=\"8\"/><line x1=\"21\" x2=\"16.65\" y1=\"21\" y2=\"16.65\"/><line x1=\"11\" x2=\"11\" y1=\"8\" y2=\"14\"/><line x1=\"8\" x2=\"14\" y1=\"11\" y2=\"11\"/>",
        "zoom-out": "<circle cx=\"11\" cy=\"11\" r=\"8\"/><line x1=\"21\" x2=\"16.65\" y1=\"21\" y2=\"16.65\"/><line x1=\"8\" x2=\"14\" y1=\"11\" y2=\"11\"/>",
        "check": "<polyline points=\"20 6 9 17 4 12\"/>",
        "zap": "<polygon points=\"13 2 3 14 12 14 11 22 21 10 12 10 13 2\"/>",
        "folder": "<path d=\"M4 20h16a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.93a2 2 0 0 1-1.66-.9l-.82-1.2A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13c0 1.1.9 2 2 2Z\"/>",
        "external-link": "<path d=\"M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6\"/><polyline points=\"15 3 21 3 21 9\"/><line x1=\"10\" x2=\"21\" y1=\"14\" y2=\"3\"/>",
        "sun": "<circle cx=\"12\" cy=\"12\" r=\"4\"/><path d=\"M12 2v2\"/><path d=\"M12 20v2\"/><path d=\"m4.93 4.93 1.41 1.41\"/><path d=\"m17.66 17.66 1.41 1.41\"/><path d=\"M2 12h2\"/><path d=\"M20 12h2\"/><path d=\"m6.34 17.66-1.41 1.41\"/><path d=\"m19.07 4.93-1.41 1.41\"/>",
        "moon": "<path d=\"M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z\"/>",
        "snowflake": "<line x1=\"2\" x2=\"22\" y1=\"12\" y2=\"12\"/><line x1=\"12\" x2=\"12\" y1=\"2\" y2=\"22\"/><path d=\"m20 16-4-4 4-4\"/><path d=\"m4 8 4 4-4 4\"/><path d=\"m16 4-4 4-4-4\"/><path d=\"m8 20 4-4 4 4\"/>",
        "x": "<line x1=\"18\" x2=\"6\" y1=\"6\" y2=\"18\"/><line x1=\"6\" x2=\"18\" y1=\"6\" y2=\"18\"/>",
        "rotate-ccw": "<path d=\"M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8\"/><path d=\"M3 3v5h5\"/>",
        "file-text": "<path d=\"M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z\"/><polyline points=\"14 2 14 8 20 8\"/><line x1=\"16\" x2=\"8\" y1=\"13\" y2=\"13\"/><line x1=\"16\" x2=\"8\" y1=\"17\" y2=\"17\"/><polyline points=\"10 9 9 9 8 9\"/>",
        "code": "<polyline points=\"16 18 22 12 16 6\"/><polyline points=\"8 6 2 12 8 18\"/>",
        "box": "<path d=\"M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z\"/><path d=\"m3.3 7 8.7 5 8.7-5\"/><path d=\"M12 22V12\"/>",
        "library": "<path d=\"m16 6 4 14\"/><path d=\"M12 6v14\"/><path d=\"M8 8v12\"/><path d=\"M4 4v16\"/>",
        "sparkles": "<path d=\"m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z\"/>",
        "layers": "<path d=\"m12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83Z\"/><path d=\"m22 17.65-9.17 4.16a2 2 0 0 1-1.66 0L2 17.65\"/><path d=\"m22 12.65-9.17 4.16a2 2 0 0 1-1.66 0L2 12.65\"/>"
    })

    Image {
        id: iconImg
        anchors.fill: parent
        sourceSize.width: root.size
        sourceSize.height: root.size
        smooth: true
        source: {
            var path = root.iconPaths[root.name] || root.iconPaths["file-text"]
            var hex = root.color.toString()
            var svg = "<svg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='" + hex + "' stroke-width='" + root.strokeWidth + "' stroke-linecap='round' stroke-linejoin='round'>" + path + "</svg>"
            return "data:image/svg+xml;utf8," + encodeURIComponent(svg)
        }
    }
}
