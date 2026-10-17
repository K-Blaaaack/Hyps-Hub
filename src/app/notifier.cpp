#include "app/notifier.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QVariantMap>

#include <memory>

namespace hyps {

Notifier::Notifier(QObject *parent)
    : QObject(parent)
{
    const QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.isConnected()) {
        return;
    }
    auto interface = std::make_unique<QDBusInterface>(
            QStringLiteral("org.freedesktop.Notifications"),
            QStringLiteral("/org/freedesktop/Notifications"),
            QStringLiteral("org.freedesktop.Notifications"),
            bus,
            this);
    m_available = interface->isValid();
}

void Notifier::notify(const QString &title, const QString &body)
{
    if (!m_available) {
        return;
    }
    auto *interface = new QDBusInterface(
            QStringLiteral("org.freedesktop.Notifications"),
            QStringLiteral("/org/freedesktop/Notifications"),
            QStringLiteral("org.freedesktop.Notifications"),
            QDBusConnection::sessionBus(),
            this);
    if (!interface->isValid()) {
        interface->deleteLater();
        return;
    }

    QVariantMap hints;
    hints.insert(QStringLiteral("desktop-entry"), QStringLiteral("hyps-hub"));
    interface->asyncCall(QStringLiteral("Notify"),
                         QStringLiteral("Hyps Hub"),
                         static_cast<uint>(0),
                         QStringLiteral("hyps-hub"),
                         title,
                         body,
                         QStringList(),
                         hints,
                         5000);
    interface->deleteLater();
}

} // namespace hyps
