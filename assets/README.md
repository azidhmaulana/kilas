# Assets

No binary assets are checked in yet. The v0.1.0 prototype draws all
artwork procedurally in QML (gradients, Unicode glyphs) specifically so
the visual/animation proof of concept has zero asset-pipeline
dependencies. Add real icons/artwork here once the design is locked, and
wire them into `qt_add_qml_module`'s `RESOURCES` in the root
`CMakeLists.txt`.
