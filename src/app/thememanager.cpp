#include "app/thememanager.h"

#include "app/appsettings.h"

#include <QGuiApplication>
#include <QColor>
#include <QPalette>
#include <QStyleHints>

namespace hyps {

namespace {

/*
 * Material Design 3 基线配色（官方 baseline scheme，light / dark 两套）。
 *
 * 令牌名沿用 MD3 规范里的 color role 命名，QML 侧通过 Theme.colors.<role> 访问，
 * 例如 Theme.colors.primary / Theme.colors.surfaceContainerHigh。
 * 另加 4 组 MD3 规范之外但界面必需的语义扩展角色（success / warning 及其容器），
 * 色值取自 Material tonal palette 的 40/90（浅色）与 80/30（深色）档位。
 */
struct Md3Scheme
{
    const char *role;
    const char *light;
    const char *dark;
};

constexpr Md3Scheme kMd3Scheme[] = {
    // Primary
    { "primary", "#6750a4", "#d0bcff" },
    { "onPrimary", "#ffffff", "#381e72" },
    { "primaryContainer", "#eaddff", "#4f378b" },
    { "onPrimaryContainer", "#21005d", "#eaddff" },
    // Secondary
    { "secondary", "#625b71", "#ccc2dc" },
    { "onSecondary", "#ffffff", "#332d41" },
    { "secondaryContainer", "#e8def8", "#4a4458" },
    { "onSecondaryContainer", "#1d192b", "#e8def8" },
    // Tertiary
    { "tertiary", "#7d5260", "#efb8c8" },
    { "onTertiary", "#ffffff", "#492532" },
    { "tertiaryContainer", "#ffd8e4", "#633b48" },
    { "onTertiaryContainer", "#31111d", "#ffd8e4" },
    // Error
    { "error", "#b3261e", "#f2b8b5" },
    { "onError", "#ffffff", "#601410" },
    { "errorContainer", "#f9dedc", "#8c1d18" },
    { "onErrorContainer", "#410e0b", "#f9dedc" },
    // Success（MD3 扩展）
    { "success", "#146c2e", "#8bd89b" },
    { "onSuccess", "#ffffff", "#00390f" },
    { "successContainer", "#a6f4b6", "#0b5220" },
    { "onSuccessContainer", "#002204", "#a6f4b6" },
    // Warning（MD3 扩展）
    { "warning", "#7a5900", "#f2c14e" },
    { "onWarning", "#ffffff", "#402d00" },
    { "warningContainer", "#ffdf9e", "#5c4300" },
    { "onWarningContainer", "#261a00", "#ffdf9e" },
    // Surface
    { "surface", "#fef7ff", "#141218" },
    { "onSurface", "#1d1b20", "#e6e0e9" },
    { "surfaceDim", "#ded8e1", "#141218" },
    { "surfaceBright", "#fef7ff", "#3b383e" },
    { "surfaceContainerLowest", "#ffffff", "#0f0d13" },
    { "surfaceContainerLow", "#f7f2fa", "#1d1b20" },
    { "surfaceContainer", "#f3edf7", "#211f26" },
    { "surfaceContainerHigh", "#ece6f0", "#2b2930" },
    { "surfaceContainerHighest", "#e6e0e9", "#36343b" },
    { "onSurfaceVariant", "#49454f", "#cac4d0" },
    // Outline
    { "outline", "#79747e", "#938f99" },
    { "outlineVariant", "#cac4d0", "#49454f" },
    // Inverse
    { "inverseSurface", "#322f35", "#e6e0e9" },
    { "inverseOnSurface", "#f5eff7", "#313033" },
    { "inversePrimary", "#d0bcff", "#6750a4" },
    // Utility
    { "scrim", "#000000", "#000000" },
    { "shadow", "#000000", "#000000" },
    // 代码/日志面板底色
    { "codeSurface", "#f7f2fa", "#0f0d13" },
    // 旧令牌兼容别名：surfaceVariant 在 MD3 中已改名为 surfaceContainerHighest
    { "surfaceVariant", "#e6e0e9", "#36343b" },
    { "background", "#fef7ff", "#141218" },
    { "onBackground", "#1d1b20", "#e6e0e9" },
};

QString pick(const Md3Scheme &entry, bool dark)
{
    return QString::fromLatin1(dark ? entry.dark : entry.light);
}

} // namespace

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
    // 让 Qt 内部控件（输入法候选、原生菜单、文件对话框）贴近 MD3 配色。
    QPalette palette;
    const QVariantMap c = colors();
    const auto role = [&c](const char *name) {
        return QColor(c.value(QString::fromLatin1(name)).toString());
    };

    palette.setColor(QPalette::Window, role("surface"));
    palette.setColor(QPalette::WindowText, role("onSurface"));
    palette.setColor(QPalette::Base, role("surfaceContainerLowest"));
    palette.setColor(QPalette::AlternateBase, role("surfaceContainerLow"));
    palette.setColor(QPalette::Text, role("onSurface"));
    palette.setColor(QPalette::PlaceholderText, role("onSurfaceVariant"));
    palette.setColor(QPalette::Button, role("surfaceContainerHigh"));
    palette.setColor(QPalette::ButtonText, role("onSurface"));
    palette.setColor(QPalette::Highlight, role("primary"));
    palette.setColor(QPalette::HighlightedText, role("onPrimary"));
    palette.setColor(QPalette::ToolTipBase, role("inverseSurface"));
    palette.setColor(QPalette::ToolTipText, role("inverseOnSurface"));
    palette.setColor(QPalette::Link, role("primary"));
    palette.setColor(QPalette::Disabled, QPalette::Text, role("onSurfaceVariant"));
    palette.setColor(QPalette::Disabled, QPalette::ButtonText, role("onSurfaceVariant"));
    palette.setColor(QPalette::Disabled, QPalette::WindowText, role("onSurfaceVariant"));
    QGuiApplication::setPalette(palette);
}

QVariantMap ThemeManager::colors() const
{
    const bool isDark = dark();
    QVariantMap c;
    for (const Md3Scheme &entry : kMd3Scheme) {
        c.insert(QString::fromLatin1(entry.role), pick(entry, isDark));
    }
    c.insert(QStringLiteral("dark"), isDark);
    return c;
}

} // namespace hyps
