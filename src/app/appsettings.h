#pragma once

#include <QObject>
#include <QVariantMap>
#include <QString>

namespace hyps {

/**
 * GUI 自身配置（JSON，位于 $XDG_CONFIG_HOME/hyps-hub/config.json）。
 *
 * 与 Hyps CLI 的配置完全分离。配置损坏时保留原文件并回退默认值，
 * 通过 loadWarning 告知界面。
 */
class AppSettings : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(bool notificationsEnabled READ notificationsEnabled WRITE setNotificationsEnabled
                       NOTIFY notificationsEnabledChanged)
    Q_PROPERTY(bool advancedMode READ advancedMode WRITE setAdvancedMode NOTIFY advancedModeChanged)
    Q_PROPERTY(QString lastPage READ lastPage WRITE setLastPage NOTIFY lastPageChanged)
    Q_PROPERTY(QString loadWarning READ loadWarning NOTIFY loadWarningChanged)

public:
    explicit AppSettings(QString filePath, QObject *parent = nullptr);

    bool load();
    bool save(QString *error = nullptr);

    QString theme() const;
    void setTheme(const QString &theme);

    bool notificationsEnabled() const;
    void setNotificationsEnabled(bool enabled);

    bool advancedMode() const;
    void setAdvancedMode(bool enabled);

    QString lastPage() const;
    void setLastPage(const QString &page);

    QString loadWarning() const { return m_loadWarning; }

    Q_INVOKABLE QVariantMap windowGeometry() const;
    Q_INVOKABLE void saveWindowGeometry(int x, int y, int width, int height, bool maximized);

    QString filePath() const { return m_filePath; }

signals:
    void themeChanged();
    void notificationsEnabledChanged();
    void advancedModeChanged();
    void lastPageChanged();
    void loadWarningChanged();

private:
    QVariantMap defaults() const;
    QVariant value(const QString &key, const QVariant &fallback) const;
    void setValue(const QString &key, const QVariant &value);

    QString m_filePath;
    QVariantMap m_data;
    QString m_loadWarning;
};

} // namespace hyps
