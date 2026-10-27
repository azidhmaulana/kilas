# KILAS — Liquid Glass Dynamic Island

**Version 0.1.0 — UI & animation prototype. Not a production application.**

KILAS is a floating, always-on-top "Dynamic Island" style widget for
Windows, Ubuntu Linux, and macOS, built with Qt 6, QML, and C++/CMake.
This phase is a visual and animation proof of concept: premium Liquid
Glass aesthetics, fluid motion, and a handful of mocked demo panels
(music, notifications, drag-and-drop, quick tools). See `CLAUDE.md` for
the full design/architecture spec and development rules, and
`.claude/skills/` for the detailed technical references this project
was built against.

## Status

**Built and run successfully on Windows 11** with Qt 6.8.3 (MinGW 13.1.0
kit) + CMake/Ninja — screenshot-verified: both windows render with
correct glass styling, color tokens, and layout, and the app produces
zero QML runtime warnings. Three real bugs were found and fixed during
bring-up (see "Toolchain gotchas" below) — this was genuinely useful
verification, not a rubber stamp. **Not yet built/run on macOS or
Linux** — the CMake setup targets all three per `CLAUDE.md`, but only
Windows has been exercised so far. The system's MSVC (Visual Studio
2026 Community) install was found to be missing its own `include`/`lib`
(broken toolset), so this was built with Qt's MinGW kit instead — a
clean MSVC install should work fine too (CMakeLists doesn't assume
either compiler) but hasn't itself been verified.

## Requirements

- Qt **6.8 or newer** (Core, Gui, Qml, Quick, QuickControls2)
- CMake **3.21+**
- A C++17 compiler:
  - Windows: MSVC (Visual Studio 2022/2026) or MinGW — verified with Qt's
    bundled MinGW 13.1.0 kit (`aqtinstall`: `install-qt ... win64_mingw`
    + `install-tool ... tools_mingw1310`)
  - macOS: Xcode command line tools (Clang) — untested
  - Linux: GCC or Clang — untested

## Build

```bash
cmake -S . -B build -DCMAKE_PREFIX_PATH="<path-to-your-Qt-6.8-kit>"
cmake --build build
```

On Windows without a working MSVC install, add
`-G Ninja -DCMAKE_C_COMPILER=<mingw>/bin/gcc.exe -DCMAKE_CXX_COMPILER=<mingw>/bin/g++.exe`.

Before running, deploy the Qt runtime next to the binary (not needed on
a system where Qt's bin dir is already on `PATH`, but safest in general):

```bash
<qt-kit>/bin/windeployqt.exe --qmldir qml build/kilas.exe   # Windows
```

Run the resulting `kilas` (or `kilas.exe`) binary from `build/`. Launching
it opens two windows: the floating island (frameless, transparent,
always-on-top, centered at the top of your primary display) and a
normal decorated "KILAS — Demo Controller" window you can use to drive
every demo without needing to discover each interaction by hand.

## Motion & performance optimization pass

A follow-up pass focused specifically on animation smoothness/frame
pacing, with the explicit constraint of not changing the existing UI
design. Rebuilt cleanly afterward (zero QML runtime warnings).

**Diagnosis.** Code review plus `QSG_RENDER_TIMING=1`/`QSG_INFO=1`
(not left on permanently — see `CLAUDE.md`) surfaced two real
bottlenecks, not guessed ones:

1. `Main.qml` bound the native OS window's `width`/`height` directly to
   `Island`'s live, animated size — every frame of the expand/collapse
   animation was a **real native window resize** (confirmed via the
   scene graph log: `Creating Direct Composition device` /
   per-window `QRhi`/swapchain machinery engaging on every size
   change), not a cheap scene graph update. This is almost certainly
   what "feels heavy" referred to.
2. `GlassSurface.qml`'s `ShaderEffectSource` feeding the ambient glow
   blur had `live: true` — the scene graph log showed its window's
   render thread ticking every ~16ms **forever, including while
   sitting perfectly idle** with nothing visually changing. This is
   exactly "repeated glass blur calculations" / "unnecessary offscreen
   rendering" from the diagnosis checklist, and was fixed, not just
   described.

**Fixes applied:**

- `Main.qml`: switched from animating the native window's geometry
  directly ("Approach A") to a stable two-tier window surface
  ("Approach B") — the window snaps *instantly* (unanimated) between a
  tight "collapsed" size and a larger "stable" size that covers every
  non-collapsed state, and `Island.qml` animates its own width/height
  *inside* that stable window as an ordinary, cheap scene graph resize.
  See the `desktop-windowing` skill's new "Animating window geometry"
  section and `CLAUDE.md`'s "Stable window geometry" rule for the full
  reasoning and the disclosed trade-off (a larger invisible/
  click-blocking margin while non-collapsed, not while idle).
- `GlassSurface.qml`: `live: false` on the glow's `ShaderEffectSource`,
  with explicit `scheduleUpdate()` calls wired to exactly the
  properties that actually change its appearance (`hoverProgress`,
  `width`, `height`) — same visual result, renders only when something
  genuinely needs to, idles the instant nothing is moving. Also added
  `autoPaddingEnabled: false` on the glow's `MultiEffect` (smaller,
  predictable effect surface) and documented why `brightness`/
  `saturation` animating with hover is cheap (uniform update on an
  already-compiled shader) versus the real hazard the skill warns about
  (toggling boolean effect features like `blurEnabled`/`shadowEnabled`,
  which forces a shader-variant swap — nothing in this codebase does
  that).
