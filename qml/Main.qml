import QtQuick
import QtQuick.Window
import Kilas

// The island's real OS window: frameless, transparent, always-on-top.
//
// PERFORMANCE (see the desktop-windowing / motion-design skills and
// CLAUDE.md "Stable window geometry"): this used to bind width/height
// directly to Island's live, animated size — "Approach A" (native
// geometry animation), which meant every frame of the expand/collapse
// animation triggered a REAL native window resize (DWM round trip +
// backing-store/swapchain reallocation on Windows), not just a scene
// graph update. That was the dominant cause of stutter and resize
// flicker. This now uses "Approach B" (stable window surface): the
// native window snaps ONCE, unanimated, to whichever of two fixed
// sizes covers the current family of states, and `Island` animates its
// own width/height *inside* that stable window — a pure scene graph
// resize, which the threaded render loop handles smoothly.
//
// Trade-off, disclosed rather than hidden: while non-collapsed (hover/
// expanded/notification), the native window is sized for the largest
// state (expanded) even if the content is currently smaller (e.g. just
// hovering) — so the invisible, click-blocking margin around the glass
// shape is a little more generous during active interaction than the
// tight-fit approach this project started with. It snaps back down to
// the tight collapsed size as soon as the collapse animation visually
// finishes, so the common idle state (collapsed) still has a minimal
// footprint. See README "Known, disclosed limitations".
//
// Known, disclosed limitation: on compositor-less Linux setups,
// `color: "transparent"` on a frameless window can fall back to an
// opaque black backing surface instead of true transparency — this is
// a platform/compositor limitation, not a bug in this QML, and is not
// verified fixed here since this environment has no Linux display to
// test against (see the final verification report).
Window {
    id: islandWindow

    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"
    visible: true
    title: "KILAS"

    readonly property int compactWidth: island.collapsedWidth
    readonly property int compactHeight: island.collapsedHeight
    // +16 is rounding/antialiasing headroom, not a blur-bleed margin —
    // GlassSurface's glow MultiEffect has autoPaddingEnabled explicitly
    // off, so nothing paints outside the island's nominal size.
    readonly property int stableWidth: island.expandedWidth + 16
    readonly property int stableHeight: island.expandedHeight + 16

    // True the instant a transition AWAY from "collapsed" starts (so
    // the window is already big enough before the content starts
    // growing into it — no mid-grow clipping). Only goes back to true
    // once a transition INTO "collapsed" has had time to fully finish
    // shrinking — never at the start of it, or the window would clip
    // the glass shape while it's still visually large.
    property bool windowIsCompact: true

    Connections {
        target: DemoState
        function onIslandStateChanged() {
            if (DemoState.islandState === "collapsed") {
                collapseSettle.restart()
            } else {
                collapseSettle.stop()
                islandWindow.windowIsCompact = false
            }
        }
    }

    Timer {
        id: collapseSettle
        // Covers both the "collapsed" and "hover" shrink-transition
        // durations with a small safety margin — worst case the window
        // stays a little larger than strictly necessary for ~60ms after
        // a quick hover-cancel, never shrinks early into visible content.
        interval: Math.max(MotionTokens.collapseDuration, MotionTokens.hoverDuration) + 60
        onTriggered: islandWindow.windowIsCompact = true
    }

    width: windowIsCompact ? compactWidth : stableWidth
    height: windowIsCompact ? compactHeight : stableHeight

    x: Math.round((Screen.width - width) / 2)
    y: 14

    Island {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
    }

    DemoController {}
}
