import QtQuick
import Kilas

Item {
    id: root
    signal collapseRequested()

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingMd

        Row {
            width: parent.width

            Column {
                spacing: 0
                Text {
                    text: "KILAS"
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSizeTitle
                    font.bold: true
                    font.letterSpacing: 1
                }
                Text {
                    text: "Everything at a glance."
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSizeSmall
                }
            }

            Item { width: parent.width - 160; height: 1 }

            QuickAction {
                glyph: "↙"
                onClicked: root.collapseRequested()
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(1, 1, 1, 0.08)
        }

        MusicWidget {
            width: parent.width
            compact: true
        }

        Row {
            spacing: Theme.spacingSm

            QuickAction {
                glyph: "♪"
                label: "Music"
                onClicked: DemoState.currentPanel = "music"
            }
            QuickAction {
                glyph: "⚙"
                label: "Tools"
                onClicked: DemoState.currentPanel = "tools"
            }
            QuickAction {
                glyph: "✉"
                label: "Notify"
                onClicked: DemoState.requestNotification("File copied successfully")
            }
        }
    }
}