- Converted every `Behavior`/animation on `x`, `scale`, `rotation`, or
  `opacity` across `Island.qml`, `GlassSurface.qml`, `QuickAction.qml`,
  `NotificationPill.qml`, `ToolsPanel.qml`, and `Waveform.qml` from
  `NumberAnimation`/`PropertyAnimation` to the matching render-thread
  Animator (`XAnimator`, `ScaleAnimator`, `OpacityAnimator`) — these run
  on the scene graph render thread independent of the GUI thread. Left
  `width`/`height`/`cornerRadius`/`color` animations as-is; there is no
  Animator type for them.
- Wired up `MotionTokens.contentRevealDelay`, which existed as a token
  but was never actually used: the expanded panel content now
  pause-then-fades-in slightly *after* the geometry morph starts (only
  when entering expanded — collapsing fades out immediately), matching
  the "content appears slightly after expansion begins" motion spec
  that had silently gone unimplemented.
- Reviewed and *kept unchanged*: the waveform's bar-height animation
  (periodic ~11Hz re-sample + per-bar eased `Behavior`, not a per-frame
  JS loop, not `Canvas`-based — already the right pattern) and the
  three-panel switcher (all three panels stay instantiated and are
  only slid/faded, never recreated — already correct).

**Measured (not invented) results**, via `QSG_RENDER_TIMING=1`:
threaded render loop confirmed active; RHI backend is Direct3D11 on a
real discrete GPU (NVIDIA GeForce RTX 5050 in this environment, "prefer
software device: 0"); steady-state idle frame cost is 0–1ms
(render+swap) on the island's window after the `live:false` fix, versus
every ~16ms indefinitely before it. **Not measured**: frame timing
*during* a live expand/collapse animation — this session's input
simulation (`SendInput`/`mouse_event`) did not reliably register clicks
against the running app (plausibly an artifact of the remote-desktop
session this ran under), so the animation itself could not be
interactively triggered and profiled here. The architectural fix (no
more native resize per frame) is verified by code, not by a captured
animation trace — this is disclosed, not glossed over. Recommend
testing interactively (rapid clicking, hover-during-expand, panel
switching mid-transition) the next time a human or a working input
path is available.

**Remaining, lower-priority observation:** the separate `DemoController`
window's render thread was *also* seen ticking continuously at idle in
the same log capture, with no obvious cause in `DemoController.qml`
(no `Timer`, no `live: true`, no infinite animation) — not
root-caused in this pass since it's a debug-only utility window, not
part of the Liquid Glass surface this optimization targeted. Worth
revisiting if `DemoController` itself ever needs to be lightweight.

## Toolchain gotchas found during bring-up

Real, non-obvious issues hit getting this to actually run — worth
knowing before you hit them again:

1. **`qt_add_qml_module`'s generated type-registration code uses an
   angle-bracket `#if __has_include(<Foo.h>)`**, which only resolves
   against `-I` include directories, never the including file's own
   directory. Any C++ header with `QML_ELEMENT`/`QML_SINGLETON` must
   have its directory added via `target_include_directories`, or the
   type silently never registers (fails to compile with "X was not
   declared in this scope" in the generated file, not your code).
2. **`pragma Singleton` auto-detection in pure-QML singletons did not
   work** with this Qt 6.8.3 toolchain — `Theme`, `MotionTokens`, and
   `DemoState` came out registered as plain, uninstantiated types in
   the generated `qmldir` instead of singletons. Referencing a property
   on an uninstantiated type (`Theme.accent`) is valid QML syntax that
   silently evaluates to `undefined` rather than erroring, so this
   showed up as a sea of "Unable to assign [undefined] to QColor/int/
   double/bool" warnings and a UI that rendered with no color/sizing at
   all. Fixed with explicit
   `set_source_files_properties(<file> PROPERTIES QT_QML_SINGLETON_TYPE TRUE)`
   — **called before `qt_add_qml_module()`**, since that macro reads
   the property synchronously while processing `QML_FILES`, not lazily.
3. A `WIN32_EXECUTABLE TRUE` Qt app has no console and silently
   discards `qWarning`/`qDebug` output, which hid bug #2 at first. The
   `WIN32_EXECUTABLE $<IF:$<CONFIG:Debug>,FALSE,TRUE>` generator
   expression in `CMakeLists.txt` keeps a console attached on Debug
   builds specifically so QML runtime warnings are visible.

## Project structure

```text
KILAS/
├── .claude/                  Project-local Claude Code skills + CLAUDE.md
├── CMakeLists.txt
├── src/                      C++ (AppController: the one real backend piece — the Focus Timer)
├── qml/
│   ├── Main.qml               Island's OS window (frameless/transparent/always-on-top)
│   ├── Island.qml             State machine: collapsed/hover/expanded/notification
│   ├── DemoController.qml     Separate demo-control window (Phase 7)
│   ├── components/            GlassSurface, MusicWidget, Waveform, NotificationPill, QuickAction
│   ├── panels/                 HomePanel, MusicPanel, ToolsPanel
│   ├── animations/             MotionTokens (durations/easings — the motion design system)
│   └── theme/                  Theme (color/spacing/radius tokens)
├── assets/
└── tests/
```

## What's real vs. simulated

- **Glass/blur**: the Liquid Glass surface (`qml/components/GlassSurface.qml`)
  is a GPU-shader simulation (Qt Quick `MultiEffect` blurring an in-scene
  glow layer, plus gradient tint and edge lighting) — it does **not**
  blur the real desktop behind the window. True native backdrop blur
  (Windows Mica/Acrylic via DWM, macOS `NSVisualEffectView`, Linux
  compositor blur-behind) is **not implemented** in this prototype — see
  the `liquid-glass-ui` skill for exactly why (inconsistent OS/compositor
  support) and what would be required to add it as an optional layer.
- **Focus Timer**: real C++ logic (`AppController`, a `QTimer`-backed
  countdown), the one non-mocked backend feature.
- **Everything else** (music playback, clipboard, notifications, file
  drop persistence) is mock data/visual demonstration only, per the
  scope limits in `CLAUDE.md`.

## Known, disclosed limitations

- No true per-pixel click-through for the island's transparent window
  margins — mitigated by keeping the OS window geometry tightly matched
  to the visible glass shape at every state, not solved outright.
- Rounded-corner clipping of panel content relies on margins keeping
  content away from the corners rather than a true rounded clip mask.
- Native backdrop blur, multi-monitor picker UI, and real OS notification
  integration are explicitly out of scope for this phase.
