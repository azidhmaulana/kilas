#include "AppController.h"

#include <QtGlobal>

AppController::AppController(QObject *parent)
    : QObject(parent)
{
    m_timer.setInterval(1000);
    connect(&m_timer, &QTimer::timeout, this, &AppController::tick);
}

QString AppController::platformName() const
{
#if defined(Q_OS_WIN)
    return QStringLiteral("Windows");
#elif defined(Q_OS_MACOS)
    return QStringLiteral("macOS");
#elif defined(Q_OS_LINUX)
    return QStringLiteral("Linux");
#else
    return QStringLiteral("Unknown");
#endif
}

QString AppController::qtRuntimeVersion() const
{
    return QString::fromLatin1(qVersion());
}

void AppController::startFocusTimer(int minutes)
{
    if (minutes <= 0)
        return;

    m_secondsRemaining = minutes * 60;
    emit focusSecondsRemainingChanged();

    if (!m_timer.isActive()) {
        m_timer.start();
        emit focusTimerRunningChanged();
    }
}

void AppController::stopFocusTimer()
{
    const bool wasRunning = m_timer.isActive();
    m_timer.stop();
    m_secondsRemaining = 0;
    emit focusSecondsRemainingChanged();
    if (wasRunning)
        emit focusTimerRunningChanged();
}

void AppController::tick()
{
    if (m_secondsRemaining <= 1) {
        m_secondsRemaining = 0;
        emit focusSecondsRemainingChanged();
        m_timer.stop();
        emit focusTimerRunningChanged();
        emit focusTimerFinished();
        return;
    }

    --m_secondsRemaining;
    emit focusSecondsRemainingChanged();
}
