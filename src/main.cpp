#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("KILAS"));
    app.setOrganizationName(QStringLiteral("KILAS"));
    app.setApplicationVersion(QStringLiteral("0.1.0"));

    // Basic, non-decorated style — the island paints its own chrome.
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, [] { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("Kilas", "Main");

    return app.exec();
}
