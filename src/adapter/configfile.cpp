#include "adapter/configfile.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QSaveFile>
#include <QSet>

namespace hyps {

namespace {

QString stripTrailingComment(const QString &value)
{
    int inSingle = 0;
    int inDouble = 0;
    int escape = 0;
    for (int i = 0; i < value.size(); ++i) {
        const QChar ch = value.at(i);
        if (escape) {
            escape = 0;
            continue;
        }
        if (ch == QLatin1Char('\\') && inDouble) {
            escape = 1;
            continue;
        }
        if (ch == QLatin1Char('\'') && !inDouble) {
            inSingle = 1 - inSingle;
            continue;
        }
        if (ch == QLatin1Char('"') && !inSingle) {
            inDouble = 1 - inDouble;
            continue;
        }
        if (ch == QLatin1Char('#') && !inSingle && !inDouble) {
            QString result = value.left(i);
            while (!result.isEmpty() && result.back().isSpace()) {
                result.chop(1);
            }
            return result;
        }
    }
    return value;
}

bool unquoteValue(const QString &input, QString *output)
{
    if (input.size() >= 2) {
        const QChar first = input.front();
        const QChar last = input.back();
        if ((first == QLatin1Char('"') && last == QLatin1Char('"'))
            || (first == QLatin1Char('\'') && last == QLatin1Char('\''))) {
            *output = input.mid(1, input.size() - 2);
            return true;
        }
    }
    *output = input;
    return false;
}

QStringList splitTopLevel(const QString &value)
{
    QStringList parts;
    QString current;
    int inSingle = 0;
    int inDouble = 0;
    for (const QChar ch : value) {
        if (ch == QLatin1Char('\'') && !inDouble) {
            inSingle = 1 - inSingle;
            current += ch;
            continue;
        }
        if (ch == QLatin1Char('"') && !inSingle) {
            inDouble = 1 - inDouble;
            current += ch;
            continue;
        }
        if (ch == QLatin1Char(',') && !inSingle && !inDouble) {
            parts.append(current);
            current.clear();
            continue;
        }
        current += ch;
    }
    parts.append(current);
    return parts;
}

QStringList splitWhitespaceTopLevel(const QString &value)
{
    QStringList parts;
    QString current;
    int inSingle = 0;
    int inDouble = 0;
    for (const QChar ch : value) {
        if (ch == QLatin1Char('\'') && !inDouble) {
            inSingle = 1 - inSingle;
            current += ch;
            continue;
        }
        if (ch == QLatin1Char('"') && !inSingle) {
            inDouble = 1 - inDouble;
            current += ch;
            continue;
        }
        if (ch.isSpace() && !inSingle && !inDouble) {
            if (!current.isEmpty()) {
                parts.append(current);
                current.clear();
            }
            continue;
        }
        current += ch;
    }
    if (!current.isEmpty()) {
        parts.append(current);
    }
    return parts;
}

QStringList textToLines(const QString &text)
{
    QStringList lines = text.split(QLatin1Char('\n'));
    if (!lines.isEmpty() && lines.last().isEmpty()) {
        lines.removeLast();
    }
    return lines;
}

QString quoteIfNeeded(const QString &value)
{
    const QString trimmed = value.trimmed();
    if (trimmed.compare(QLatin1String("true"), Qt::CaseInsensitive) == 0
        || trimmed.compare(QLatin1String("false"), Qt::CaseInsensitive) == 0) {
        return trimmed;
    }
    static const QRegularExpression numberRe(QStringLiteral("^-?\\d+(?:\\.\\d+)?$"));
    if (numberRe.match(trimmed).hasMatch()) {
        return trimmed;
    }
    static const QRegularExpression plainRe(
            QStringLiteral("^[A-Za-z0-9_./:+@%^,-]+$"));
    if (plainRe.match(trimmed).hasMatch()) {
        return trimmed;
    }

    QString safe = value;
    safe.replace(QLatin1Char('\n'), QLatin1Char(' '));
    safe.replace(QLatin1Char('\r'), QLatin1Char(' '));
    return QLatin1Char('"') + safe + QLatin1Char('"');
}

} // namespace

ConfigFile::ConfigFile(QString filePath, QObject *parent)
    : QObject(parent)
    , m_filePath(std::move(filePath))
{
}

bool ConfigFile::load(QString *error)
{
    m_loadError.clear();
    m_warnings.clear();

    QFile file(m_filePath);
    if (!file.exists()) {
        m_text.clear();
        m_entries.clear();
        m_exists = false;
        m_dirty = false;
        emit changed();
        return true;
    }
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        m_loadError = tr("无法读取 %1：%2").arg(m_filePath, file.errorString());
        if (error) {
            *error = m_loadError;
        }
        emit changed();
        return false;
    }
    const QString text = QString::fromUtf8(file.readAll());
    file.close();

