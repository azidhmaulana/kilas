# KILAS — Development Rules

## Identity

- **Name:** KILAS
- **Tagline:** Everything at a glance.
- **What it is:** a floating, always-on-top "Liquid Glass Dynamic Island"
  for Windows, Ubuntu Linux, and macOS — built with **Qt 6, QML, C++17,
  and CMake**.
- **Current phase (v0.1.x): a visual and animation proof of concept.**
  Prioritize animation quality and glass rendering over feature
  quantity. Do not expand scope into a full production application
  without an explicit instruction to move past the prototype phase.

## Tech stack

- **Qt 6.8+** (Core, Gui, Qml, Quick, QuickControls2).
- **QML** for all UI; **C++** only for backend logic, native/platform
  interop, and anything not expressible declaratively (see
  `AppController` — the Focus Timer is the one real C++ feature in the
  prototype; everything else UI-state-related lives in the QML
  `DemoState` singleton).
- **CMake** via `qt_add_executable` + `qt_add_qml_module` — no qmake, no
  hand-written `.qrc` files.
- Primary technical reference for all Qt APIs: **official Qt 6 docs**
  at `doc.qt.io/qt-6/`.
- **No React, Electron, Python, HTML, or browser-based UI anywhere.**

## Skills — when to load them

Load the matching skill *before* writing code in its area:

- **`qt-qml-expert`** — any `.qml` file, C++ class exposed to QML,
  `CMakeLists.txt` change, module registration, or C++/QML ownership
  question.
- **`liquid-glass-ui`** — any blur, translucency, tint, specular, or
  refraction work; any decision about native OS blur-behind.
- **`motion-design`** — any animation, transition, state change, or
  choreographed sequence.
- **`desktop-windowing`** — window chrome, frameless windows,
  drag/resize, multi-monitor/DPI, always-on-top, click-through.
- **`visual-qa`** — after *any* visual/UI/animation change, before
  calling it done.

These are project-local skills (`.claude/skills/`), not plugins.

## Design system

### Color tokens (`qml/theme/Theme.qml` is the source of truth)

```text
Background Dark    #10131B
Glass Surface       #202838
Accent              #A6B4FF
Primary Text        #F5F7FF
Secondary Text      #A5AEC3
Border Highlight     rgba(255,255,255,0.30)
```

### Visual identity

Elegant, minimalist, futuristic. Soft rounded geometry. Premium dark
translucent surfaces with subtle cool-blue accents, refined highlights,
very soft shadows. **No excessive neon. No cluttered UI.** The island
must read as a premium operating-system component, not a conventional
desktop application window.

### Motion system (`qml/animations/MotionTokens.qml` is the source of truth)

All animation durations/easings must come from `MotionTokens`, never be
hardcoded inline, so the whole island feels like one coordinated motion
system:

| Animation | Target duration | Easing |
|---|---|---|
| Expand (collapsed → active/expanded) | 280–350 ms | `OutBack` with slight overshoot |
| Collapse | 200–260 ms | `OutCubic`, no overshoot |
| Glass hover | 150–200 ms | `OutQuad` |
| Panel transition | 160–240 ms | `OutCubic` |
| Notification hold | ~2.6 s visible | — |

State-size spec (logical pixels, adjustable for visual quality):

```text
Collapsed: 170 × 38 px
Active:    240 × 44 px
Expanded:  400 × 290 px
```

Every expand/collapse transition must be interruptible by rapid
repeated clicks without broken geometry or stuck intermediate state —
drive size/state purely off `DemoState.islandState` and QML
`State`/`Transition`, never off one-shot imperative animations that
assume they'll run to completion uninterrupted.

## Liquid Glass — what is and isn't real here

**Hard rule (do not violate this when writing or describing UI code):**
Qt Quick `MultiEffect`/shader-based blur of in-app QML content is **not**
equivalent to native desktop backdrop blur. Never claim or imply actual
desktop/backdrop blur is happening when the implementation is only a
translucent color overlay or an in-scene GPU shader simulating glass.
Always be explicit in code comments, commit messages, and reports about
which one a given surface is using. See the `liquid-glass-ui` skill for
the full per-OS native-blur support matrix (Windows DWM Mica/Acrylic,
macOS `NSVisualEffectView` vibrancy, Linux's compositor-dependent and
largely unstandardized blur-behind) and its "never fabricate, never
require it" policy.

