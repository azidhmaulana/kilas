import QtQuick
import QtQuick.Effects
import Kilas

// The Liquid Glass surface used by the island at every state.
//
// IMPORTANT (see the liquid-glass-ui skill): this is a GPU-SHADER
// SIMULATION of a frosted-glass material — a tint gradient, a blurred
// ambient glow, and a lit border — rendered entirely inside this Qt
// Quick window. It does NOT blur the real desktop behind the window:
// Qt Quick has no access to the pixels of other applications, so true
// backdrop blur only exists if a native OS compositor API (Windows DWM
// Mica/Acrylic, macOS NSVisualEffectView, a Linux compositor's
// blur-behind hint) is layered in separately at the native window
// level. That native layer is NOT implemented in this prototype — see
// CLAUDE.md and the liquid-glass-ui skill for why, and treat this
// component as the honest, portable fallback that must look right on
// every platform on its own.
Item {
    id: root

    property bool enabled: true
    property real hoverProgress: 0 // 0..1, driven by the island's hover state
    property real cornerRadius: Theme.radiusPanel
    property color tint: Theme.glassSurface
    property real fillAlpha: Theme.glassFillAlpha
    property bool dropHighlight: false

    Behavior on cornerRadius {
        NumberAnimation { duration: MotionTokens.expandDuration; easing.type: Easing.OutCubic }
    }

    // Soft ambient glow blob, genuinely GPU-blurred via MultiEffect.
    // This is the one place real GPU blur work happens in this
    // component — it blurs an in-scene light source, not the desktop.
    // `hideSource: true` is the documented Qt Quick idiom for "capture
    // this item into a texture but don't also paint it directly" —
    // simply setting the source item's `visible: false` is NOT
    // equivalent and can leave MultiEffect with nothing to sample.
    Item {
        id: glowSourceItem
        anchors.fill: parent

        Rectangle {
            width: root.width * 0.6
            height: root.height * 0.9
            radius: width / 2
            x: root.width * 0.15 + root.hoverProgress * root.width * 0.1
            y: -height * 0.3
            color: Qt.lighter(root.tint, 1.6 + root.hoverProgress * 0.4)
            opacity: 0.55
        }
    }

    // PERFORMANCE (Phase 1/4 finding): `live: true` here was a real bug
    // — it forced this offscreen texture to be fully re-rendered on
    // *every single frame, forever*, even while the island sat
    // perfectly still (confirmed via QSG_RENDER_TIMING: the render
    // thread was ticking every ~16ms at idle with nothing animating).
    // `live: false` + an explicit `scheduleUpdate()` whenever something
    // that actually changes the glow's appearance changes (hover
    // progress, or the island's own size during expand/collapse) gives
    // the same visual result but renders this texture only when it
    // genuinely needs to, and goes fully idle the instant nothing is
    // moving.
    ShaderEffectSource {
        id: glowTexture
        sourceItem: glowSourceItem
        hideSource: true
        live: false
        smooth: true
    }

    onHoverProgressChanged: glowTexture.scheduleUpdate()
    onWidthChanged: glowTexture.scheduleUpdate()
    onHeightChanged: glowTexture.scheduleUpdate()

    // PERFORMANCE: `blurEnabled`/`blurMax` stay constant for the whole
    // app lifetime — only the numeric `brightness`/`saturation` uniforms
    // vary with hover. Toggling boolean effect features (blurEnabled,
    // shadowEnabled, maskEnabled, ...) forces MultiEffect to swap to a
    // different compiled shader variant mid-animation, which is the
    // expensive thing to avoid; adjusting a float uniform on an
    // already-compiled variant is cheap and does not recompile anything.
    // `autoPaddingEnabled: false` keeps the blur's render target pinned
    // to the item's exact bounds instead of auto-growing it — smaller,
    // predictable effect surface (Phase 4: "restrict expensive effects
    // to the smallest practical surface").
    MultiEffect {
        anchors.fill: parent
        source: glowTexture
        visible: root.enabled
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        brightness: 0.05 + root.hoverProgress * 0.05
        saturation: 0.05
    }

    // Base frosted tint — vertical gradient reads better as "glass"
    // than a flat fill, and remains legible without the blur layer if
    // `enabled` is turned off (the low-power / reduced-transparency
    // fallback).
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, root.fillAlpha + 0.08) }
            GradientStop { position: 1.0; color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, root.fillAlpha - 0.06) }
        }
    }

    // Edge lighting — brighter along the top edge, as if lit from above.
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.14 + root.hoverProgress * 0.18)

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: parent.height * 0.5
            radius: root.cornerRadius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.borderHighlight }
                GradientStop { position: 1.0; color: "transparent" }
            }
            opacity: 0.22 + root.hoverProgress * 0.2
        }
    }

    // Drop-target reaction border (Animation 5 — Magnetic Drop Zone).
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: "transparent"
        border.width: 2
        border.color: Theme.accent
        opacity: root.dropHighlight ? 0.85 : 0
        // Opacity is one of the five properties QQuickItem's render
        // thread can animate without GUI-thread involvement each frame
        // — see the motion-design skill. Same pattern applied below for
        // the collapsed/hover/expanded content fades.
        Behavior on opacity { OpacityAnimator { duration: MotionTokens.hoverDuration } }
    }
}
