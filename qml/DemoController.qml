import QtQuick
import QtQuick.Window
import Kilas

// Phase 7 — Interactive Demo Controller. A plain, decorated, opaque
// window deliberately separate from the island so it never visually
// interferes with (or gets mistaken for part of) the Liquid Glass
// surface being evaluated. Every control here does something real and
// observable on the island — nothing is a placeholder.
Window {
    id: controller

    width: 300
    height: 560
    minimumWidth: 280
    minimumHeight: 480
    title: "KILAS — Demo Controller"
    color: Theme.backgroundDark
    visible: true

    x: Math.max(20, Screen.width - width - 40)
    y: Math.max(20, Screen.height - height - 80)

    Flickable {
        anchors.fill: parent
        anchors.margins: Theme.spacingLg
        contentHeight: content.implicitHeight
        clip: true

        Column {
            id: content
            width: parent.width
            spacing: Theme.spacingMd

            Text {
                text: "KILAS Demo Controller"
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeTitle
                font.bold: true
            }
            Text {
                text: "Drives the floating island for evaluation. Runtime: Qt "
                      + AppController.qtRuntimeVersion + " on " + AppController.platformName + "."
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
                width: parent.width
            }

            Section { title: "Island state" }
            Row {
                spacing: Theme.spacingSm
                QuickAction {
                    glyph: DemoState.islandState === "expanded" ? "↙" : "↗"
                    label: DemoState.islandState === "expanded" ? "Collapse" : "Expand"
                    highlighted: DemoState.islandState === "expanded"
                    onClicked: DemoState.islandState = (DemoState.islandState === "expanded") ? "collapsed" : "expanded"
                }
            }

            Section { title: "Panels" }
            Row {
                spacing: Theme.spacingSm
                QuickAction { glyph: "⌂"; label: "Home"; highlighted: DemoState.currentPanel === "home"; onClicked: { DemoState.islandState = "expanded"; DemoState.currentPanel = "home" } }
                QuickAction { glyph: "♪"; label: "Music"; highlighted: DemoState.currentPanel === "music"; onClicked: { DemoState.islandState = "expanded"; DemoState.currentPanel = "music" } }
                QuickAction { glyph: "⚙"; label: "Tools"; highlighted: DemoState.currentPanel === "tools"; onClicked: { DemoState.islandState = "expanded"; DemoState.currentPanel = "tools" } }
            }

            Section { title: "Music demo" }
            Row {
                spacing: Theme.spacingSm
                QuickAction {
                    glyph: DemoState.isPlaying ? "⏸" : "▶"
                    label: DemoState.isPlaying ? "Pause" : "Play"
                    highlighted: DemoState.isPlaying
                    onClicked: DemoState.togglePlayback()
                }
            }

            Section { title: "Notification demo" }
            Row {
                spacing: Theme.spacingSm
                QuickAction {
                    glyph: "✉"
                    label: "Trigger notification"
                    onClicked: DemoState.requestNotification("File copied successfully")
                }
            }

            Section { title: "File drop demo" }
            Text {
                text: "Drag a real file onto the island to test native drag-and-drop, or fire a simulated drop below (no files are read, moved, or copied either way)."
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
                width: parent.width
            }
            Row {
                spacing: Theme.spacingSm
                QuickAction {
                    glyph: "⬇"
                    label: "Simulate drop"
                    onClicked: {
                        DemoState.islandState = "expanded"
                        DemoState.currentPanel = "tools"
                        DemoState.simulateFileDrop()
                    }
                }
            }

            Section { title: "Rendering" }
            Row {
                spacing: Theme.spacingSm
                QuickAction {
                    glyph: DemoState.glassEnabled ? "◉" : "○"
                    label: "Glass " + (DemoState.glassEnabled ? "On" : "Off")
                    highlighted: DemoState.glassEnabled
                    onClicked: DemoState.glassEnabled = !DemoState.glassEnabled
                }
                QuickAction {
                    glyph: DemoState.animationsEnabled ? "◉" : "○"
                    label: "Motion " + (DemoState.animationsEnabled ? "On" : "Off")
                    highlighted: DemoState.animationsEnabled
                    onClicked: DemoState.animationsEnabled = !DemoState.animationsEnabled
                }
            }

            Section { title: "Contrast test backdrop" }
            Text {
                text: "Synthetic swatch drawn behind the glass for legibility checks — this does NOT change your real desktop wallpaper. For true cross-wallpaper QA, change your actual desktop background and re-observe (see the visual-qa skill)."
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
                width: parent.width
            }
            Row {
                spacing: Theme.spacingSm
                QuickAction {
                    glyph: "□"
                    label: "None"
                    highlighted: DemoState.debugBackdrop === "none"
                    onClicked: DemoState.debugBackdrop = "none"
                }
                QuickAction {
                    glyph: "■"
                    label: "Dark"
                    highlighted: DemoState.debugBackdrop === "dark"
                    onClicked: DemoState.debugBackdrop = "dark"
                }
                QuickAction {
                    glyph: "□"
                    label: "Light"
                    highlighted: DemoState.debugBackdrop === "light"
                    onClicked: DemoState.debugBackdrop = "light"
                }
            }
        }
    }

    component Section: Column {
        property string title: ""
        width: content.width
        spacing: Theme.spacingXs

        Text {
            text: parent.title
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
        }
        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(1, 1, 1, 0.1)
        }
    }
}
