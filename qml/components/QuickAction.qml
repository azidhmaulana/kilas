import QtQuick
import Kilas

// Small reusable pill button used across panels (quick actions, panel
// switcher tabs, controller toggles). Always wired to a real `clicked`
// signal — per Phase 7's rule, nothing in this app should look
// clickable and do nothing.
Rectangle {
    id: root

    signal clicked()

    property string glyph: "•"
    property string label: ""
    property bool highlighted: false

    implicitWidth: row.implicitWidth + Theme.spacingLg
    implicitHeight: 30
    radius: Theme.radiusCard
    color: root.highlighted
           ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.28)
           : Qt.rgba(1, 1, 1, hover.hovered ? 0.10 : 0.05)

    Behavior on color { ColorAnimation { duration: MotionTokens.hoverDuration } }

    border.width: 1
    border.color: root.highlighted ? Theme.accent : Qt.rgba(1, 1, 1, 0.12)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacingXs

        Text {
            text: root.glyph
            color: root.highlighted ? Theme.accent : Theme.textSecondary
            font.pixelSize: Theme.fontSizeBody
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.label
            visible: text.length > 0
            color: root.highlighted ? Theme.textPrimary : Theme.textSecondary
            font.pixelSize: Theme.fontSizeSmall
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    scale: hover.pressed ? 0.96 : 1.0
    // Render-thread Animator: this is the highest-frequency animation
    // in the app (fires on every button press across every panel), so
    // keeping it off the GUI thread matters more than its small size
    // suggests — see the motion-design skill.
    Behavior on scale { ScaleAnimator { duration: 90; easing.type: Easing.OutQuad } }
}
