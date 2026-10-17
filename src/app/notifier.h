#pragma once

#include <QObject>
#include <QString>

namespace hyps {

/**
 * 桌面通知（可选能力）。通过 org.freedesktop.Notifications D-Bus 服务发送，
 * 服务不可用时静默降级，不阻塞界面。
 */
class Notifier : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available CONSTANT)

public:
    explicit Notifier(QObject *parent = nullptr);

    bool available() const { return m_available; }

    Q_INVOKABLE void notify(const QString &title, const QString &body);

private:
    bool m_available = false;
};

} // namespace hyps
