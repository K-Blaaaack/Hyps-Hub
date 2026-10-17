#include "app/appcontroller.h"

#include "app/taskmanager.h"

#include <QClipboard>
#include <QDesktopServices>
#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QTimer>
#include <QUrl>

namespace hyps {

AppController::AppController(TaskManager *tasks, QObject *parent)
    : QObject(parent)
    , m_tasks(tasks)
{
}

void AppController::quitApplication()
{
    // 先终止运行中的子进程（进程组），给 bash 与游戏留出退出时间，再退出应用。
    if (m_tasks) {
        m_tasks->cancelAll();
    }
    QTimer::singleShot(1600, this, []() { QCoreApplication::quit(); });
}

void AppController::forceQuitNow()
{
    if (m_tasks) {
        m_tasks->cancelAll();
    }
    QTimer::singleShot(300, this, []() { QCoreApplication::quit(); });
}

void AppController::copyToClipboard(const QString &text) const
{
    if (auto *clipboard = QGuiApplication::clipboard()) {
        clipboard->setText(text);
    }
}

bool AppController::openExternalUrl(const QString &url) const
{
    const QUrl parsed(url);
    if (!parsed.isValid() || (parsed.scheme() != QLatin1String("https")
                              && parsed.scheme() != QLatin1String("http"))) {
        return false;
    }
    return QDesktopServices::openUrl(parsed);
}

bool AppController::openDirectory(const QString &path) const
{
    if (path.isEmpty()) {
        return false;
    }
    QDir().mkpath(path);
    return QDesktopServices::openUrl(QUrl::fromLocalFile(path));
}

bool AppController::openFileInFolder(const QString &path) const
{
    const QFileInfo info(path);
    if (!info.exists()) {
        return false;
    }
    return QDesktopServices::openUrl(QUrl::fromLocalFile(info.absolutePath()));
}

} // namespace hyps
