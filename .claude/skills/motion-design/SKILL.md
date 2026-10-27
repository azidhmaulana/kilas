---
name: motion-design
description: Use when adding or reviewing animations, transitions, or state changes in KILAS QML. Covers Qt Quick's render-thread Animator classes vs property animations, easing curves, Behavior/States/Transitions, the Qt Quick Timeline module for choreography, and how to keep animations GPU-smooth at 60/120 Hz without blocking the UI thread.
---

# Motion Design (GPU-smooth QML animation)

Primary references: `doc.qt.io/qt-6/qtquick-statesanimations-animations.html`,
`doc.qt.io/qt-6/qml-qtquick-animator.html`, `doc.qt.io/qt-6/qtquicktimeline-index.html`,
and `doc.qt.io/qt-6/qml-qtquick-propertyanimation.html`.

## Why most QML animations are already "GPU-accelerated" — and when they aren't

Qt Quick's scene graph renders on a dedicated render thread, separate from
the QML/JS GUI thread, whenever the platform's threaded render loop is
active (default on Windows/Linux/macOS for `QQuickWindow`/`Window`). A
standard `PropertyAnimation`/`NumberAnimation` still has its **value
computed on the GUI thread** each frame, then handed to the scene graph —
fine for almost everything, but it means a busy GUI thread (heavy JS, large
layout recalculation) can cause the animation to stutter even though
rendering itself is GPU-driven.

**Animator classes** (`XAnimator`, e.g. `ScaleAnimator`, `OpacityAnimator`,
`RotationAnimator`, `UniformAnimator`) run entirely on the **render thread**
and are driven directly by the scene graph, bypassing the GUI thread each
frame. Use them specifically for:

- Animations that must stay smooth even if the GUI thread is momentarily
  busy (e.g. loading state transitions, window open/close, page swipes).
- Pure transform/opacity animations — `ScaleAnimator`, `OpacityAnimator`,
  `RotationAnimator`, `XAnimator`/`YAnimator`.

```qml
// Prefer this for a transform-only entrance animation:
ScaleAnimator on glassPanel {
    from: 0.92; to: 1.0
    duration: 220
    easing.type: Easing.OutCubic
}

// Over the GUI-thread equivalent when smoothness under load matters:
Behavior on scale {
    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
}
```

Trade-off: Animator classes only animate `x`, `y`, `scale`, `rotation`,
`opacity` (the transform/opacity properties the scene graph can apply
independently of GUI-thread layout) — anything else (`width`, `height`,
custom shader uniforms, color) still goes through a regular
`PropertyAnimation`/`Behavior`. For KILAS, default to Animator classes for
transform/opacity, and regular animations for everything else, then keep
GUI-thread work light so those aren't the bottleneck either.

## Behavior, States, and Transitions

- `Behavior on <property>` is the idiomatic way to animate any property
  change triggered from elsewhere (binding change, state change) without
  writing imperative animation-start code.
- Use `State`/`Transition` for multi-property, named UI states ("collapsed"
  / "expanded" / "focused") rather than a pile of independent `Behavior`
  blocks — a `Transition` can sequence/parallelize multiple property
  animations declaratively and is easier to reason about as the UI grows.

```qml
states: [
    State {
        name: "expanded"
        PropertyChanges { target: panel; height: 320; opacity: 1.0 }
    }
]
transitions: Transition {
    ParallelAnimation {
        NumberAnimation { properties: "height"; duration: 280; easing.type: Easing.OutExpo }
        NumberAnimation { properties: "opacity"; duration: 180; easing.type: Easing.OutQuad }
    }
}
```

## Choreographed/complex motion: Qt Quick Timeline

For multi-step, keyframed sequences (a splash sequence, a multi-stage
glass-panel reveal with staggered children), use the **Qt Quick Timeline**
module (`import QtQuick.Timeline`) rather than chaining `SequentialAnimation`
blocks by hand — it gives you a scrubable keyframe timeline (also editable
visually in Qt Design Studio) and keeps complex choreography declarative
and inspectable instead of a deeply nested animation tree.

## Easing and feel

- Default to `Easing.OutCubic`/`Easing.OutExpo` for entrances (fast start,
  soft landing) and `Easing.InCubic`/`Easing.InQuad` for exits.
- For a "liquid"/elastic feel appropriate to the Liquid Glass aesthetic
  (`[[liquid-glass-ui]]`), `SpringAnimation` (mass/spring/damping model) can
  read more organic than a fixed-duration eased curve — use sparingly, it's
  easy to overshoot into "bouncy toy" territory for a professional desktop
  app.
- Keep interaction-triggered animations short: 150–300ms for most UI
  feedback; longer (400ms+) only for deliberate, rare transitions (window
  open, major view change). Long animations on frequent interactions (hover,
  click) make the app feel sluggish.

## Avoiding GUI-thread jank

- Never drive animation via a JS `Timer` that mutates properties every tick
  — this runs on the GUI thread, competes with everything else, and is not
  frame-synced. Use declarative animations/Animators, which are
  frame-driven by the render loop.
- Avoid heavy bindings re-evaluating during an animation (see
  `[[qt-qml-expert]]` on binding cost) — an animated property that triggers
  a cascade of dependent bindings each frame is a common, hard-to-spot
  source of dropped frames.
- Avoid `layer.enabled: true` on items that are *also* being animated every
  frame unless necessary for the Liquid Glass shader stack — `layer`
  forces an offscreen render-to-texture pass; combined with a per-frame
  transform it's strictly more expensive than animating the un-layered
  item when both are visually equivalent.
- Measure, don't guess: `doc.qt.io/qt-6/qtquick-debugging-qmlprofiler.html`
  shows per-frame render/binding time; also check `QSG_RENDER_TIMING=1` as
  an environment variable for quick scene-graph frame timing without a full
  profiler session.

## Respecting reduced motion

Expose and honor a "reduce motion" app setting (and ideally detect the OS
accessibility equivalent where Qt surfaces it) — when active, shorten or
skip non-essential animations (entrance/exit transitions) while keeping
state changes instant and correct. This is both an accessibility
requirement and a pragmatic performance fallback on weaker GPUs, same spirit
as the "[[liquid-glass-ui]]" reduced-transparency fallback.

## Validation checklist

- [ ] Transform/opacity-only animations use Animator classes
      (`ScaleAnimator`/`OpacityAnimator`/`RotationAnimator`/`XAnimator`/
      `YAnimator`) where smoothness under GUI-thread load matters.
- [ ] No JS `Timer`-driven property mutation used as a substitute for a
      real animation type.
- [ ] Multi-property UI states use `State`/`Transition`, not ad-hoc
      parallel `Behavior` blocks that have grown hard to follow.
- [ ] Complex keyframed sequences use Qt Quick Timeline instead of deeply
      nested `SequentialAnimation`/`ParallelAnimation`.
- [ ] Animation durations match the interaction's frequency (short for
      frequent feedback, longer only for rare transitions).
- [ ] No unnecessary `layer.enabled` on items animated every frame.
- [ ] A reduced-motion path exists and has been exercised.
- [ ] Verified smooth via QML Profiler / `QSG_RENDER_TIMING=1` on at least
      one change touching a hot animated path.
