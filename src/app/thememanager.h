#pragma once

#include <QObject>
#include <QVariantMap>

class QStyleHints;

namespace hyps {

class AppSettings;

/**
 * 主题控制：跟随系统 color-scheme（Qt 6 在 Wayland/GNOME/KDE 下可用），
 * 也允许用户手动固定浅色/深色。颜色令牌以 QVariantMap 形式提供给 QML。
 */
class ThemeManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString preference READ preference WRITE setPreference NOTIFY preferenceChanged)
    Q_PROPERTY(bool dark READ dark NOTIFY darkChanged)
    Q_PROPERTY(bool systemDark READ systemDark NOTIFY systemDarkChanged)
    Q_PROPERTY(QVariantMap colors READ colors NOTIFY darkChanged)

public:
    explicit ThemeManager(AppSettings *settings, QObject *parent = nullptr);

    QString preference() const { return m_preference; }
    void setPreference(const QString &preference);

    bool dark() const;
    bool systemDark() const;
    QVariantMap colors() const;

signals:
    void preferenceChanged();
    void darkChanged();
    void systemDarkChanged();

private:
    void readSystemScheme();
    void applyQtHints();

    AppSettings *m_settings = nullptr;
    QString m_preference = QStringLiteral("system");
    bool m_systemDark = false;
};

} // namespace hyps
