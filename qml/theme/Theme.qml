pragma Singleton
import QtQuick

// KILAS color & geometry tokens — see CLAUDE.md "Motion and glass
// specifications" for the source-of-truth design spec. Keep every
// color/radius/spacing value used across the app behind this singleton
// so the palette can be re-tuned from one place.
//
// Properties here are plain `property`, not `readonly property`: with
// `readonly`, Qt 6.8's QML compiler constant-folds/inlines the value,
// and in this project that raced with other files' first-frame
// bindings reading this singleton before it had finished constructing
// (observed as one-shot "Cannot read property 'r' of undefined" at
// startup that then never recovered, since a folded constant never
// fires a later change notification to re-trigger the binding). Plain
// properties go through the normal binding/notify path instead.
QtObject {
    property color backgroundDark: "#10131B"
    property color glassSurface: "#202838"
    property color accent: "#A6B4FF"
    property color textPrimary: "#F5F7FF"
    property color textSecondary: "#A5AEC3"
    property color borderHighlight: Qt.rgba(1, 1, 1, 0.30)

    property color danger: "#FF8A8A"
    property color success: "#8AFFC1"

    property real glassFillAlpha: 0.46
    property real glassFillAlphaLow: 0.30

    property int radiusPill: 19
    property int radiusPanel: 24
    property int radiusCard: 14

    property int spacingXs: 4
    property int spacingSm: 8
    property int spacingMd: 14
    property int spacingLg: 20

    property int fontSizeSmall: 11
    property int fontSizeBody: 13
    property int fontSizeTitle: 15
}
