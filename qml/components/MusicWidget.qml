import QtQuick
import Kilas

// Mock mini music player (Animation 3). All playback state lives in
// DemoState — no real media backend, per CLAUDE.md's scope limits.
Item {
    id: root

    property bool compact: false
    implicitHeight: compact ? 44 : 150

    Row {
        id: layout
        anchors.fill: parent
        spacing: Theme.spacingMd

        Rectangle {
            id: artwork
            width: root.compact ? 32 : 96
            height: width
            radius: Theme.radiusCard
            anchors.verticalCenter: root.compact ? parent.verticalCenter : undefined
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.accent }
                GradientStop { position: 1.0; color: Theme.backgroundDark }
            }

            Text {
                anchors.centerIn: parent
                text: "♪"
                color: Theme.textPrimary
                font.pixelSize: root.compact ? 14 : 28
                opacity: 0.85
            }
        }

        Column {
            spacing: Theme.spacingSm
            anchors.verticalCenter: root.compact ? parent.verticalCenter : undefined
            width: layout.width - artwork.width - Theme.spacingMd

            Column {
                spacing: 1
                Text {
                    text: DemoState.currentTrack.title
                    color: Theme.textPrimary
                    font.pixelSize: root.compact ? Theme.fontSizeSmall : Theme.fontSizeTitle
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width
                }
                Text {
                    text: DemoState.currentTrack.artist
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSizeSmall
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            Waveform {
                active: DemoState.isPlaying
                barCount: root.compact ? 10 : 22
                maxHeight: root.compact ? 10 : 18
            }

            Row {
                visible: !root.compact
                spacing: Theme.spacingSm

                QuickAction {
                    glyph: "⏮"
                    onClicked: DemoState.previousTrack()
                }
                QuickAction {
                    glyph: DemoState.isPlaying ? "⏸" : "▶"
                    highlighted: true
                    onClicked: DemoState.togglePlayback()
                }
                QuickAction {
                    glyph: "⏭"
                    onClicked: DemoState.nextTrack()
                }
            }

            Rectangle {
                visible: !root.compact
                width: 180
                height: 3
                radius: 1.5
                color: Qt.rgba(1, 1, 1, 0.12)

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    color: Theme.accent
                    width: parent.width * Math.min(1, DemoState.playbackPosition / DemoState.currentTrack.duration)
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.Linear } }
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: DemoState.isPlaying && !root.compact
        repeat: true
        onTriggered: {
            if (DemoState.playbackPosition >= DemoState.currentTrack.duration)
                DemoState.nextTrack()
            else
                DemoState.playbackPosition += 1
        }
    }
}
