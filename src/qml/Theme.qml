pragma Singleton
import QtQuick

QtObject {
    id: theme

    // Colors
    readonly property bool isDark: (typeof settingsMgr !== "undefined") ? (settingsMgr.themeMode !== "light") : true

    readonly property color background: isDark ? "#121214" : "#f8fafc"
    readonly property color sidebarBg: isDark ? "#18181b" : "#f1f5f9"
    readonly property color surface: isDark ? "#202024" : "#ffffff"
    readonly property color surfaceElevated: isDark ? "#27272a" : "#ffffff"
    readonly property color surfaceHover: isDark ? "#2e2e33" : "#e2e8f0"
    readonly property color border: isDark ? "#2e2e33" : "#e2e8f0"
    readonly property color borderFocus: isDark ? "#38bdf8" : "#0284c7"

    // Accents
    readonly property color accent: isDark ? "#38bdf8" : "#0284c7"
    readonly property color accentHover: isDark ? "#7dd3fc" : "#0369a1"
    readonly property color accentPressed: isDark ? "#0284c7" : "#075985"
    readonly property color accentDim: isDark ? "#1e3a5f" : "#e0f2fe"

    // Semantic Colors
    readonly property color success: "#22c55e"
    readonly property color successBg: isDark ? "#14532d" : "#dcfce7"
    readonly property color warning: "#eab308"
    readonly property color warningBg: isDark ? "#713f12" : "#fef9c3"
    readonly property color danger: "#ef4444"
    readonly property color dangerBg: isDark ? "#7f1d1d" : "#fee2e2"

    // Typography
    readonly property color textPrimary: isDark ? "#f4f4f5" : "#0f172a"
    readonly property color textSecondary: isDark ? "#a1a1aa" : "#475569"
    readonly property color textMuted: isDark ? "#71717a" : "#94a3b8"
    readonly property color textOnAccent: "#ffffff"

    // Reader styling
    readonly property color readerBg: isDark ? "#141416" : "#ffffff"
    readonly property color readerCodeBg: isDark ? "#1a1a1e" : "#f1f5f9"
    readonly property color readerBorder: isDark ? "#27272a" : "#e2e8f0"

    // Fonts
    readonly property string fontSans: "Segoe UI, -apple-system, BlinkMacSystemFont, Roboto, sans-serif"
    readonly property string fontMono: "Cascadia Code, Consolas, Fira Code, monospace"

    // Radii & Padding
    readonly property int radiusSm: 4
    readonly property int radiusMd: 8
    readonly property int radiusLg: 12
    readonly property int spacingSm: 6
    readonly property int spacingMd: 12
    readonly property int spacingLg: 20

    // Motion & Animation Constants
    readonly property int animDurationFast: 110
    readonly property int animDurationNormal: 180
    readonly property int animDurationSlow: 260
    readonly property int animEasingDecel: Easing.OutCubic
    readonly property int animEasingAccel: Easing.InQuad
}
