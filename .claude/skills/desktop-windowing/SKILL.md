---
name: desktop-windowing
description: Use when working on KILAS's window chrome, frameless/custom-titlebar behavior, window dragging/resizing, multi-monitor DPI handling, system tray, or any platform-specific windowing code. Covers Qt 6 QWindow/Window APIs (startSystemMove/startSystemResize), Qt::WA_TranslucentBackground equivalents in Qt Quick, high-DPI scaling, and per-OS native windowing differences (Win32 DWM, X11/Wayland, Cocoa).
---

# Desktop Windowing (Qt 6 Quick)

Primary references: `doc.qt.io/qt-6/qml-qtquick-window-window.html`,
`doc.qt.io/qt-6/qwindow.html#startSystemMove`,
`doc.qt.io/qt-6/highdpi.html`, and `doc.qt.io/qt-6/qsystemtrayicon.html`.

## Frameless, custom-chrome windows

KILAS's Liquid Glass aesthetic (`[[liquid-glass-ui]]`) implies a custom
titlebar, which means a frameless `Window`/`ApplicationWindow`:

```qml
import QtQuick
import QtQuick.Window

ApplicationWindow {
    id: root
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"          // required for any translucent/glass chrome
    width: 1024; height: 680

    // Custom titlebar drag region
    Rectangle {
        id: titleBar
        height: 40
        width: parent.width
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => {
                if (mouse.button === Qt.LeftButton)
                    root.startSystemMove()
            }
        }
    }
}
```

Key points:

- `color: "transparent"` on the `Window` is the Qt Quick equivalent of
  `Qt::WA_TranslucentBackground` — required for the window's own alpha
  channel to composite correctly, independent of any in-scene glass shader.
  Without it, a frameless window still has an opaque backing surface.
- `startSystemMove()`/`startSystemResize(edges)` (available on `QWindow`
  since Qt 5.15, exposed to QML `Window` since Qt 6) hand dragging/resizing
  to the native window manager — **prefer this over manually tracking mouse
  deltas and calling `setX/setY`**, because the native path gets you correct
  snapping, multi-monitor edge behavior, and WM-level animations for free,
  and avoids the input-lag feel of a JS-driven drag loop.
- Implement resize handles (invisible `MouseArea`s along edges/corners)
  calling `startSystemResize(Qt.TopEdge | Qt.LeftEdge)` etc., rather than
  reimplementing resize math.
- A frameless window loses native drop-shadow and (on Windows) rounded
  corners automatically — if required, they must be painted in QML
  (shader-based shadow/rounded rect) or, on Windows 11, re-enabled via
  `DwmSetWindowAttribute`/`DWMWA_WINDOW_CORNER_PREFERENCE` through native
  interop.

## Animating window geometry: never resize the native window every frame