    m_exists = true;
    reparse(text);
    m_dirty = false;
    emit changed();
    return true;
}

QVariantMap ConfigFile::reload()
{
    QString error;
    const bool ok = load(&error);
    QVariantMap result;
    result.insert(QStringLiteral("ok"), ok);
    result.insert(QStringLiteral("error"), error);
    return result;
}

void ConfigFile::discardChanges()
{
    QString error;
    load(&error);
}

void ConfigFile::addWarning(const QString &warning)
{
    m_warnings.append(warning);
}

void ConfigFile::reparse(const QString &text)
{
    m_entries.clear();
    m_warnings.clear();
    m_text = text;

    const QStringList lines = textToLines(text);
    QString section;
    static const QRegularExpression sectionRe(QStringLiteral("^\\[([^\\]]+)\\]$"));

    for (int i = 0; i < lines.size(); ++i) {
        const QString trimmed = lines.at(i).trimmed();
        if (trimmed.isEmpty() || trimmed.startsWith(QLatin1Char('#'))) {
            continue;
        }

        const auto sectionMatch = sectionRe.match(trimmed);
        if (sectionMatch.hasMatch()) {
            section = sectionMatch.captured(1).trimmed();
            continue;
        }

        const int equals = trimmed.indexOf(QLatin1Char('='));
        if (equals <= 0) {
            addWarning(tr("第 %1 行缺少 key = value 结构，上游解析器会忽略该行").arg(i + 1));
            continue;
        }

        const QString bareKey = trimmed.left(equals).trimmed();
        if (bareKey.isEmpty() || bareKey.contains(QLatin1Char(' '))
            || bareKey.contains(QLatin1Char('\t'))) {
            addWarning(tr("第 %1 行的键名无效，上游解析器会忽略该行").arg(i + 1));
            continue;
        }

        const QString valueText = trimmed.mid(equals + 1).trimmed();
        const QString stripped = stripTrailingComment(valueText).trimmed();
        const int startLine = i;
        int endLine = i;
        bool array = false;
        QString combined = stripped;

        const bool multilineSquare = stripped.startsWith(QLatin1Char('['))
                && !stripped.contains(QLatin1Char(']'));
        const bool multilineParen = stripped.startsWith(QLatin1Char('('))
                && !stripped.contains(QLatin1Char(')'));
        if (multilineSquare || multilineParen) {
            const QChar close = multilineSquare ? QLatin1Char(']') : QLatin1Char(')');
            bool closed = false;
            for (int j = i + 1; j < lines.size(); ++j) {
                const QString candidate = lines.at(j).trimmed();
                if (candidate.isEmpty() || candidate.startsWith(QLatin1Char('#'))) {
                    continue;
                }
                const QString part = stripTrailingComment(candidate).trimmed();
                if (part.isEmpty()) {
                    continue;
                }
                combined += multilineSquare ? QStringLiteral(", ") : QStringLiteral(" ");
                combined += part;
                if (part.contains(close)) {
                    closed = true;
                    endLine = j;
                    break;
                }
            }
            if (!closed) {
                addWarning(tr("第 %1 行的数组 '%2' 未闭合，上游解析器会忽略该键")
                                   .arg(i + 1)
                                   .arg(bareKey));
                continue;
            }
            array = true;
            i = endLine;
        }

        // 单行 `[ ... ]` / `( ... )` 与多行数组在语义上一致。
        const bool arrayLike = (stripped.startsWith(QLatin1Char('['))
                                && stripped.endsWith(QLatin1Char(']')))
                || (stripped.startsWith(QLatin1Char('('))
                    && stripped.endsWith(QLatin1Char(')')));

        QString value;
        const bool quoted = unquoteValue(combined, &value);

        Entry entry;
        entry.bareKey = bareKey;
        entry.section = section;
        entry.key = section.isEmpty() ? bareKey : section + QLatin1Char('.') + bareKey;
        entry.startLine = startLine;
        entry.endLine = endLine;
        entry.rawValue = combined;
        entry.value = value;
        entry.array = array || arrayLike;
        entry.quoted = quoted;
        m_entries.append(entry);
    }
}

