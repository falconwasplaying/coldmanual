pragma Singleton
import QtQuick

QtObject {
    id: theme

    // Active Theme State
    readonly property bool isDark: (typeof settingsMgr !== "undefined") ? (settingsMgr.themeMode !== "light") : true

    // App Branding Icons
    readonly property string logoUrl: isDark ? "qrc:/resources/cmw.svg" : "qrc:/resources/cmb.svg"
    readonly property string appIconUrl: "qrc:/resources/cmi.svg"

    // ==========================================
    // MATERIAL DESIGN 3: COLOR SYSTEM
    // Classic Pixel Blue Key / Seed Palette
    // ==========================================

    // Primary Roles
    readonly property color primary: isDark ? "#a8c7fa" : "#0b57d0"
    readonly property color onPrimary: isDark ? "#062e6f" : "#ffffff"
    readonly property color primaryContainer: isDark ? "#004a77" : "#d3e3fd"
    readonly property color onPrimaryContainer: isDark ? "#c2e7ff" : "#041e49"
    readonly property color inversePrimary: isDark ? "#0b57d0" : "#a8c7fa"

    // Secondary Roles (Navigation Rail Indicator, Tonal Buttons, Filter Chips)
    readonly property color secondary: isDark ? "#bec6dc" : "#535f70"
    readonly property color onSecondary: isDark ? "#283141" : "#ffffff"
    readonly property color secondaryContainer: isDark ? "#004a77" : "#c2e7ff"
    readonly property color onSecondaryContainer: isDark ? "#c2e7ff" : "#001d35"

    // Tertiary Roles
    readonly property color tertiary: isDark ? "#efb8c8" : "#7d5260"
    readonly property color onTertiary: isDark ? "#492532" : "#ffffff"
    readonly property color tertiaryContainer: isDark ? "#492532" : "#ffd8e4"
    readonly property color onTertiaryContainer: isDark ? "#ffd8e4" : "#31111d"

    // Surface Container Hierarchy (M3 Tonal Elevation)
    readonly property color surface: isDark ? "#111318" : "#fdf8fd"
    readonly property color surfaceDim: isDark ? "#111318" : "#ded8e1"
    readonly property color surfaceBright: isDark ? "#37393e" : "#fdf8fd"
    readonly property color surfaceContainerLowest: isDark ? "#0c0e13" : "#ffffff"
    readonly property color surfaceContainerLow: isDark ? "#191c20" : "#f3f3f8"
    readonly property color surfaceContainer: isDark ? "#1d2024" : "#ededf2"
    readonly property color surfaceContainerHigh: isDark ? "#282a2f" : "#e7e8ed"
    readonly property color surfaceContainerHighest: isDark ? "#33353a" : "#e1e2e7"

    // Inverse Surfaces (Snackbars / Toasts)
    readonly property color inverseSurface: isDark ? "#e2e2e6" : "#2e3135"
    readonly property color inverseOnSurface: isDark ? "#2e3135" : "#f1f0f4"

    // Outline Roles
    readonly property color outline: isDark ? "#8c9199" : "#72777f"
    readonly property color outlineVariant: isDark ? "#42474e" : "#c2c7cf"

    // Typography & Content Roles
    readonly property color onSurface: isDark ? "#e2e2e6" : "#191c20"
    readonly property color onSurfaceVariant: isDark ? "#c2c7cf" : "#42474e"
    readonly property color textPrimary: onSurface
    readonly property color textSecondary: onSurfaceVariant
    readonly property color textMuted: outline
    readonly property color textOnAccent: onPrimary

    // Legacy Aliases for Seamless Backward Compatibility
    readonly property color background: surface
    readonly property color sidebarBg: surfaceContainerLow
    readonly property color surfaceElevated: surfaceContainerHigh
    readonly property color surfaceHover: surfaceContainerHighest
    readonly property color border: outlineVariant
    readonly property color borderFocus: primary
    readonly property color accent: primary
    readonly property color accentHover: isDark ? "#c2e7ff" : "#0842a0"
    readonly property color accentPressed: isDark ? "#7dadf8" : "#062e6f"
    readonly property color accentDim: secondaryContainer

    // Semantic Colors (M3 Error & Feedback)
    readonly property color danger: isDark ? "#f2b8b5" : "#b3261e"
    readonly property color dangerBg: isDark ? "#8c1d18" : "#f9dedc"
    readonly property color error: danger
    readonly property color onError: isDark ? "#601410" : "#ffffff"
    readonly property color errorContainer: dangerBg
    readonly property color onErrorContainer: isDark ? "#f9dedc" : "#410e0b"

    readonly property color success: isDark ? "#6dd58c" : "#198754"
    readonly property color successBg: isDark ? "#0d3b19" : "#c8f7d5"
    readonly property color warning: isDark ? "#f9cf58" : "#b26a00"
    readonly property color warningBg: isDark ? "#4a3000" : "#fff0c7"

    // Reader Styling
    readonly property color readerBg: isDark ? "#111318" : "#ffffff"
    readonly property color readerCodeBg: isDark ? "#1d2024" : "#f3f3f8"
    readonly property color readerBorder: surfaceContainerHighest

    // Fonts
    readonly property string fontSans: "Segoe UI, -apple-system, BlinkMacSystemFont, Roboto, sans-serif"
    readonly property string fontMono: "Cascadia Code, Consolas, Fira Code, monospace"

    // ==========================================
    // MATERIAL DESIGN 3: SHAPE SCALE
    // ==========================================
    readonly property int shapeNone: 0
    readonly property int shapeExtraSmall: 4
    readonly property int shapeSmall: 8
    readonly property int shapeMedium: 12
    readonly property int shapeLarge: 16
    readonly property int shapeExtraLarge: 28
    readonly property int shapeFull: 9999

    // Legacy radius aliases
    readonly property int radiusSm: shapeSmall
    readonly property int radiusMd: shapeMedium
    readonly property int radiusLg: shapeLarge
    readonly property int radiusXl: shapeExtraLarge
    readonly property int radiusPill: shapeFull

    // Spacing
    readonly property int spacingSm: 6
    readonly property int spacingMd: 12
    readonly property int spacingLg: 20
    readonly property int spacingXl: 28

    // State Layer Opacities
    readonly property real stateHover: 0.08
    readonly property real stateFocus: 0.12
    readonly property real statePress: 0.12
    readonly property real stateDrag: 0.16

    // Motion & Animation Constants (M3 Emphasized / Decelerated Curves)
    readonly property int animDurationFast: 120
    readonly property int animDurationNormal: 220
    readonly property int animDurationSlow: 350
    readonly property int animEasingDecel: Easing.OutCubic
    readonly property int animEasingAccel: Easing.InQuad
}
