#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QTimer>

// Demonstrates the project's C++/QML integration pattern (see the
// qt-qml-expert skill): QML_SINGLETON + QML_ELEMENT registration,
// Q_PROPERTY with NOTIFY, Q_INVOKABLE methods, and a QTimer-driven
// background task exposed declaratively to QML. Backs the Quick Tools
// "Focus Timer" demo card — the one piece of real (non-mocked) C++
// logic in this prototype.
class AppController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString platformName READ platformName CONSTANT)
    Q_PROPERTY(QString qtRuntimeVersion READ qtRuntimeVersion CONSTANT)
    Q_PROPERTY(int focusSecondsRemaining READ focusSecondsRemaining NOTIFY focusSecondsRemainingChanged)
    Q_PROPERTY(bool focusTimerRunning READ focusTimerRunning NOTIFY focusTimerRunningChanged)

public:
    explicit AppController(QObject *parent = nullptr);

    QString platformName() const;
    QString qtRuntimeVersion() const;
    int focusSecondsRemaining() const { return m_secondsRemaining; }
    bool focusTimerRunning() const { return m_timer.isActive(); }

    Q_INVOKABLE void startFocusTimer(int minutes);
    Q_INVOKABLE void stopFocusTimer();

signals:
    void focusSecondsRemainingChanged();
    void focusTimerRunningChanged();
    void focusTimerFinished();

private:
    void tick();

    QTimer m_timer;
    int m_secondsRemaining = 0;
};
