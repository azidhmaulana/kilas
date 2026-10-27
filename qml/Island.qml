import QtQuick
import Kilas

// The floating Dynamic Island itself. Its width/height animate freely
// as a normal scene graph resize — the host window (Main.qml) no
// longer tracks this live, frame-by-frame; it snaps to one of two
// fixed sizes instead (see Main.qml's "stable window" comment for why:
// a native window resize on every frame was the main source of
// stutter). True per-pixel click-through still isn't implemented here
// — see the desktop-windowing skill and CLAUDE.md for that trade-off.
Item {
    id: root

    readonly property int collapsedWidth: 170
    readonly property int collapsedHeight: 38
    readonly property int hoverWidth: 240
    readonly property int hoverHeight: 44
    readonly property int expandedWidth: 400
    readonly property int expandedHeight: 290
    readonly property int notificationWidth: 320
    readonly property int notificationHeight: 72

    property real hoverProgress: 0

    width: collapsedWidth
    height: collapsedHeight

    Behavior on hoverProgress {
        NumberAnimation { duration: MotionTokens.hoverDuration; easing.type: MotionTokens.hoverEasingType }
    }

    state: DemoState.islandState

    states: [
        State {
            name: "collapsed"
            PropertyChanges { target: root; width: root.collapsedWidth; height: root.collapsedHeight; hoverProgress: 0 }
        },
        State {
            name: "hover"
            PropertyChanges { target: root; width: root.hoverWidth; height: root.hoverHeight; hoverProgress: 1 }
        },
        State {
            name: "expanded"
            PropertyChanges { target: root; width: root.expandedWidth; height: root.expandedHeight; hoverProgress: 1 }
        },
        State {
            name: "notification"
            PropertyChanges { target: root; width: root.notificationWidth; height: root.notificationHeight; hoverProgress: 0.6 }
        }
    ]

    transitions: [
        Transition {
            to: "expanded"
            NumberAnimation {
                properties: "width,height"
                duration: DemoState.animationsEnabled ? MotionTokens.expandDuration : 0
                easing.type: MotionTokens.expandEasingType
                easing.overshoot: MotionTokens.expandEasingOvershoot
            }
        },
        Transition {
            to: "collapsed"
            NumberAnimation {
                properties: "width,height"
                duration: DemoState.animationsEnabled ? MotionTokens.collapseDuration : 0
                easing.type: MotionTokens.collapseEasingType
            }
        },
        Transition {
            NumberAnimation {
                properties: "width,height"
                duration: DemoState.animationsEnabled ? MotionTokens.hoverDuration : 0
                easing.type: MotionTokens.hoverEasingType
            }
        }
    ]

    // Synthetic contrast-test backdrop (DemoController "Contrast test
    // backdrop" controls) — a flat swatch drawn behind the glass purely
    // for legibility checks. This is NOT a real desktop wallpaper swap;
    // see the visual-qa skill for the manual cross-wallpaper QA step.
    Rectangle {
        anchors.centerIn: parent
        width: parent.width + 120
        height: parent.height + 120
        radius: 24
        z: -1
        visible: DemoState.debugBackdrop !== "none"
        color: DemoState.debugBackdrop === "dark" ? "#05060A" : "#F2F3F7"
    }

    GlassSurface {
        id: glass
        anchors.fill: parent
        enabled: DemoState.glassEnabled
        hoverProgress: root.hoverProgress
        dropHighlight: DemoState.dropActive
        cornerRadius: (root.state === "expanded") ? Theme.radiusPanel : root.height / 2
    }

    // --- Collapsed / hover content -----------------------------------
    Item {
        anchors.fill: parent
        visible: root.state === "collapsed" || root.state === "hover"
        opacity: visible ? 1 : 0
        Behavior on opacity { OpacityAnimator { duration: MotionTokens.hoverDuration } }

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingSm

            Text {
                text: "KILAS"
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                font.letterSpacing: 1
                anchors.verticalCenter: parent.verticalCenter
            }
            Waveform {
                active: DemoState.isPlaying
                barCount: 5
                maxHeight: 10
                minHeight: 2
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // --- Expanded content: tab row + panel switcher -------------------
    Item {
        id: expandedContent
        anchors.fill: parent
        visible: root.state === "expanded"
        opacity: visible ? 1 : 0
        // Phase 5 — "content appears slightly after expansion begins":
        // only pause-then-fade-in when *entering* expanded (root.state
        // already reflects the new/target state here); leaving fades
        // out immediately alongside the shrink, which reads as natural
        // rather than delayed.
        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: root.state === "expanded" ? MotionTokens.contentRevealDelay : 0 }
                OpacityAnimator { duration: MotionTokens.contentRevealDuration; easing.type: Easing.OutCubic }
            }
        }

        Row {
            id: tabRow
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: Theme.spacingSm }
            height: 26
            spacing: Theme.spacingXs

            QuickAction {
                glyph: "⌂"
                label: "Home"
                highlighted: DemoState.currentPanel === "home"
                onClicked: DemoState.currentPanel = "home"
            }
            QuickAction {
                glyph: "♪"
                label: "Music"
                highlighted: DemoState.currentPanel === "music"
                onClicked: DemoState.currentPanel = "music"
            }
            QuickAction {
                glyph: "⚙"
                label: "Tools"
                highlighted: DemoState.currentPanel === "tools"
                onClicked: DemoState.currentPanel = "tools"
            }
        }

        // Three panels laid out side by side; only `currentIndex` is
        // ever fully opaque and on-screen — switching slides+crossfades
        // between them (Animation 6 — Panel Transitions).
        Item {
            id: panelHost
            anchors { top: tabRow.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; topMargin: Theme.spacingXs }
            clip: true

            readonly property var panelOrder: ["home", "music", "tools"]
            readonly property int currentIndex: panelOrder.indexOf(DemoState.currentPanel)
            readonly property int panelDuration: DemoState.animationsEnabled ? MotionTokens.panelDuration : 0

            // x and opacity are both render-thread Animator-eligible
            // (see motion-design skill) — three panels sliding/fading in
            // parallel on every switch is exactly the kind of thing that
            // benefits from staying off the GUI thread.
            HomePanel {
                width: panelHost.width
                height: panelHost.height
                x: (0 - panelHost.currentIndex) * panelHost.width
                opacity: panelHost.currentIndex === 0 ? 1 : 0
                Behavior on x { XAnimator { duration: panelHost.panelDuration; easing.type: MotionTokens.panelEasingType } }
                Behavior on opacity { OpacityAnimator { duration: panelHost.panelDuration } }
                onCollapseRequested: DemoState.islandState = "collapsed"
            }
            MusicPanel {
                width: panelHost.width
                height: panelHost.height
                x: (1 - panelHost.currentIndex) * panelHost.width
                opacity: panelHost.currentIndex === 1 ? 1 : 0
                Behavior on x { XAnimator { duration: panelHost.panelDuration; easing.type: MotionTokens.panelEasingType } }
                Behavior on opacity { OpacityAnimator { duration: panelHost.panelDuration } }
            }
            ToolsPanel {
                width: panelHost.width
                height: panelHost.height
                x: (2 - panelHost.currentIndex) * panelHost.width
                opacity: panelHost.currentIndex === 2 ? 1 : 0
                Behavior on x { XAnimator { duration: panelHost.panelDuration; easing.type: MotionTokens.panelEasingType } }
                Behavior on opacity { OpacityAnimator { duration: panelHost.panelDuration } }
            }
        }
    }

    // --- Notification content ------------------------------------------
    NotificationPill {
        anchors.fill: parent
        visible: root.state === "notification"
        text: DemoState.notificationText
    }

    // --- Interaction -----------------------------------------------------
    // Only hit-testable while collapsed/hovering: once expanded, the
    // tab row and panel buttons underneath need real clicks, and this
    // being declared last (topmost in paint/input order) would otherwise
    // swallow every one of them. Collapsing back down happens via
    // HomePanel's explicit collapse button instead of "click anywhere".
    MouseArea {
        anchors.fill: parent
        enabled: root.state === "collapsed" || root.state === "hover"
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: if (root.state === "collapsed") DemoState.islandState = "hover"
        onExited: if (root.state === "hover") DemoState.islandState = "collapsed"
        onClicked: DemoState.islandState = "expanded"
    }

    // --- Magnetic Drop Zone (Animation 5) -------------------------------
    DropArea {
        anchors.fill: parent
        keys: ["text/uri-list"]
        onEntered: {
            DemoState.dropActive = true
            if (root.state === "collapsed" || root.state === "hover") {
                DemoState.restoreState = root.state
                DemoState.currentPanel = "tools"
                DemoState.islandState = "expanded"
            }
        }
        onExited: DemoState.dropActive = false
        onDropped: function(drop) {
            DemoState.dropActive = false
            // Both branches emit DemoState.fileDropDemoRequested()
            // internally — don't emit it again here.
            if (drop.hasUrls)
                DemoState.registerDroppedUrls(drop.urls)
            else
                DemoState.simulateFileDrop()
        }
    }

    // --- Notification Morph (Animation 4) -------------------------------
    Connections {
        target: DemoState
        function onNotificationRequested() {
            if (root.state !== "notification") {
                DemoState.restoreState = root.state
                DemoState.islandState = "notification"
                notificationTimer.restart()
            }
        }
    }

    Timer {
        id: notificationTimer
        interval: MotionTokens.notificationHoldMs
        onTriggered: DemoState.islandState = DemoState.restoreState
    }
}