QVariantList ConfigFile::entries() const
{
    QVariantList list;
    list.reserve(m_entries.size());
    for (const Entry &entry : m_entries) {
        QVariantMap map;
        map.insert(QStringLiteral("key"), entry.key);
        map.insert(QStringLiteral("value"), entry.value);
        map.insert(QStringLiteral("rawValue"), entry.rawValue);
        map.insert(QStringLiteral("startLine"), entry.startLine + 1);
        map.insert(QStringLiteral("endLine"), entry.endLine + 1);
        map.insert(QStringLiteral("array"), entry.array);
        map.insert(QStringLiteral("quoted"), entry.quoted);
        map.insert(QStringLiteral("section"), entry.section);
        list.append(map);
    }
    return list;
}

QVariantMap ConfigFile::values() const
{
    QVariantMap map;
    for (const Entry &entry : m_entries) {
        map.insert(entry.key, entry.value);
    }
    return map;
}

QString ConfigFile::valueFor(const QString &key, const QString &fallback) const
{
    QString result = fallback;
    bool found = false;
    for (const Entry &entry : m_entries) {
        if (entry.key == key) {
            result = entry.value;
            found = true;
        }
    }
    return found ? result : fallback;
}

bool ConfigFile::hasKey(const QString &key) const
{
    for (const Entry &entry : m_entries) {
        if (entry.key == key) {
            return true;
        }
    }
    return false;
}

bool ConfigFile::isTrue(const QString &key) const
{
    const QString value = valueFor(key).trimmed().toLower();
    return value == QLatin1String("true") || value == QLatin1String("1")
            || value == QLatin1String("yes") || value == QLatin1String("on")
            || value == QLatin1String("enabled");
}

QStringList ConfigFile::keys() const
{
    QStringList result;
    QSet<QString> seen;
    for (const Entry &entry : m_entries) {
        if (seen.contains(entry.key)) {
            continue;
        }
        seen.insert(entry.key);
        result.append(entry.key);
    }
    return result;
}

QStringList ConfigFile::arrayValues(const QString &key) const
{
    const Entry *found = nullptr;
    for (const Entry &entry : m_entries) {
        if (entry.key == key) {
            found = &entry;
        }
    }
    if (!found) {
        return {};
    }
    if (!found->array) {
        return found->value.isEmpty() ? QStringList() : QStringList{found->value};
    }

    QString inner = found->value.trimmed();
    if (inner.startsWith(QLatin1Char('[')) && inner.endsWith(QLatin1Char(']'))) {
        inner = inner.mid(1, inner.size() - 2);
    } else if (inner.startsWith(QLatin1Char('(')) && inner.endsWith(QLatin1Char(')'))) {
        inner = inner.mid(1, inner.size() - 2);
    }

    QStringList raw = inner.contains(QLatin1Char(',')) ? splitTopLevel(inner)
                                                       : splitWhitespaceTopLevel(inner);
    QStringList result;
    for (const QString &part : raw) {
        const QString trimmed = part.trimmed();
        if (trimmed.isEmpty() || trimmed.startsWith(QLatin1Char('#'))) {
            continue;
        }
        QString value;
        unquoteValue(trimmed, &value);
        value = value.trimmed();
        if (!value.isEmpty()) {
            result.append(value);
        }
    }
    return result;
}

