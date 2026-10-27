import QtQuick
import Kilas

// Content shown while the island is in its "notification" state
// (Animation 4 — Notification Morph). Demo-only: no real OS notification
// integration, per the scope limits in CLAUDE.md.
Item {
    id: root
    anchors.fill: parent

    property string text: ""

    Row {
        anchors.centerIn: parent
        spacing: Theme.spacingMd

        Rectangle {
            id: iconBadge
            width: 24; height: 24
            radius: width / 2
            color: Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.22)
            anchors.verticalCenter: parent.verticalCenter

            opacity: 0
            scale: 0.6
            Component.onCompleted: {
                opacity = 1
                scale = 1
            }
            Behavior on opacity { OpacityAnimator { duration: MotionTokens.notificationMorphDuration; easing.type: Easing.OutCubic } }
            Behavior on scale { ScaleAnimator { duration: MotionTokens.notificationMorphDuration; easing.type: Easing.OutBack } }

            Text {
                anchors.centerIn: parent
                text: "✓"
                color: Theme.success
                font.pixelSize: Theme.fontSizeBody
                font.bold: true
            }
        }

        Text {
            text: root.text
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeBody
            anchors.verticalCenter: parent.verticalCenter

            opacity: 0
            Component.onCompleted: opacity = 1
            Behavior on opacity {
                OpacityAnimator {
                    duration: MotionTokens.notificationMorphDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
