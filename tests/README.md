# Tests

No automated test harness is wired up yet for this prototype phase. See
the `visual-qa` skill for the intended approach once the UI stabilizes:

- **Qt Quick Test** (`qmltestrunner`) with `TestCase { ... }` QML files
  for behavioral checks (state transitions, DemoState mutations).
- `Item.grabToImage()` based pixel comparisons for visual regression
  checks on stable components (e.g. `GlassSurface`, `Waveform`).

Don't invest in pixel-diff baselines before the Liquid Glass design
direction is confirmed against real usage — see CLAUDE.md's
prototype-only scope.