bool ConfigFile::commitText(const QString &newText)
{
    reparse(ensureTrailingNewline(newText));
    m_dirty = true;
    emit changed();
    return true;
}

bool ConfigFile::setValue(const QString &key, const QString &value)
{
    const QString trimmedKey = key.trimmed();
    if (trimmedKey.isEmpty() || trimmedKey.contains(QLatin1Char(' '))
        || trimmedKey.contains(QLatin1Char('='))) {
        return false;
    }

    QStringList lines = textToLines(m_text);
    int index = -1;
    for (int i = m_entries.size() - 1; i >= 0; --i) {
        if (m_entries.at(i).key == trimmedKey) {
            index = i;
            break;
        }
    }

    const QString replacement = trimmedKey + QStringLiteral(" = ") + quoteIfNeeded(value);
    if (index >= 0) {
        const Entry entry = m_entries.at(index);
        QStringList updated = lines.mid(0, entry.startLine);
        updated.append(replacement);
        updated += lines.mid(entry.endLine + 1);
        lines = updated;
    } else {
        lines.append(replacement);
    }
    return commitText(lines.join(QLatin1Char('\n')));
}

bool ConfigFile::setArray(const QString &key, const QStringList &values)
{
    const QString trimmedKey = key.trimmed();
    if (trimmedKey.isEmpty() || trimmedKey.contains(QLatin1Char(' '))
        || trimmedKey.contains(QLatin1Char('='))) {
        return false;
    }

    QStringList lines = textToLines(m_text);
    int index = -1;
    for (int i = m_entries.size() - 1; i >= 0; --i) {
        if (m_entries.at(i).key == trimmedKey) {
            index = i;
            break;
        }
    }

    const QStringList replacementLines = formatArray(trimmedKey, values).split(QLatin1Char('\n'));
    if (index >= 0) {
        const Entry entry = m_entries.at(index);
        QStringList updated = lines.mid(0, entry.startLine);
        updated += replacementLines;
        updated += lines.mid(entry.endLine + 1);
        lines = updated;
    } else {
        lines += replacementLines;
    }
    return commitText(lines.join(QLatin1Char('\n')));
}

QString ConfigFile::formatArray(const QString &bareKey, const QStringList &values) const
{
    QString text = bareKey + QStringLiteral(" = [\n");
    for (const QString &value : values) {
        text += QStringLiteral("    ") + quoteIfNeeded(value) + QStringLiteral(",\n");
    }
    text += QStringLiteral("]");
    return text;
}

bool ConfigFile::removeKey(const QString &key)
{
    int removed = 0;
    QStringList lines = textToLines(m_text);
    for (int i = m_entries.size() - 1; i >= 0; --i) {
        const Entry &entry = m_entries.at(i);
        if (entry.key != key) {
            continue;
        }
        QStringList updated = lines.mid(0, entry.startLine);
        updated += lines.mid(entry.endLine + 1);
        lines = updated;
        ++removed;
    }
    if (removed == 0) {
        return false;
    }
    return commitText(lines.join(QLatin1Char('\n')));
}

