import QtQuick
import Kilas

// Simulated audio-reactive waveform (Animation 3). Mock data only — no
// real audio analysis. Bar target heights are re-sampled on a timer and
// each bar eases to its new target via Behavior, rather than being
// mutated every frame from JS — see the motion-design skill on why a
// periodic-resample + Behavior pattern is preferred over a per-frame
// JS-driven animation loop.
Row {
    id: root

    property bool active: false
    property int barCount: 18
    property real minHeight: 3
    property real maxHeight: 16
    property color barColor: Theme.accent

    spacing: 3

    Repeater {
        id: repeater
        model: root.barCount

        Rectangle {
            required property int index
            width: 2
            radius: 1
            color: root.barColor
            opacity: root.active ? 0.9 : 0.35
            anchors.verticalCenter: parent.verticalCenter
            height: root.minHeight

            Behavior on height {
                NumberAnimation {
                    duration: MotionTokens.waveformSettleDuration
                    easing.type: Easing.OutQuad
                }
            }
            Behavior on opacity {
                OpacityAnimator { duration: MotionTokens.hoverDuration }
            }
        }
    }

    Timer {
        interval: MotionTokens.waveformSampleIntervalMs
        running: root.active
        repeat: true
        onTriggered: {
            for (var i = 0; i < repeater.count; ++i) {
                var bar = repeater.itemAt(i)
                if (bar)
                    bar.height = root.minHeight + Math.random() * (root.maxHeight - root.minHeight)
            }
        }
    }

    onActiveChanged: {
        if (!active) {
            for (var i = 0; i < repeater.count; ++i) {
                var bar = repeater.itemAt(i)
                if (bar)
                    bar.height = root.minHeight
            }
        }
    }
}
