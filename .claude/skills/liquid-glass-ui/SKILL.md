---
name: liquid-glass-ui
description: Use when implementing frosted/translucent "Liquid Glass" panels, blur, refraction, or specular highlight effects in KILAS QML. Covers Qt Quick's MultiEffect/ShaderEffect pipeline, custom GLSL/HLSL shaders via QSB, RHI backend differences, and the real limitations of native OS blur (Windows Acrylic/Mica, macOS vibrancy, Linux compositor blur) versus a GPU-shader approach.
---

# Liquid Glass UI (Qt Quick Effects + Shaders)

Primary references: `doc.qt.io/qt-6/qtquick-effects-multieffect.html`,
`doc.qt.io/qt-6/qtshadertools-index.html` (Qt Shader Tools / QSB),
`doc.qt.io/qt-6/qtquick-effects-qml-shadereffect.html`, and
`doc.qt.io/qt-6/qrhi.html` for the Rendering Hardware Interface backends
(Direct3D 11/12, Metal, Vulkan, OpenGL) that Qt Quick's scene graph runs on
since Qt 6.

## What "real" Liquid Glass means here

A convincing glass/liquid-glass surface is **not** just `opacity + color`.
It needs, layered in this order:

1. **Background blur** (Gaussian or dual-Kawase) of whatever is behind the
   panel.
2. **Tint** — a translucent color overlay on top of the blur.
3. **Specular highlight / sheen** — a soft directional light gradient that
   moves or reacts to simulate curved glass.
4. **Edge refraction / displacement** (optional, higher cost) — a subtle
   normal-map-like distortion at the panel's rounded border to sell
   "glass," not "frosted plastic."
5. **Border** — a 1px semi-transparent highlight/stroke, usually brighter
   on the top edge, to catch the implied light source.

Qt Quick gives you the building blocks but not a one-line effect for this —
build it from `MultiEffect` + a custom `ShaderEffect` for the specular/
refraction layer.

## Qt Quick Effects module (Qt 6.5+)

`Qt5Compat.GraphicalEffects` (the old `QtGraphicalEffects` port) is a
**compatibility shim for migrating Qt 5 apps** — do not build new KILAS UI
on it. Use the native **Qt Quick Effects** module instead:

```qml
import QtQuick
import QtQuick.Effects

Item {
    id: glassPanel
    width: 320; height: 200

    // Content to be blurred must be captured first — usually a
    // ShaderEffectSource/Image of the background, or layer.enabled on
    // the item sitting behind this panel.
    MultiEffect {
        anchors.fill: parent
        source: backgroundCapture   // Item/ShaderEffectSource of what's behind
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 0.6                    // 0..1, tune per design spec
        blurMax: 48                  // px radius ceiling
        brightness: 0.05
        saturation: 0.1
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Qt.rgba(1, 1, 1, 0.12)   // tint
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.35)
    }
}
```

Notes:

- `MultiEffect` is GPU-accelerated and runs as a single combined shader pass
  (blur + color adjustments) — far cheaper than stacking several
  `Qt5Compat.GraphicalEffects` items, which each add a render-to-texture
  pass.
- Blurring **live, moving content behind the panel** (not a static
  background) means the source must be re-rendered every frame the content
  moves — this is the single most expensive thing in a Liquid Glass UI.
  Cache aggressively: only re-run the blur source when the background
  actually changes (`live: false` on the `ShaderEffectSource` plus manual
  `scheduleUpdate()` when needed), not continuously.

## Custom specular/refraction shaders

For the specular sheen and refraction layer, write a custom `ShaderEffect`
with fragment shaders compiled through **Qt Shader Tools (QSB)**:

- Qt 6's scene graph is backend-agnostic (D3D/Metal/Vulkan/GL via RHI), so
  shaders are authored once in Vulkan-flavored GLSL and cross-compiled by
  `qsb` into `.qsb` bundles at build time — add them via CMake:

```cmake
qt6_add_shaders(kilas_app "glass_shaders"
    PREFIX "/shaders"
    FILES
        shaders/specular.frag
        shaders/refraction.frag
)
```

```qml
ShaderEffect {
    anchors.fill: parent
    property real time: 0
    property vector2d lightDir: Qt.vector2d(0.3, -0.6)
    fragmentShader: "qrc:/shaders/specular.frag.qsb"
    NumberAnimation on time { from: 0; to: 1; duration: 6000; loops: Animation.Infinite }
}
```

- Keep shader logic in the fragment shader; drive only a handful of
  `uniform` properties (`time`, `lightDir`, `intensity`) from QML so the
  shader compiles once and animation stays GPU-side (see `[[motion-design]]`
  for why driving uniforms from QML properties, not JS timers, matters for
  frame pacing).
