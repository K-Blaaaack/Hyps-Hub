#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <QVector>

namespace hyps {

/**
 * Hyps 配置文件的读取 / 编辑 / 保存。
 *
 * 忠实实现上游 lib/config/parse.sh 的语法：
 *  - `key = value`，`#` 注释（引号外的行内注释会被剥离）
 *  - 单/双引号字符串
 *  - 多行数组 `[ ... ]` 与 `( ... )`
 *  - `[section]` 前缀
 *
 * 编辑时只重写目标键所在的行，保留无关行的注释与顺序；保存前生成
 * `.bak.<时间戳>` 备份，使用 QSaveFile 原子替换。
 */
class ConfigFile : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString filePath READ filePath CONSTANT)
    Q_PROPERTY(bool exists READ exists NOTIFY changed)
    Q_PROPERTY(bool dirty READ dirty NOTIFY changed)
    Q_PROPERTY(QString text READ text NOTIFY changed)
    Q_PROPERTY(QVariantList entries READ entries NOTIFY changed)
    Q_PROPERTY(QVariantMap values READ values NOTIFY changed)
    Q_PROPERTY(QString loadError READ loadError NOTIFY changed)
    Q_PROPERTY(QStringList warnings READ warnings NOTIFY changed)

public:
    struct Entry
    {
        QString key;
        QString bareKey;
        QString section;
        int startLine = 0;
        int endLine = 0;
        QString rawValue;
        QString value;
        bool array = false;
        bool quoted = false;
    };

    explicit ConfigFile(QString filePath, QObject *parent = nullptr);

    QString filePath() const { return m_filePath; }
    bool exists() const { return m_exists; }
    bool dirty() const { return m_dirty; }
    QString text() const { return m_text; }
    QVariantList entries() const;
    QVariantMap values() const;
    QString loadError() const { return m_loadError; }
    QStringList warnings() const { return m_warnings; }

    bool load(QString *error = nullptr);

    Q_INVOKABLE QVariantMap reload();
    Q_INVOKABLE QVariantMap save();
    Q_INVOKABLE QVariantMap applyRawText(const QString &text);
    Q_INVOKABLE void discardChanges();

    Q_INVOKABLE QString valueFor(const QString &key, const QString &fallback = QString()) const;
    Q_INVOKABLE bool hasKey(const QString &key) const;
    Q_INVOKABLE bool isTrue(const QString &key) const;
    Q_INVOKABLE QStringList keys() const;
    Q_INVOKABLE QStringList arrayValues(const QString &key) const;

    Q_INVOKABLE bool setValue(const QString &key, const QString &value);
    Q_INVOKABLE bool setArray(const QString &key, const QStringList &values);
    Q_INVOKABLE bool removeKey(const QString &key);

    Q_INVOKABLE QVariantList validate() const;

    const QVector<Entry> &rawEntries() const { return m_entries; }
    int backupCount() const;

signals:
    void changed();

private:
    void reparse(const QString &text);
    bool commitText(const QString &newText);
    QString formatArray(const QString &bareKey, const QStringList &values) const;
    QString ensureTrailingNewline(const QString &text) const;
    void pruneBackups(int keep) const;
    void addWarning(const QString &warning);

    QString m_filePath;
    QString m_text;
    QVector<Entry> m_entries;
    QString m_loadError;
    QStringList m_warnings;
    bool m_exists = false;
    bool m_dirty = false;
};

} // namespace hyps
