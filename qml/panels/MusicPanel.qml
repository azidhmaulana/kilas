import QtQuick
import Kilas

Item {
    id: root

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingMd

        Text {
            text: "Now Playing"
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSizeSmall
        }

        MusicWidget {
            width: parent.width
            compact: false
        }
    }
}
