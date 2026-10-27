import QtQuick
import Kilas

// Mock Quick Tools cards: Clipboard (static mock data), Focus Timer
// (real C++ backend via AppController), File Shelf (the drop target for
// Animation 5 — Magnetic Drop Zone). No real clipboard access, no file
// persistence — see CLAUDE.md scope limits.
Item {
    id: root

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingSm

        Text {
            text: "Quick Tools"
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSizeSmall
        }

        // --- Clipboard (mock) ---
        Rectangle {
            width: parent.width
            height: 54
            radius: Theme.radiusCard
            color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingSm
                spacing: 2

                Text { text: "Clipboard"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeBody; font.bold: true }
                Text { text: "“KILAS demo build” · “168 Collins St”"; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeSmall; elide: Text.ElideRight; width: parent.width }
            }
        }

        // --- Focus Timer (real C++ backend) ---
        Rectangle {
            width: parent.width
            height: 54
            radius: Theme.radiusCard
            color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            Row {
                anchors.fill: parent
                anchors.margins: Theme.spacingSm

                Column {
                    width: parent.width - 80
                    spacing: 2
                    Text { text: "Focus Timer"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeBody; font.bold: true }
                    Text {
                        text: AppController.focusTimerRunning
                              ? (Math.floor(AppController.focusSecondsRemaining / 60) + ":" + String(AppController.focusSecondsRemaining % 60).padStart(2, "0") + " remaining")
                              : "25 min session"
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }

                QuickAction {
                    glyph: AppController.focusTimerRunning ? "⏹" : "▶"
                    highlighted: AppController.focusTimerRunning
                    onClicked: AppController.focusTimerRunning
                               ? AppController.stopFocusTimer()
                               : AppController.startFocusTimer(25)
                }
            }
        }

        // --- File Shelf (drop target) ---
        Rectangle {
            id: shelf
            width: parent.width
            height: 70
            radius: Theme.radiusCard
            color: DemoState.dropActive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                                         : Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            border.color: DemoState.dropActive ? Theme.accent : Qt.rgba(1, 1, 1, 0.08)
            Behavior on color { ColorAnimation { duration: MotionTokens.hoverDuration } }
            Behavior on border.color { ColorAnimation { duration: MotionTokens.hoverDuration } }

            scale: shelfPulse.running ? 1.03 : 1.0
            Behavior on scale { ScaleAnimator { duration: MotionTokens.dropPulseDuration; easing.type: Easing.OutElastic } }

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingSm
                spacing: 2

                Row {
                    spacing: Theme.spacingSm
                    Text {
                        text: "⬇"
                        color: Theme.accent
                        font.pixelSize: Theme.fontSizeBody
                        scale: DemoState.dropActive ? 1.3 : 1.0
                        Behavior on scale { ScaleAnimator { duration: MotionTokens.hoverDuration; easing.type: Easing.OutBack } }
                    }
                    Text { text: "File Shelf"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeBody; font.bold: true }
                }
                Text {
                    text: DemoState.shelfCount === 0
                          ? "Drag a file onto the island to try it"
                          : DemoState.shelfCount + " file(s) added this session"
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSizeSmall
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            Timer {
                id: shelfPulse
                interval: MotionTokens.dropPulseDuration
                onTriggered: running = false
            }

            Connections {
                target: DemoState
                function onFileDropDemoRequested() { shelfPulse.restart() }
            }
        }
    }
}
