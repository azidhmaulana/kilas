pragma Singleton
import QtQuick

// Reusable motion tokens for KILAS (see the motion-design skill).
// Every animation in the app should pull its duration/easing from here
// rather than hardcoding numbers inline — keeps the whole island feeling
// like one coordinated motion system instead of per-component guesses.
//
// Plain `property`, not `readonly property` — see the comment in
// Theme.qml for why: `readonly` on a singleton let the compiler fold
// these into constants that raced with other files' first-frame
// bindings at startup.
QtObject {
    // Animation 1 — Elastic Morph (expand/collapse)
    property int expandDuration: 320
    property int collapseDuration: 230
    property int expandEasingType: Easing.OutBack
    property real expandEasingOvershoot: 1.08
    property int collapseEasingType: Easing.OutCubic

    // Content inside the island should start fading/sliding in slightly
    // *after* the geometry morph begins (Phase 3: "content appears
    // slightly after expansion begins").
    property int contentRevealDelay: 90
    property int contentRevealDuration: 180

    // Animation 2 — Glass Hover
    property int hoverDuration: 170
    property int hoverEasingType: Easing.OutQuad

    // Animation 6 — Panel Transitions
    property int panelDuration: 200
    property int panelEasingType: Easing.OutCubic

    // Animation 4 — Notification Morph
    property int notificationHoldMs: 2600
    property int notificationMorphDuration: 260

    // Animation 5 — Magnetic Drop Zone
    property int dropPulseDuration: 420

    // Waveform re-sample interval while "playing" (Animation 3)
    property int waveformSampleIntervalMs: 90
    property int waveformSettleDuration: 220
}