QVariantList ConfigFile::validate() const
{
    QVariantList issues;
    for (const QString &warning : m_warnings) {
        QVariantMap issue;
        issue.insert(QStringLiteral("level"), QStringLiteral("warning"));
        issue.insert(QStringLiteral("key"), QString());
        issue.insert(QStringLiteral("message"), warning);
        issues.append(issue);
    }

    QSet<QString> seen;
    QSet<QString> duplicated;
    for (const Entry &entry : m_entries) {
        if (seen.contains(entry.key) && !duplicated.contains(entry.key)) {
            duplicated.insert(entry.key);
            QVariantMap issue;
            issue.insert(QStringLiteral("level"), QStringLiteral("warning"));
            issue.insert(QStringLiteral("key"), entry.key);
            issue.insert(QStringLiteral("message"),
                         tr("键 '%1' 重复出现，上游解析器以最后一项为准").arg(entry.key));
            issues.append(issue);
        }
        seen.insert(entry.key);
    }
    return issues;
}

QVariantMap ConfigFile::save()
{
    QVariantMap result;
    if (!m_dirty) {
        result.insert(QStringLiteral("ok"), true);
        result.insert(QStringLiteral("message"), tr("没有需要保存的修改"));
        return result;
    }

    const QFileInfo info(m_filePath);
    QDir().mkpath(info.absolutePath());

    QString backupPath;
    if (m_exists) {
        const QString stamp =
                QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMddHHmmss"));
        backupPath = m_filePath + QStringLiteral(".bak.") + stamp;
        int counter = 1;
        while (QFile::exists(backupPath)) {
            backupPath = m_filePath + QStringLiteral(".bak.") + stamp
                    + QStringLiteral("-") + QString::number(counter++);
        }
        if (!QFile::copy(m_filePath, backupPath)) {
            result.insert(QStringLiteral("ok"), false);
            result.insert(QStringLiteral("error"),
                          tr("无法创建备份 %1，已取消保存").arg(backupPath));
            return result;
        }
    }

    QSaveFile file(m_filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        result.insert(QStringLiteral("ok"), false);
        result.insert(QStringLiteral("error"),
                      tr("无法写入 %1：%2").arg(m_filePath, file.errorString()));
        return result;
    }
    file.write(ensureTrailingNewline(m_text).toUtf8());
    if (!file.commit()) {
        result.insert(QStringLiteral("ok"), false);
        result.insert(QStringLiteral("error"), tr("保存失败：%1").arg(file.errorString()));
        return result;
    }

    m_exists = true;
    m_dirty = false;
    if (!backupPath.isEmpty()) {
        pruneBackups(10);
    }
    emit changed();

    result.insert(QStringLiteral("ok"), true);
    result.insert(QStringLiteral("backup"), backupPath);
    result.insert(QStringLiteral("path"), m_filePath);
    result.insert(QStringLiteral("warnings"), QVariantList(validate()));
    return result;
}

QVariantMap ConfigFile::applyRawText(const QString &text)
{
    reparse(ensureTrailingNewline(text));
    m_dirty = true;
    emit changed();

    QVariantMap result;
    result.insert(QStringLiteral("ok"), true);
    result.insert(QStringLiteral("warnings"), QVariantList(validate()));
    return result;
}

QString ConfigFile::ensureTrailingNewline(const QString &text) const
{
    if (text.isEmpty()) {
        return text;
    }
    if (text.endsWith(QLatin1Char('\n'))) {
        return text;
    }
    return text + QLatin1Char('\n');
}

void ConfigFile::pruneBackups(int keep) const
{
    const QFileInfo info(m_filePath);
    QDir dir(info.absolutePath());
    const QStringList filters{QStringLiteral("%1.bak.*").arg(info.fileName())};
    QFileInfoList backups = dir.entryInfoList(filters, QDir::Files, QDir::Name);
    const int removeCount = static_cast<int>(backups.size()) - keep;
    for (int i = 0; i < removeCount; ++i) {
        QFile::remove(backups.at(i).absoluteFilePath());
    }
}

int ConfigFile::backupCount() const
{
    const QFileInfo info(m_filePath);
    QDir dir(info.absolutePath());
    return static_cast<int>(dir.entryList({QStringLiteral("%1.bak.*").arg(info.fileName())},
                                          QDir::Files)
                                    .size());
}

} // namespace hyps
