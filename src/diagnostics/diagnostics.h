#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>

namespace hyps {

class AppPaths;
class AppSettings;
class EnvironmentReport;
class RuntimeManager;
class TaskManager;

/**
 * 诊断导出：生成一个包含环境、Hyps 组件、任务与日志的目录包。
 * 敏感字段（token/password/secret 等）在写入前脱敏。
 */
class Diagnostics : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString lastExportPath READ lastExportPath NOTIFY exportStateChanged)
    Q_PROPERTY(QString lastExportError READ lastExportError NOTIFY exportStateChanged)

public:
    Diagnostics(AppPaths *paths, RuntimeManager *runtime, EnvironmentReport *report,
                TaskManager *tasks, AppSettings *settings, QObject *parent = nullptr);

    QString lastExportPath() const { return m_lastExportPath; }
    QString lastExportError() const { return m_lastExportError; }

    Q_INVOKABLE QVariantMap exportBundle(const QString &targetDirectory);
    Q_INVOKABLE QString defaultExportDirectory() const;

signals:
    void exportStateChanged();

private:
    QString redact(const QString &text) const;
    QString tailOfFile(const QString &path, int maxLines) const;
    bool writeTextFile(const QString &directory, const QString &name, const QString &content,
                       QString *error) const;
    QString buildSummary() const;

    AppPaths *m_paths = nullptr;
    RuntimeManager *m_runtime = nullptr;
    EnvironmentReport *m_report = nullptr;
    TaskManager *m_tasks = nullptr;
    AppSettings *m_settings = nullptr;
    QString m_lastExportPath;
    QString m_lastExportError;
};

} // namespace hyps
