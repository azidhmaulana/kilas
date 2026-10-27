---
name: qt-qml-expert
description: Use when writing, reviewing, or debugging Qt 6 / QML / C++ code in KILAS — module structure, CMake + qt_add_qml_module, C++/QML interop (QML_ELEMENT, Q_PROPERTY, context properties, QAbstractListModel), memory/ownership rules, and QML performance idioms. Load before touching any .qml, CMakeLists.txt, or C++ class exposed to QML.
---

# Qt 6 / QML / C++ Expert

Primary reference: official Qt 6 docs at https://doc.qt.io/qt-6/ — specifically
`qtqml-index.html`, `qtquickcontrols-index.html`, `cmake-manual.html`, and
`qtqml-cppintegration-topic.html`. When in doubt about an API's current
signature, treat the doc.qt.io Qt 6 page as ground truth over memory or
Qt 5 habits — Qt 6 changed module registration, deprecated several Qt 5
patterns (`qmlRegisterType` → `QML_ELEMENT`), and uses a new build system
integration (`qt_add_qml_module`).

## Module & project structure

KILAS should use the Qt 6 **CMake QML module** system, not the legacy
`qmlRegisterType` + `.qrc` approach:

```cmake
qt_add_qml_module(kilas_app
    URI Kilas
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/components/GlassPanel.qml
    SOURCES
        src/backend/AppController.cpp
        src/backend/AppController.h
    RESOURCES
        assets/icons/app.svg
)
```

- One logical QML module per feature area (`Kilas.Ui`, `Kilas.Core`) once the
  app grows past a single module — keeps `qmlimportscanner` and the Qt Quick
  Compiler working per-module.
- Never hand-roll `.qrc` files for QML sources when `qt_add_qml_module` is
  available (Qt 6.2+) — it generates the resource list, the qmldir, and
  (optionally) runs `qmlcachegen` for you.
- Enable the Qt Quick Compiler (`qt_add_qml_module(... QML_FILES ... OUTPUT_DIRECTORY ...)`
  with `ENABLE_TYPE_COMPILER` / `qt6_target_qml_sources` with cache generation
  turned on for release builds) to compile QML to C++ bytecode ahead of time —
  this removes JS parse/compile cost on startup and matters for a desktop app
  that should feel instant.

## Exposing C++ to QML

Prefer the Qt 6 declarative registration macros over imperative registration:

```cpp
// AppController.h
class AppController : public QObject {
    Q_OBJECT
    QML_ELEMENT                       // registers the type via CMake/build system
    Q_PROPERTY(bool isBusy READ isBusy NOTIFY isBusyChanged)
public:
    explicit AppController(QObject *parent = nullptr);
    bool isBusy() const { return m_busy; }
    Q_INVOKABLE void refresh();
signals:
    void isBusyChanged();
private:
    bool m_busy = false;
};
```

Rules of thumb:

- `QML_ELEMENT` / `QML_SINGLETON` / `QML_UNCREATABLE` on the C++ class,
  **not** `qmlRegisterType<T>()` calls scattered in `main.cpp`. Registration
  then happens automatically at build time via the module's URI.
- Every QML-visible property needs a `NOTIFY` signal, even if it looks
  constant today — QML's binding engine depends on it for change propagation,
  and a property without `NOTIFY` silently breaks reactive bindings later.
- Use `Q_INVOKABLE` for C++ methods QML calls imperatively; use signals for
  C++ → QML events; use properties/bindings for state, not polling.
- For lists/tables exposed to QML, subclass `QAbstractListModel` and expose
  roles via `roleNames()` — do **not** expose a raw `QList<QObject*>` as a
  property when the list can change size at runtime; `QAbstractListModel`
  gives `Repeater`/`ListView` fine-grained `dataChanged`/`rowsInserted`
  updates instead of full rebinds.

## Ownership and memory rules

QML/JS garbage collection and C++ ownership interact in specific,
non-obvious ways (see `qtqml-cppintegration-data.html`):

- An object created in QML (`Component.createObject`) is owned by the QML
  engine and can be destroyed by GC — never hold a raw C++ pointer to it
  past its possible lifetime without a `QPointer`.
- An object passed from C++ to QML as a `QObject*` property/return value
  keeps **C++ ownership by default** unless you explicitly call
  `QQmlEngine::setObjectOwnership(obj, QQmlEngine::JavaScriptOwnership)`.
  Get this wrong and you either leak or get a use-after-free when QML GC
  deletes something C++ still references.
- Context properties (`engine.rootContext()->setContextProperty(...)`) are
  a legacy, non-type-safe mechanism — prefer singletons registered with
  `QML_SINGLETON` for app-wide services (settings, theme, controller) in new
  KILAS code.

## Performance idioms specific to QML

- Avoid deep, wide property binding chains that re-evaluate on every pixel
  of an animation — a binding like `width: parent.width * someExpensiveFn()`
  runs `someExpensiveFn()` on every parent resize/frame if it's not a pure
  property read.
- Prefer `Loader` with `asynchronous: true` for heavy, rarely-shown views
  (settings panels, dialogs) so they don't block the first frame.
- Avoid `anchors` churn in tight animation loops — anchoring recomputes
  layout; for anything animated every frame prefer explicit `x`/`y`/`width`
  bound to a single driving property.
- Use `Qt.binding()` sparingly and only when a binding genuinely needs to be
  assigned imperatively; most of the time a declarative binding expression
  is both clearer and cheaper.
- Profile with **Qt Quick Profiler / QML Profiler** (`doc.qt.io/qt-6/qtquick-debugging-qmlprofiler.html`)
  before guessing — it shows binding evaluation cost, scene graph prep, and
  render time per frame directly.
- See `[[motion-design]]` for animation-specific performance rules (Animator
  classes vs PropertyAnimation) and `[[liquid-glass-ui]]` for shader/effect
  cost.

## Validation checklist

Before considering a QML/C++ change done:

- [ ] New C++ types use `QML_ELEMENT`/`QML_SINGLETON`, not manual
      `qmlRegisterType`.
- [ ] Every `Q_PROPERTY` has a working `NOTIFY` signal and the signal is
      actually emitted when the value changes.
- [ ] Object ownership across the C++/QML boundary is explicit (default
      C++ ownership vs `JavaScriptOwnership`), especially for anything
      created dynamically.
- [ ] No `qmlRegisterType`/`.qrc` hand-editing when `qt_add_qml_module`
      could express the same thing.
- [ ] Large/rarely-used QML components are behind an async `Loader`.
- [ ] Ran (or reasoned about) the QML Profiler for any change touching a
      hot path (startup, scrolling, animated view).
- [ ] `CMakeLists.txt` changes build cleanly with `cmake --build` for the
      target Qt 6 version pinned in `CLAUDE.md`.
