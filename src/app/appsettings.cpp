#include "app/appsettings.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#include <QTimer>

namespace hyps {

AppSettings::AppSettings(QString filePath, QObject *parent)
    : QObject(parent)
    , m_filePath(std::move(filePath))
    , m_data(defaults())
{
}

QVariantMap AppSettings::defaults() const
{
    QVariantMap data;
    data.insert(QStringLiteral("version"), 1);
    data.insert(QStringLiteral("theme"), QStringLiteral("system"));
    data.insert(QStringLiteral("notificationsEnabled"), true);
    data.insert(QStringLiteral("advancedMode"), false);
    data.insert(QStringLiteral("lastPage"), QStringLiteral("home"));

    QVariantMap window;
    window.insert(QStringLiteral("x"), 0);
    window.insert(QStringLiteral("y"), 0);
    window.insert(QStringLiteral("width"), 1180);
    window.insert(QStringLiteral("height"), 760);
    window.insert(QStringLiteral("maximized"), false);
    data.insert(QStringLiteral("window"), window);
    return data;
}

bool AppSettings::load()
{
    m_loadWarning.clear();
    m_data = defaults();

    QFile file(m_filePath);
    if (!file.exists()) {
        return true;
    }
    if (!file.open(QIODevice::ReadOnly)) {
        m_loadWarning = QStringLiteral("无法读取配置文件 %1：%2（使用默认设置）")
                                .arg(m_filePath, file.errorString());
        emit loadWarningChanged();
        return false;
    }

    QJsonParseError parseError{};
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &parseError);
    file.close();

    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        const QString backup = m_filePath
                + QStringLiteral(".corrupt.")
                + QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMddHHmmss"));
        QFile::copy(m_filePath, backup);
        m_loadWarning = QStringLiteral("GUI 配置文件损坏（%1），已备份到 %2，当前使用默认设置。")
                                .arg(parseError.errorString(), backup);
        emit loadWarningChanged();
        return false;
    }

    const QJsonObject object = document.object();
    for (auto it = object.begin(); it != object.end(); ++it) {
        m_data.insert(it.key(), it.value().toVariant());
    }
    if (!m_data.value(QStringLiteral("window")).toMap().isEmpty()) {
        QVariantMap merged = defaults().value(QStringLiteral("window")).toMap();
        const QVariantMap loaded = m_data.value(QStringLiteral("window")).toMap();
        for (auto it = loaded.begin(); it != loaded.end(); ++it) {
            merged.insert(it.key(), it.value());
        }
        m_data.insert(QStringLiteral("window"), merged);
    }
    return true;
}

bool AppSettings::save(QString *error)
{
    QDir().mkpath(QFileInfo(m_filePath).absolutePath());

    QSaveFile file(m_filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        if (error) {
            *error = QStringLiteral("无法写入 %1：%2").arg(m_filePath, file.errorString());
        }
        return false;
    }
    const QJsonDocument document(QJsonObject::fromVariantMap(m_data));
    file.write(document.toJson(QJsonDocument::Indented));
    if (!file.commit()) {
        if (error) {
            *error = QStringLiteral("保存配置失败：%1").arg(file.errorString());
        }
        return false;
    }
    return true;
}

QVariant AppSettings::value(const QString &key, const QVariant &fallback) const
{
    const auto it = m_data.constFind(key);
    if (it == m_data.constEnd() || !it.value().isValid()) {
        return fallback;
    }
    return it.value();
}

void AppSettings::setValue(const QString &key, const QVariant &newValue)
{
    m_data.insert(key, newValue);
    save();
}

QString AppSettings::theme() const
{
    const QString value = m_data.value(QStringLiteral("theme")).toString();
    if (value != QLatin1String("system") && value != QLatin1String("light")
        && value != QLatin1String("dark")) {
        return QStringLiteral("system");
    }
    return value;
}

void AppSettings::setTheme(const QString &newTheme)
{
    if (theme() == newTheme) {
        return;
    }
    setValue(QStringLiteral("theme"), newTheme);
    emit themeChanged();
}

bool AppSettings::notificationsEnabled() const
{
    return value(QStringLiteral("notificationsEnabled"), true).toBool();
}

void AppSettings::setNotificationsEnabled(bool enabled)
{
    if (notificationsEnabled() == enabled) {
        return;
    }
    setValue(QStringLiteral("notificationsEnabled"), enabled);
    emit notificationsEnabledChanged();
}

bool AppSettings::advancedMode() const
{
    return value(QStringLiteral("advancedMode"), false).toBool();
}

void AppSettings::setAdvancedMode(bool enabled)
{
    if (advancedMode() == enabled) {
        return;
    }
    setValue(QStringLiteral("advancedMode"), enabled);
    emit advancedModeChanged();
}

QString AppSettings::lastPage() const
{
    return value(QStringLiteral("lastPage"), QStringLiteral("home")).toString();
}

void AppSettings::setLastPage(const QString &page)
{
    if (lastPage() == page || page.isEmpty()) {
        return;
    }
    setValue(QStringLiteral("lastPage"), page);
    emit lastPageChanged();
}

QVariantMap AppSettings::windowGeometry() const
{
    return value(QStringLiteral("window"), defaults().value(QStringLiteral("window"))).toMap();
}

void AppSettings::saveWindowGeometry(int x, int y, int width, int height, bool maximized)
{
    QVariantMap window;
    window.insert(QStringLiteral("x"), x);
    window.insert(QStringLiteral("y"), y);
    window.insert(QStringLiteral("width"), width);
    window.insert(QStringLiteral("height"), height);
    window.insert(QStringLiteral("maximized"), maximized);
    m_data.insert(QStringLiteral("window"), window);
    save();
}

} // namespace hyps
