pragma Singleton
import QtQuick

// Shared, in-memory demo state for the prototype. This is intentionally
// a plain QML singleton (not C++) because it holds nothing but
// transient UI/demo state for this visual proof of concept — see
// AppController (C++) for the one piece of real backend logic (the
// Focus Timer). Both Island.qml and DemoController.qml bind to this so
// the floating island and the separate demo-control window stay in
// sync without any direct parent/child coupling between the two windows.
QtObject {
    id: root

    // "collapsed" | "hover" | "expanded" | "notification"
    property string islandState: "collapsed"
    property string restoreState: "collapsed"

    // "home" | "music" | "tools"
    property string currentPanel: "home"

    property bool glassEnabled: true
    property bool animationsEnabled: true
    property bool dropActive: false

    // Synthetic contrast-test backdrop, NOT the real desktop wallpaper —
    // see liquid-glass-ui skill / visual-qa: real wallpaper comparison is
    // a manual QA step performed by actually changing the OS wallpaper.
    // "none" | "dark" | "light"
    property string debugBackdrop: "none"

    // --- Music mock state (Animation 3) ---
    property bool isPlaying: false
    property int trackIndex: 0
    property real playbackPosition: 0
    property var tracks: [
        { title: "Midnight Drive", artist: "KILAS Demo", duration: 214 },
        { title: "Glass Horizon", artist: "KILAS Demo", duration: 188 },
        { title: "Afterglow", artist: "KILAS Demo", duration: 231 }
    ]
    // Defensive fallback, not just `tracks[trackIndex]`: Qt 6.8's QML
    // compiler evaluated this singleton's own bindings slightly after
    // some *other* files' first-frame bindings already tried to read
    // it, so `tracks`/`trackIndex` could transiently be unset — see the
    // matching note in Theme.qml.
    property var currentTrack: (tracks && tracks.length > trackIndex)
                                ? tracks[trackIndex]
                                : { title: "", artist: "", duration: 1 }

    function togglePlayback() { isPlaying = !isPlaying }

    function nextTrack() {
        trackIndex = (trackIndex + 1) % tracks.length
        playbackPosition = 0
    }

    function previousTrack() {
        trackIndex = (trackIndex - 1 + tracks.length) % tracks.length
        playbackPosition = 0
    }

    // --- Notification demo (Animation 4) ---
    property string notificationText: ""
    signal notificationRequested(string text)

    function requestNotification(text) {
        notificationText = text
        notificationRequested(text)
    }

    // --- File Shelf / drop demo (Animation 5) ---
    property int shelfCount: 0
    property var shelfNames: []
    signal fileDropDemoRequested()

    function simulateFileDrop() {
        shelfCount += 1
        shelfNames = shelfNames.concat(["Mock-File-" + shelfCount + ".txt"])
        fileDropDemoRequested()
    }

    function registerDroppedUrls(urls) {
        shelfCount += urls.length
        var names = []
        for (var i = 0; i < urls.length; ++i)
            names.push(urls[i].toString().split("/").pop())
        shelfNames = shelfNames.concat(names)
        fileDropDemoRequested()
    }
}