## Cross-platform restrictions

- Target Windows, Ubuntu Linux, and macOS. Never ship a feature that
  only works on one platform without a disclosed, tested fallback for
  the others.
- Native/platform-specific code (DWM calls, `NSVisualEffectView`
  interop, X11/Wayland-specific hints) must be isolated behind a single
  abstraction, never scattered `#ifdef`s through QML-adjacent C++.
- Prevent the island's invisible window margin from blocking clicks to
  other applications — the window stays at the tight collapsed size
  whenever idle, and only grows to its stable interactive size while
  non-collapsed (see "Stable window geometry" below); true per-pixel
  click-through is a known, disclosed limitation if not implemented
  (see `desktop-windowing` skill).
- Never claim a platform was verified unless it was actually run and
  observed on that platform in this session. State plainly which
  platform(s) a change was tested on.

## Prototype-only scope — do NOT implement

AI assistant features, production clipboard history, real system media
controls, a database, user accounts, cloud services, a plugin
marketplace, an auto-updater, analytics, background monitoring
services, full production settings, or installer packaging. All demo
features (music, notifications, drag-and-drop, quick tools) use mock
data and must stay lightweight visual demonstrations — see `README.md`
for the current real-vs-simulated breakdown.

## Component & naming conventions

- One QML type per file, PascalCase filenames matching the root type
  name (`GlassSurface.qml`, `MusicWidget.qml`).
- Shared design tokens live in exactly two singletons: `Theme` (color/
  spacing/radius) and `MotionTokens` (durations/easings). Shared,
  cross-window demo/UI state lives in the `DemoState` singleton. Real
  backend logic lives in C++ (`AppController`), registered via
  `QML_ELEMENT`/`QML_SINGLETON`, never via manual `qmlRegisterType`.
- Panels (`qml/panels/`) are full views switched by `DemoState.currentPanel`.
  Components (`qml/components/`) are reusable pieces with no opinion on
  which panel/window hosts them.

## Code style

- No comments explaining *what* code does — identifiers should do that.
  Comment only non-obvious *why* (a platform quirk, a workaround, a
  constraint that would surprise a reader) — see the examples already in
  this codebase (`GlassSurface.qml`, `Main.qml`).
- Follow the C++ ownership rules in the `qt-qml-expert` skill exactly.
- No premature abstraction: this is a five-screen prototype, not a
  framework. Don't build a generic theming engine, plugin system, or
  state-management library ahead of an actual second use case.

## Performance targets

- Stable 60 FPS under normal interaction; support higher refresh rates
  when available.
- No unnecessary continuous rendering while idle (waveform/animations
  should not run when nothing is playing/animating).
- Non-blocking main/GUI thread — no JS `Timer`-driven property mutation
  used as a substitute for a real animation type.
- Never report a measured FPS number without having actually profiled
  it (QML Profiler / `QSG_RENDER_TIMING=1`) in this session.

### Stable window geometry

**Never bind the native `Window`'s width/height directly to a live,
animated QML value.** Confirmed in this project: doing so turns every
animation frame into a real native window resize (a DWM round trip plus
backing-store reallocation on Windows), which is the dominant cause of
stutter/flicker for a window-geometry animation — not GPU rendering
cost. Keep the native window pinned to a small, fixed set of sizes
(snapped instantly, never animated), and animate the *QML content's*
width/height inside that stable window instead. See `qml/Main.qml` and
the `desktop-windowing` skill's "Animating window geometry" section for
the worked pattern and its disclosed trade-off (a slightly larger
invisible/click-blocking margin while non-collapsed).

### Animator classes by default for transform/opacity

Any `Behavior`/animation on `x`, `y`, `scale`, `rotation`, or `opacity`
should use the matching render-thread Animator (`XAnimator`,
`YAnimator`, `ScaleAnimator`, `RotationAnimator`, `OpacityAnimator`)
instead of `NumberAnimation`, unless the property being animated isn't
one of those five (e.g. `width`, `height`, `cornerRadius`, `color` —
those have no Animator equivalent and stay on `PropertyAnimation`/
`ColorAnimation`). See the `motion-design` skill.