- Test every custom shader on **all three target RHI backends** your CI/dev
  machines represent (Direct3D on Windows, Metal on macOS, Vulkan/OpenGL on
  Linux) — GLSL→HLSL/MSL cross-compilation via QSB is generally reliable but
  precision and texture-sampling edge cases do differ; see
  `QSG_RHI_BACKEND` env var for forcing a backend during testing.

## Native OS blur: what's real and what isn't

Qt Quick does **not** expose native compositor blur-behind as a first-class
QML API. Each OS has a different, non-portable mechanism, and most require
dropping to native/platform code:

| Platform | Native effect | How it's accessed | Caveats |
|---|---|---|---|
| **Windows 11** | Mica / Acrylic (DWM backdrop) | `DwmSetWindowAttribute` with `DWMWA_SYSTEMBACKDROP_TYPE` via raw Win32 calls on the window's `HWND` (from `QWindow::winId()`) — no Qt wrapper | Only applies to the whole window backdrop, not arbitrary QML panels; requires a frameless or Mica-compatible window; disabled when the user turns off transparency effects in Windows Settings; not available at all on Windows 10 except for older "Acrylic" private APIs |
| **Windows 10** | Acrylic blur-behind | Undocumented `SetWindowCompositionAttribute` | Private API, can break between Windows updates — fragile, treat as best-effort cosmetic only |
| **macOS** | Vibrancy / `NSVisualEffectView` | Must add a native `NSVisualEffectView` behind the Qt `NSView` via platform-native code (`QWindow::winId()` → `(__bridge NSView *)`) — no public QQuickWindow API | Qt Quick's own rendering (Metal/OpenGL layer) draws **above** this view, so the blur only shows through where QML content is actually transparent; interacts with window shadow/corner radius settings |
| **Linux (X11)** | Compositor-dependent blur-behind (KDE KWin, some wobbly/Picom setups) | `_KDE_NET_WM_BLUR_BEHIND_REGION` X11 property (KWin only), or compositor-specific hints | **Not standardized.** GNOME/Mutter has no public blur-behind protocol; only works under specific compositors (KWin, some Picom configs); nothing happens under a non-compositing WM |
| **Linux (Wayland)** | None standardized | No cross-desktop protocol for window-backdrop blur as of Qt 6 | Effectively unavailable portably; some compositors (KWin on Wayland) support their own extension, GNOME does not |

**Conclusion for KILAS:** native OS blur-behind is inconsistent enough
(Windows 10 vs 11, KDE vs GNOME, Wayland vs X11, macOS view-layering quirks)
that it cannot be the primary mechanism for Liquid Glass. Treat it as an
**optional, best-effort enhancement** behind a capability check
(`[[desktop-windowing]]` has the per-platform detection pattern), and make
the **GPU shader blur (MultiEffect + custom shaders) the real, portable
implementation** that looks correct everywhere regardless of OS/compositor
support. Only layer native blur-behind on top when detected, as a free
extra softness — never require it for the effect to look right.

## Best practices

- Precompute/cache blur sources for static backgrounds; only mark them
  `live: true` when the background genuinely animates behind the glass.
- Keep glass panels' corner `radius` consistent with the border-highlight
  shader's assumptions — refraction/specular shaders baked for one radius
  look wrong if the panel's geometry changes without updating uniforms.
- Respect a "reduce transparency/reduce motion" setting (`[[motion-design]]`)
  — fall back to a flat, higher-contrast tint with no blur when the OS
  accessibility setting or an in-app toggle requests it; this is also a
  performance escape hatch on low-end GPUs.
- Never stack more than 2–3 live blurred layers on screen at once — each is
  a render-to-texture pass; profile with the Qt Quick Profiler's GPU timing
  before shipping a screen with multiple glass panels.

## Validation checklist

- [ ] Glass effect built from `QtQuick.Effects` (`MultiEffect`) or a custom
      `ShaderEffect`, not the deprecated `Qt5Compat.GraphicalEffects`.
- [ ] Blur source is only re-rendered when its content actually changes
      (no unconditional `live: true` on static backgrounds).
- [ ] Custom shaders tested on each RHI backend relevant to the target OS
      (`QSG_RHI_BACKEND=d3d11|metal|vulkan|opengl`).
- [ ] Native OS blur-behind (if used) is behind a capability check and is
      never required for correct visual appearance.
- [ ] A reduced-transparency/low-power fallback exists and has been
      visually checked.
- [ ] No more than a small, profiled number of simultaneous live-blurred
      panels on any one screen.
