cmake_minimum_required(VERSION 3.21)

project(Kilas VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(kilas
    src/main.cpp
    src/AppController.h
    src/AppController.cpp
)

# This Qt 6.8.3 toolchain's qt_add_qml_module did NOT auto-detect
# `pragma Singleton` in these three pure-QML files when generating the
# module's qmldir — they came out registered as plain, uninstantiated
# types instead of singletons. Referencing an uninstantiated type's
# property from QML (e.g. Theme.accent) is valid syntax but always
# evaluates to `undefined`, which is exactly what every "Unable to
# assign [undefined] to ..." runtime warning traced back to.
# QT_QML_SINGLETON_TYPE forces the correct `singleton` qmldir entry
# explicitly rather than relying on pragma auto-detection — and MUST be
# set before qt_add_qml_module() runs, since it reads this property
# synchronously while processing QML_FILES, not lazily.
set_source_files_properties(
    qml/theme/Theme.qml
    qml/animations/MotionTokens.qml
    qml/state/DemoState.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(kilas
    URI Kilas
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/Island.qml
        qml/DemoController.qml
        qml/components/GlassSurface.qml
        qml/components/MusicWidget.qml
        qml/components/Waveform.qml
        qml/components/NotificationPill.qml
        qml/components/QuickAction.qml
        qml/panels/HomePanel.qml
        qml/panels/MusicPanel.qml
        qml/panels/ToolsPanel.qml
        qml/animations/MotionTokens.qml
        qml/theme/Theme.qml
        qml/state/DemoState.qml
    SOURCES
        src/AppController.h
        src/AppController.cpp
)

set_target_properties(kilas PROPERTIES
    WIN32_EXECUTABLE $<IF:$<CONFIG:Debug>,FALSE,TRUE>
    MACOSX_BUNDLE TRUE
)

# qt_add_qml_module's generated type-registration code does
# `#if __has_include(<AppController.h>)`, an angle-bracket include that
# only resolves against -I directories (never the including file's own
# directory) — src/ must be on the include path or QML_ELEMENT/
# QML_SINGLETON headers silently fail that check and the type is never
# registered.
target_include_directories(kilas PRIVATE src)

target_link_libraries(kilas PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)
