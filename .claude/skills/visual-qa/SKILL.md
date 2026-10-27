---
name: visual-qa
description: Use after any UI, animation, or Liquid Glass visual change in KILAS to verify it actually looks and performs right — running the app, capturing screenshots/grabToImage comparisons, checking frame pacing and DPI scaling, and working through the cross-platform visual checklist. Load before marking a QML/visual task complete.
---

# Visual QA for KILAS

Primary references: `doc.qt.io/qt-6/qtquick-debugging-qmlprofiler.html`,
`doc.qt.io/qt-6/qml-qtquick-item.html#grabToImage-method`, and
`doc.qt.io/qt-6/qtquicktest-index.html` (Qt Quick Test / `qmltestrunner`).

A change to QML/shaders/animation is not done when it compiles — Qt Quick
code can build and run while being visually broken (wrong blur radius,
dropped frames, a glass panel that's opaque on Linux because the shader
path differs). This skill is the "actually look at it" step.

## Running and capturing the app

- Prefer the project's `run` skill/launch workflow to start KILAS rather
  than re-deriving build/run commands from scratch.
- For a quick, scripted pixel check of a specific QML component without
  launching the full app, use `Item.grabToImage()`:

```qml
// Ad-hoc visual capture for comparison, e.g. in a dev/debug harness
glassPanel.grabToImage(function(result) {
    result.saveToFile("panel_snapshot.png")
})
```

- For regression-style comparisons, Qt Quick Test (`qmltestrunner`) can run
  `TestCase { ... }` QML files headlessly in CI and combine `grabToImage`
  with pixel-diffing against a known-good reference image — set this up
  once KILAS has enough stable visual components to be worth baselining;
  don't over-invest in pixel-diff infra before the design has stabilized.
- When reviewing interactively, always check both **light and dark**
  desktop themes if KILAS adapts to system theme, and at least one scaled
  (125%/150%) DPI setting, not only 100%.

## What to look for (beyond "does it look okay")

### Liquid Glass panels (`[[liquid-glass-ui]]`)
- Blur is visibly blurring the *actual* content behind the panel, not a
  stale/cached frame — move something behind the panel and confirm it
  updates (if the design intends a live, non-static backdrop).
- No banding/aliasing artifacts in the blur or specular gradient — a sign
  of too-low precision in a custom shader.
- Tint and border contrast hold up against both a light and dark background
  behind the panel — Liquid Glass tends to break first against the backdrop
  color it wasn't tuned on.
- Corner radius of the glass shader's refraction/border matches the
  `Rectangle`/clip geometry exactly — mismatches show as a seam at the edge.

### Motion (`[[motion-design]]`)
- No visible stutter on entrance/exit animations — if unsure, capture with
  `QSG_RENDER_TIMING=1` or the QML Profiler and check for frame times
  consistently under ~16.6ms (60Hz) or ~8.3ms (120Hz) during the animation,
  not just "looked smooth to the eye."
- Animations reach their exact end state — no visible snapping/jump at the
  end of an eased curve (a sign the `to` value and the resting layout value
  disagree).
- Reduced-motion mode (if implemented) actually shortens/skips the
  animation when toggled, verified by actually toggling it, not just by
  reading the code.

### Windowing (`[[desktop-windowing]]`)
- Frameless window drag/resize feels native (no lag, correct cursor,
  correct edge hit-testing) — test at window edges and corners
  specifically.
- No transparent-window artifacts (black flashes, incorrect compositing)
  when moving the window across monitors with different DPI/scale factors.
- Window chrome renders correctly immediately on launch — check for a
  one-frame flash of unstyled/opaque content before the first real paint.

### Cross-platform parity
- Run the same visual check path on **at least Windows and one of
  Linux/macOS** before calling a visual change "done" — native blur
  fallbacks, RHI backend differences, and compositor quirks
  (`[[liquid-glass-ui]]`, `[[desktop-windowing]]`) mean a screen that's
  perfect on one OS can be silently degraded on another. If only one
  platform is available to test locally, say so explicitly rather than
  claiming full cross-platform verification.

## Accessibility pass

- Check contrast of text/icons against the glass tint in both light and
  dark variants — translucent surfaces are a common source of failing
  contrast ratios; don't rely on the opaque mockup's contrast holding once
  blur/tint is in place.
- Confirm focus indicators (keyboard navigation) remain visible against
  glass backgrounds — a subtle focus ring can disappear entirely against a
  busy blurred backdrop.

## Reporting results

When reporting a visual QA pass, state plainly:
- What was actually run/captured (app launched and interacted with vs.
  code-read-only).
- Which platform(s) were checked.
- Any check that was skipped and why (e.g. "macOS not available in this
  environment — Windows and Linux verified").

Never report a visual change as verified based solely on reading the QML
source — type-checking and a clean build are necessary but not sufficient;
this skill exists specifically because they don't catch visual regressions.

## Validation checklist

- [ ] App actually launched and the changed screen/component visually
      inspected (not just compiled).
- [ ] Checked in both light and dark theme if theme-adaptive.
- [ ] Checked at 100% and at least one non-100% DPI scale.
- [ ] Liquid Glass panels checked against both a light and dark backdrop
      for contrast/tint correctness.
- [ ] Animation frame pacing checked (profiler or `QSG_RENDER_TIMING`) for
      anything touching a hot/frequent animation path.
- [ ] Frameless window drag/resize manually exercised at edges/corners.
- [ ] Cross-platform check done on more than one OS, or the gap explicitly
      disclosed in the report.
- [ ] Accessibility contrast and focus-visibility spot-checked for any
      glass/translucent surface.
