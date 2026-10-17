#include "app/thememanager.h"

#include "app/appsettings.h"

#include <QGuiApplication>
#include <QColor>
#include <QPalette>
#include <QStyleHints>

namespace hyps {

ThemeManager::ThemeManager(AppSettings *settings, QObject *parent)
    : QObject(parent)
    , m_settings(settings)
{
    m_preference = settings ? settings->theme() : QStringLiteral("system");

    if (settings) {
        connect(settings, &AppSettings::themeChanged, this, [this]() {
            const QString preference = m_settings->theme();
            if (m_preference == preference) {
                return;
            }
            m_preference = preference;
            applyQtHints();
            emit preferenceChanged();
            emit darkChanged();
        });
    }

    if (auto *hints = QGuiApplication::styleHints()) {
        connect(hints, &QStyleHints::colorSchemeChanged, this,
                [this](Qt::ColorScheme) {
                    readSystemScheme();
                    applyQtHints();
                    emit darkChanged();
                });
    }

    readSystemScheme();
    applyQtHints();
}

void ThemeManager::readSystemScheme()
{
    bool systemDark = false;
    if (const auto *hints = QGuiApplication::styleHints()) {
        switch (hints->colorScheme()) {
        case Qt::ColorScheme::Dark:
            systemDark = true;
            break;
        case Qt::ColorScheme::Light:
            systemDark = false;
            break;
        case Qt::ColorScheme::Unknown:
            systemDark = false;
            break;
        }
    }
    if (m_systemDark != systemDark) {
        m_systemDark = systemDark;
        emit systemDarkChanged();
    }
}

bool ThemeManager::systemDark() const
{
    return m_systemDark;
}

bool ThemeManager::dark() const
{
    if (m_preference == QLatin1String("dark")) {
        return true;
    }
    if (m_preference == QLatin1String("light")) {
        return false;
    }
    return m_systemDark;
}

void ThemeManager::setPreference(const QString &preference)
{
    if (m_preference == preference || preference.isEmpty()) {
        return;
    }
    if (preference != QLatin1String("system") && preference != QLatin1String("light")
        && preference != QLatin1String("dark")) {
        return;
    }
    m_preference = preference;
    if (m_settings) {
        m_settings->setTheme(preference);
    }
    applyQtHints();
    emit preferenceChanged();
    emit darkChanged();
}

void ThemeManager::applyQtHints()
{
    // 让 Qt 内部控件（输入法候选、原生菜单等）尽量贴近应用主题。
    QPalette palette;
    const QVariantMap c = colors();
    palette.setColor(QPalette::Window, QColor(c.value(QStringLiteral("ink")).toString()));
    palette.setColor(QPalette::WindowText, QColor(c.value(QStringLiteral("paper")).toString()));
    palette.setColor(QPalette::Base, QColor(c.value(QStringLiteral("ink2")).toString()));
    palette.setColor(QPalette::AlternateBase, QColor(c.value(QStringLiteral("ink3")).toString()));
    palette.setColor(QPalette::Text, QColor(c.value(QStringLiteral("paper2")).toString()));
    palette.setColor(QPalette::Button, QColor(c.value(QStringLiteral("ink2")).toString()));
    palette.setColor(QPalette::ButtonText, QColor(c.value(QStringLiteral("paper2")).toString()));
    palette.setColor(QPalette::Highlight, QColor(c.value(QStringLiteral("signal")).toString()));
    palette.setColor(QPalette::HighlightedText,
                     QColor(c.value(QStringLiteral("onSignal")).toString()));
    palette.setColor(QPalette::ToolTipBase, QColor(c.value(QStringLiteral("ink3")).toString()));
    palette.setColor(QPalette::ToolTipText, QColor(c.value(QStringLiteral("paper")).toString()));
    QGuiApplication::setPalette(palette);
}

QVariantMap ThemeManager::colors() const
{
    const bool isDark = dark();
    QVariantMap c;

    // Ark 设计令牌：近黑墨底 + 纸阶文字 + 单一青色信号 + 酸性绿状态。
    // 浅色模式沿用同一几何语言，只反转墨/纸阶并提高信号色对比度。
    if (isDark) {
        c.insert(QStringLiteral("ink"), QStringLiteral("#080a0b"));
        c.insert(QStringLiteral("ink2"), QStringLiteral("#0e1112"));
        c.insert(QStringLiteral("ink3"), QStringLiteral("#141819"));
        c.insert(QStringLiteral("ink4"), QStringLiteral("#1a1f21"));
        c.insert(QStringLiteral("rule"), QStringLiteral("#242a2d"));
        c.insert(QStringLiteral("line"), QStringLiteral("#333b3f"));
        c.insert(QStringLiteral("lineHover"), QStringLiteral("#4a5459"));

        c.insert(QStringLiteral("paper"), QStringLiteral("#f4f6f6"));
        c.insert(QStringLiteral("paper2"), QStringLiteral("#c3cbcd"));
        c.insert(QStringLiteral("muted"), QStringLiteral("#8d9396"));
        c.insert(QStringLiteral("disabled"), QStringLiteral("#5a6165"));

        c.insert(QStringLiteral("signal"), QStringLiteral("#18d1ff"));
        c.insert(QStringLiteral("signalPressed"), QStringLiteral("#0f9dc4"));
        c.insert(QStringLiteral("signalDim"), QStringLiteral("#1f18d1ff"));
        c.insert(QStringLiteral("onSignal"), QStringLiteral("#080a0b"));
        c.insert(QStringLiteral("state"), QStringLiteral("#c8eb21"));
        c.insert(QStringLiteral("onState"), QStringLiteral("#080a0b"));
        c.insert(QStringLiteral("warn"), QStringLiteral("#e0a34a"));
        c.insert(QStringLiteral("danger"), QStringLiteral("#e0524f"));

        c.insert(QStringLiteral("codeBg"), QStringLiteral("#0a0d0e"));
        c.insert(QStringLiteral("overlay"), QStringLiteral("#080a0bcc"));
        c.insert(QStringLiteral("scrollbar"), QStringLiteral("#333b3f"));
        c.insert(QStringLiteral("gridLine"), QStringLiteral("#0af4f6f6"));
        c.insert(QStringLiteral("stripe"), QStringLiteral("#23f4f6f6"));
        c.insert(QStringLiteral("vignette"), QStringLiteral("#000000"));
    } else {
        c.insert(QStringLiteral("ink"), QStringLiteral("#eceeef"));
        c.insert(QStringLiteral("ink2"), QStringLiteral("#f7f8f8"));
        c.insert(QStringLiteral("ink3"), QStringLiteral("#e3e6e7"));
        c.insert(QStringLiteral("ink4"), QStringLiteral("#d8ddde"));
        c.insert(QStringLiteral("rule"), QStringLiteral("#d2d8da"));
        c.insert(QStringLiteral("line"), QStringLiteral("#b6bfc2"));
        c.insert(QStringLiteral("lineHover"), QStringLiteral("#95a1a5"));

        c.insert(QStringLiteral("paper"), QStringLiteral("#0d1113"));
        c.insert(QStringLiteral("paper2"), QStringLiteral("#2f383b"));
        c.insert(QStringLiteral("muted"), QStringLiteral("#667175"));
        c.insert(QStringLiteral("disabled"), QStringLiteral("#98a2a5"));

        c.insert(QStringLiteral("signal"), QStringLiteral("#0b7f9d"));
        c.insert(QStringLiteral("signalPressed"), QStringLiteral("#08657d"));
        c.insert(QStringLiteral("signalDim"), QStringLiteral("#1a0b7f9d"));
        c.insert(QStringLiteral("onSignal"), QStringLiteral("#f7fafa"));
        c.insert(QStringLiteral("state"), QStringLiteral("#7c9900"));
        c.insert(QStringLiteral("onState"), QStringLiteral("#f7fafa"));
        c.insert(QStringLiteral("warn"), QStringLiteral("#94600f"));
        c.insert(QStringLiteral("danger"), QStringLiteral("#b23a37"));

        c.insert(QStringLiteral("codeBg"), QStringLiteral("#f2f4f4"));
        c.insert(QStringLiteral("overlay"), QStringLiteral("#eceeefdd"));
        c.insert(QStringLiteral("scrollbar"), QStringLiteral("#b6bfc2"));
        c.insert(QStringLiteral("gridLine"), QStringLiteral("#0a0d1113"));
        c.insert(QStringLiteral("stripe"), QStringLiteral("#230d1113"));
        c.insert(QStringLiteral("vignette"), QStringLiteral("#ffffff"));
    }

    c.insert(QStringLiteral("dark"), isDark);
    return c;
}

} // namespace hyps
