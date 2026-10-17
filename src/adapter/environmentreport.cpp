#include "adapter/environmentreport.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QSaveFile>

namespace hyps {

namespace {

QString stripAnsi(const QString &text)
{
    static const QRegularExpression ansi(QStringLiteral("\\x1b\\[[0-9;?]*[A-Za-z]"));
    QString result = text;
    result.remove(ansi);
    return result;
}

QString statusFromIcon(const QString &icon)
{
    if (icon == QStringLiteral("✓")) {
        return QStringLiteral("ok");
    }
    if (icon == QStringLiteral("!")) {
        return QStringLiteral("warn");
    }
    if (icon == QStringLiteral("✗")) {
        return QStringLiteral("fail");
    }
    return QStringLiteral("info");
}

} // namespace

EnvironmentReport::EnvironmentReport(QObject *parent)
    : QObject(parent)
{
}

QString EnvironmentReport::checkedAtText() const
{
    if (!m_checkedAt.isValid()) {
        return tr("尚未检测");
    }
    return m_checkedAt.toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"));
}

QString EnvironmentReport::summaryText() const
{
    if (!m_hasReport) {
        return tr("尚未检测");
    }
    QString text = tr("必需项 %1/%2 通过").arg(m_requiredPassed).arg(m_requiredTotal);
    if (m_requiredFailed > 0) {
        text += tr("，%1 项缺失").arg(m_requiredFailed);
    }
    if (m_warnings > 0) {
        text += tr("，可选能力缺失 %1 项").arg(m_warnings);
    }
    if (m_configWarnings > 0) {
        text += tr("，配置待创建 %1 项").arg(m_configWarnings);
    }
    return text;
}

void EnvironmentReport::parse(const QString &text, const QDateTime &checkedAt)
{
    m_rawText = stripAnsi(text);
    m_checkedAt = checkedAt;
    m_groups.clear();
    m_requiredTotal = 0;
    m_requiredPassed = 0;
    m_requiredFailed = 0;
    m_warnings = 0;
    m_configWarnings = 0;
    m_hasReport = false;

    static const QRegularExpression itemRe(
            QStringLiteral("^\\s{2,}\\[([^\\]]+)\\]\\s+(.*)$"));
    static const QRegularExpression splitRe(
            QStringLiteral("^(\\S.*?)\\s{2,}(\\S.*)$"));
    static const QRegularExpression requiredRe(
            QStringLiteral("必需项[:：]\\s*(\\d+)\\s*/\\s*(\\d+)\\s*通过"));
    static const QRegularExpression warnRe(
            QStringLiteral("可选能力缺失[:：]\\s*(\\d+)"));
    static const QRegularExpression configWarnRe(
            QStringLiteral("配置待创建[:：]\\s*(\\d+)"));

    QString currentGroup;
    QVariantList currentItems;
    int parsedItems = 0;

    auto flushGroup = [this, &currentGroup, &currentItems]() {
        if (currentItems.isEmpty()) {
            return;
        }
        QVariantMap group;
        group.insert(QStringLiteral("title"),
                     currentGroup.isEmpty() ? tr("其他") : currentGroup);
        group.insert(QStringLiteral("items"), currentItems);
        m_groups.append(group);
        currentItems.clear();
    };

    const QStringList lines = m_rawText.split(QLatin1Char('\n'));
    for (const QString &rawLine : lines) {
        const QString line = rawLine.trimmed().isEmpty() ? QString() : rawLine;
        if (line.isEmpty()) {
            continue;
        }

        // 报表标题与表格分隔行。
        if (line.startsWith(QLatin1String("[Hyps]"))) {
            continue;
        }

        const auto requiredMatch = requiredRe.match(line);
        if (requiredMatch.hasMatch()) {
            m_requiredPassed = requiredMatch.captured(1).toInt();
            m_requiredTotal = requiredMatch.captured(2).toInt();
            m_requiredFailed = qMax(0, m_requiredTotal - m_requiredPassed);
            m_hasReport = true;
            continue;
        }
        const auto warnMatch = warnRe.match(line);
        if (warnMatch.hasMatch()) {
            m_warnings = warnMatch.captured(1).toInt();
            m_hasReport = true;
            continue;
        }
        const auto configWarnMatch = configWarnRe.match(line);
        if (configWarnMatch.hasMatch()) {
            m_configWarnings = configWarnMatch.captured(1).toInt();
            m_hasReport = true;
            continue;
        }

        const auto itemMatch = itemRe.match(line);
        if (itemMatch.hasMatch()) {
            const QString icon = itemMatch.captured(1).trimmed();
            const QString body = itemMatch.captured(2).trimmed();
            QString name;
            QString detail;
            const auto splitMatch = splitRe.match(body);
            if (splitMatch.hasMatch()) {
                name = splitMatch.captured(1).trimmed();
                detail = splitMatch.captured(2).trimmed();
            } else {
                name = body;
            }

            QVariantMap item;
            item.insert(QStringLiteral("status"), statusFromIcon(icon));
            item.insert(QStringLiteral("name"), name);
            item.insert(QStringLiteral("detail"), detail);
            currentItems.append(item);
            ++parsedItems;
            m_hasReport = true;
            continue;
        }

        // 非条目、非统计的行视为分组标题。
        if (!line.startsWith(QLatin1Char(' ')) && !line.startsWith(QLatin1Char('\t'))) {
            flushGroup();
            currentGroup = line.trimmed();
        }
    }
    flushGroup();

    if (parsedItems == 0 && !m_rawText.trimmed().isEmpty() && m_requiredTotal == 0) {
        // 无法识别结构时保留原始输出，界面会展示 rawText。
        m_hasReport = true;
    }

    emit changed();
}

void EnvironmentReport::clear()
{
    m_groups.clear();
    m_rawText.clear();
    m_checkedAt = QDateTime();
    m_requiredTotal = 0;
    m_requiredPassed = 0;
    m_requiredFailed = 0;
    m_warnings = 0;
    m_configWarnings = 0;
    m_hasReport = false;
    emit changed();
}

bool EnvironmentReport::saveToFile(const QString &path) const
{
    QDir().mkpath(QFileInfo(path).absolutePath());
    QJsonObject object;
    object.insert(QStringLiteral("checkedAt"), m_checkedAt.toString(Qt::ISODateWithMs));
    object.insert(QStringLiteral("requiredTotal"), m_requiredTotal);
    object.insert(QStringLiteral("requiredPassed"), m_requiredPassed);
    object.insert(QStringLiteral("requiredFailed"), m_requiredFailed);
    object.insert(QStringLiteral("warnings"), m_warnings);
    object.insert(QStringLiteral("configWarnings"), m_configWarnings);
    object.insert(QStringLiteral("rawText"), m_rawText);
    object.insert(QStringLiteral("groups"), QJsonArray::fromVariantList(m_groups));

    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        return false;
    }
    file.write(QJsonDocument(object).toJson(QJsonDocument::Indented));
    return file.commit();
}

bool EnvironmentReport::loadFromFile(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return false;
    }
    QJsonParseError error{};
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &error);
    if (error.error != QJsonParseError::NoError || !document.isObject()) {
        return false;
    }
    const QJsonObject object = document.object();
    m_rawText = object.value(QStringLiteral("rawText")).toString();
    m_groups = object.value(QStringLiteral("groups")).toArray().toVariantList();
    m_requiredTotal = object.value(QStringLiteral("requiredTotal")).toInt();
    m_requiredPassed = object.value(QStringLiteral("requiredPassed")).toInt();
    m_requiredFailed = object.value(QStringLiteral("requiredFailed")).toInt();
    m_warnings = object.value(QStringLiteral("warnings")).toInt();
    m_configWarnings = object.value(QStringLiteral("configWarnings")).toInt();
    m_checkedAt = QDateTime::fromString(object.value(QStringLiteral("checkedAt")).toString(),
                                       Qt::ISODateWithMs);
    m_hasReport = !m_groups.isEmpty() || !m_rawText.isEmpty();
    emit changed();
    return true;
}

} // namespace hyps
