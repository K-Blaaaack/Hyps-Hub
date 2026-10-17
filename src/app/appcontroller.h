#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>

namespace hyps {

class TaskManager;

/**
 * 应用级操作：退出、剪贴板、打开外部链接/目录。
 */
class AppController : public QObject
{
    Q_OBJECT

public:
    explicit AppController(TaskManager *tasks, QObject *parent = nullptr);

    Q_INVOKABLE void quitApplication();
    Q_INVOKABLE void forceQuitNow();
    Q_INVOKABLE void copyToClipboard(const QString &text) const;

    /** 仅允许 http/https 链接，交给系统浏览器打开。 */
    Q_INVOKABLE bool openExternalUrl(const QString &url) const;

    /** 在文件管理器中打开目录（不存在时尝试创建）。 */
    Q_INVOKABLE bool openDirectory(const QString &path) const;
    Q_INVOKABLE bool openFileInFolder(const QString &path) const;

private:
    TaskManager *m_tasks = nullptr;
};

} // namespace hyps