**Confirmed in this project (KILAS's island expand/collapse):** binding
a `Window`'s `width`/`height` directly to a live, animated QML value —
so every animation frame drives a real native window resize — causes
visible stutter and resize flicker. A native resize is not a cheap
scene graph update: on Windows it's a DWM round trip plus backing-store/
swapchain reallocation; the platform compositor has to participate on
every single frame of the animation.

**The fix ("stable window surface"):** keep the native window pinned to
one of a small, fixed set of sizes (snap between them *instantly*, with
no animation), sized to cover whichever state currently needs the most
room. Animate the *QML content's* width/height freely inside that
stable window — a pure scene graph resize, which the threaded render
loop handles smoothly. See `qml/Main.qml` in this project for the
worked implementation: it snaps to a "compact" size (tight to the
collapsed pill) or a "stable" size (room for the largest expanded
state), switching eagerly when growing (so there's room before content
starts animating into it) but only switching back to compact *after*
the shrink animation has visually finished (via a settle `Timer` keyed
to the shrink duration, restarted/cancelled on rapid re-interruption) —
switching back too early clips the still-large glass shape.

Trade-off this introduces, and must be disclosed rather than hidden:
the stable window is larger than the visible content whenever it's not
collapsed, so the invisible click-blocking margin (see "Preventing the
invisible window area from blocking interactions" above) is a little
more generous during active interaction than a tight per-frame fit
would be. Minimize this by sizing the stable window for the *content
family* actually in use, not some oversized worst case, and by
returning to the tight size as soon as the content is idle again.

## High-DPI / multi-monitor

- Qt 6 enables high-DPI scaling **by default** (unlike Qt 5, where it was
  opt-in via `AA_EnableHighDpiScaling`) — do not set that attribute in Qt 6,
  it's deprecated and a no-op/warning.
- Use the `QT_SCALE_FACTOR_ROUNDING_POLICY` environment variable /
  `QGuiApplication::setHighDpiScaleFactorRoundingPolicy()` to control
  fractional-scale rounding (`PassThrough` for pixel-perfect fractional
  scaling vs `RoundPreferFloor` for crisper but less precise results) —
  decide this once for KILAS and document the choice rather than leaving it
  default per-platform.
- Test window-drag-across-monitors-with-different-scale-factors explicitly
  — this is the classic bug class (blurry or mis-sized windows) on
  Windows multi-monitor setups with mixed DPI.
- All sizes in QML should be expressed in logical pixels (the default) —
  never manually multiply by a DPI factor; Qt's scaling already accounts
  for it. A manual multiplication is a sign something's wrong.

## System tray and native menus

- `QSystemTrayIcon` (C++) remains the mechanism for a tray icon; expose a
  thin C++ wrapper to QML (`QML_SINGLETON`) if tray actions need to trigger
  QML-side state, per `[[qt-qml-expert]]`'s ownership rules.
- Native/global menu bars are platform-specific (macOS expects a real
  `NSMenu` in the global menu bar; Windows/Linux typically render an in-app
  menu). Qt Widgets' `QMenuBar` auto-adapts on macOS; a pure Qt Quick app
  without `QtWidgets` does not get this for free — decide early whether
  KILAS needs a native global menu (macOS convention) and if so budget for
  a `QtWidgets`-based `QMenuBar` fallback or native interop.

## Per-OS windowing differences to design around

| Concern | Windows | macOS | Linux |
|---|---|---|---|
| Frameless window shadow | Lost; must repaint or re-enable via DWM API | Lost by default on custom-chrome `NSWindow`; can keep via native styleMask bits | Entirely compositor-dependent; many WMs draw no shadow for override-redirect/frameless windows anyway |
| Rounded corners | Windows 11 auto-rounds normal windows but **not** reliably for frameless Qt windows — needs `DWMWA_WINDOW_CORNER_PREFERENCE` or shader-drawn corners | Must draw manually once default titlebar/frame is removed | Compositor-dependent (KWin can round via blur-behind corner radius; GNOME does not) |
| System move/resize | `startSystemMove`/`startSystemResize` map to real Win32 `WM_NCLBUTTONDOWN` hit-testing | Maps to native `NSWindow` drag/resize | Depends on X11/Wayland WM support for `_NET_WM_MOVERESIZE` — virtually all modern WMs support it, but always test under the actual target WM/compositor, not just one dev machine |
| Multi-monitor DPI | Per-monitor DPI v2 generally solid on Windows 10 1703+ | Each display's own backing scale factor, well supported | X11: can be unreliable across monitors with different scale factors depending on WM/XRandR setup; Wayland: generally better per-output scaling |

Treat every row above as something to **detect and gracefully degrade**,
not assume — see `[[liquid-glass-ui]]` for the same philosophy applied to
blur-behind specifically.

## Best practices

- Centralize platform-conditional windowing code (DWM calls, NSVisualEffect
  interop, X11 property setting) behind a single C++ abstraction
  (`PlatformWindowEffects` or similar) exposed to QML as one capability
  surface, rather than scattering `#ifdef Q_OS_WIN`/`Q_OS_MACOS`/`Q_OS_LINUX`
  blocks through QML-adjacent C++.
- Always provide a keyboard-accessible way to move/close/resize windows
  (e.g. `Alt+Space` system menu equivalent, or in-app shortcuts) since a
  fully custom frameless chrome can otherwise break accessibility tools
  that expect standard window controls.
- Test window state persistence (position, size, maximized state) across
  restarts and across monitor configuration changes (external monitor
  unplugged) — a common correctness gap in custom-chrome apps.

## Validation checklist

- [ ] Frameless window uses `startSystemMove`/`startSystemResize`, not a
      manual mouse-delta drag implementation.
- [ ] `color: "transparent"` set wherever translucent/glass chrome is used.
- [ ] No `AA_EnableHighDpiScaling`/Qt 5-era DPI attributes present.
- [ ] Behavior verified (or explicitly reasoned about) across at least one
      mixed-DPI multi-monitor scenario.
- [ ] Platform-specific windowing code (DWM/NSVisualEffect/X11 property)
      is isolated behind a single abstraction, not inlined with `#ifdef`s
      throughout the codebase.
- [ ] Window position/size/maximized state persists correctly across
      restarts and monitor changes.
- [ ] Standard window operations (move, resize, close, minimize) remain
      reachable via keyboard/accessibility tools despite custom chrome.
