#include "adapter/configfile.h"
#include "adapter/configmanager.h"
#include "adapter/environmentreport.h"
#include "adapter/gamecatalog.h"
#include "adapter/hypsadapter.h"
#include "app/appcontroller.h"
#include "app/apppaths.h"
#include "app/appsettings.h"
#include "app/directorymodel.h"
#include "app/logmodel.h"
#include "app/notifier.h"
#include "app/task.h"
#include "app/taskmanager.h"
#include "app/thememanager.h"
#include "diagnostics/diagnostics.h"
#include "runtime/runtimemanager.h"
#include "version.h"

#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QImage>
#include <QTextStream>
#include <QTimer>

using namespace hyps;

int main(int argc, char *argv[])
{
    QGuiApplication application(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("hyps-hub"));
    QCoreApplication::setApplicationVersion(QStringLiteral(HYPS_HUB_VERSION));
    QGuiApplication::setApplicationDisplayName(QStringLiteral("Hyps Hub"));
    QCoreApplication::setOrganizationName(QStringLiteral("hyps-hub"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("hyps-hub.local"));
    QGuiApplication::setDesktopFileName(QStringLiteral("hyps-hub"));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Hyps Hub - Hyps CLI 的图形客户端"));
    parser.addHelpOption();
    parser.addVersionOption();
    QCommandLineOption smokeOption(
            QStringLiteral("smoke-test"),
            QStringLiteral("加载 QML 后立即退出（用于自动化测试）"));
    parser.addOption(smokeOption);
    QCommandLineOption screenshotOption(
            QStringLiteral("screenshot"),
            QStringLiteral("加载后把窗口截图保存到指定文件并退出"),
            QStringLiteral("path"));
    parser.addOption(screenshotOption);
    QCommandLineOption previewDialogOption(
            QStringLiteral("preview-dialog"),
            QStringLiteral("打开指定 objectName 的 QML 弹窗（用于截图/调试）"),
            QStringLiteral("objectName"));
    parser.addOption(previewDialogOption);
    parser.process(application);

    QQuickStyle::setStyle(QStringLiteral("Basic"));
    QGuiApplication::setWindowIcon(QIcon(QStringLiteral(":/assets/hyps-hub.svg")));

    AppPaths paths;
    QString directoryError;
    if (!paths.ensureBaseDirectories(&directoryError)) {
        QTextStream(stderr) << "无法创建应用目录：" << directoryError << '\n';
    }

    AppSettings settings(paths.guiConfigFile());
    settings.load();
    if (!settings.loadWarning().isEmpty()) {
        QTextStream(stderr) << settings.loadWarning() << '\n';
    }

    ThemeManager theme(&settings);
    TaskManager tasks(&paths);
    RuntimeManager runtime(&paths);
    EnvironmentReport environmentReport;
    environmentReport.loadFromFile(paths.envReportFile());

    ConfigManager configs(&paths, &runtime);
    GameCatalog catalog(&paths, &runtime);
    HypsAdapter adapter(&paths, &runtime, &tasks, &environmentReport);
    Notifier notifier;
    AppController controller(&tasks);
    Diagnostics diagnostics(&paths, &runtime, &environmentReport, &tasks, &settings);

    QObject::connect(&runtime, &RuntimeManager::initialized, &configs,
                     &ConfigManager::reloadAll);
    QObject::connect(&runtime, &RuntimeManager::initialized, &catalog, &GameCatalog::refresh);
    QObject::connect(&runtime, &RuntimeManager::updateFinished, &catalog,
                     [&catalog, &configs](bool success) {
                         if (success) {
                             configs.reloadAll();
                             catalog.refresh();
                         }
                     });
    QObject::connect(&adapter, &HypsAdapter::configInitialized, &configs,
                     &ConfigManager::reloadAll);
    QObject::connect(&adapter, &HypsAdapter::configInitialized, &catalog,
                     &GameCatalog::refresh);
    QObject::connect(&adapter, &HypsAdapter::gameConfigCreated, &configs,
                     &ConfigManager::reloadAll);
    QObject::connect(&adapter, &HypsAdapter::gameConfigCreated, &catalog,
                     &GameCatalog::refresh);
    QObject::connect(&application, &QCoreApplication::aboutToQuit, &tasks,
                     &TaskManager::cancelAll);

    qmlRegisterSingletonInstance("HypsHub", 1, 0, "App", &paths);
    qmlRegisterSingletonInstance("HypsHub", 1, 0, "Settings", &settings);
    qmlRegisterSingletonInstance("HypsHub", 1, 0, "Theme", &theme);
    qmlRegisterSingletonInstance("HypsHub", 1, 0, "Tasks", &tasks);
    qmlRegisterSingletonInstance("HypsHub", 1, 0, "Runtime", &runtime);
    qmlRegisterSingletonInstance("HypsHub", 1, 0, "EnvReport", &environmentReport);
    qmlRegisterSingletonInstance("HypsHub", 1, 0, "Configs", &configs);
    qmlRegisterSingletonInstance("HypsHub", 1, 0, "Games", &catalog);
    qmlRegisterSingletonInstance("HypsHub", 1, 0, "Adapter", &adapter);
    qmlRegisterSingletonInstance("HypsHub", 1, 0, "Notifier", &notifier);
    qmlRegisterSingletonInstance("HypsHub", 1, 0, "Diag", &diagnostics);
    qmlRegisterSingletonInstance("HypsHub", 1, 0, "AppControl", &controller);

    qmlRegisterUncreatableType<Task>("HypsHub", 1, 0, "Task",
                                     QStringLiteral("由 TaskManager 创建"));
    qmlRegisterUncreatableType<LogModel>("HypsHub", 1, 0, "LogModel",
                                         QStringLiteral("由 Task 创建"));
    qmlRegisterUncreatableType<ConfigFile>("HypsHub", 1, 0, "ConfigFile",
                                           QStringLiteral("由 ConfigManager 创建"));
    qmlRegisterType<DirectoryModel>("HypsHub", 1, 0, "DirectoryModel");

    runtime.refresh();

    // CLI 自检必须等 Hyps 组件就绪，避免在 verifying 阶段误报错误。
    auto *cliVerifiedOnce = new bool(false);
    QObject::connect(&runtime, &RuntimeManager::stateChanged, &adapter,
                     [&adapter, &runtime, cliVerifiedOnce]() {
                         if (runtime.ready() && !*cliVerifiedOnce) {
                             *cliVerifiedOnce = true;
                             adapter.verifyCli();
                         }
                     });
    QObject::connect(&runtime, &RuntimeManager::updateFinished, &adapter,
                     [&adapter](bool success) {
                         if (success) {
                             adapter.verifyCli();
                         }
                     });

    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlEngine::warnings, &application,
                     [](const QList<QQmlError> &warnings) {
                         for (const QQmlError &warning : warnings) {
                             QTextStream(stderr) << "QML 警告: " << warning.toString() << '\n';
                         }
                     });
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &application,
                     [](const QUrl &url) {
                         QTextStream(stderr) << "无法加载 QML 界面：" << url.toString() << '\n';
                     });

    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));
    if (engine.rootObjects().isEmpty()) {
        QTextStream(stderr) << "QML 根对象创建失败，导入路径："
                            << engine.importPathList().join(QStringLiteral(", ")) << '\n';
        return 3;
    }

    if (parser.isSet(smokeOption)) {
        QTextStream(stdout) << "smoke-test: QML 已加载，退出\n";
        QTimer::singleShot(1500, &application, []() { QCoreApplication::quit(); });
    }

    if (parser.isSet(previewDialogOption)) {
        const QString objectName = parser.value(previewDialogOption);
        QTimer::singleShot(1200, &application, [&engine, objectName]() {
            if (engine.rootObjects().isEmpty()) {
                return;
            }
            QObject *target = engine.rootObjects().first()->findChild<QObject *>(objectName);
            if (target) {
                QMetaObject::invokeMethod(target, "open");
            } else {
                QTextStream(stderr) << "找不到弹窗：" << objectName << '\n';
            }
        });
    }

    if (parser.isSet(screenshotOption)) {
        const QString path = parser.value(screenshotOption);
        QTimer::singleShot(2200, &application, [&engine, path]() {
            if (engine.rootObjects().isEmpty()) {
                QCoreApplication::exit(4);
                return;
            }
            auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
            if (!window) {
                QCoreApplication::exit(4);
                return;
            }
            const QImage image = window->grabWindow();
            if (!image.save(path)) {
                QTextStream(stderr) << "无法保存截图：" << path << '\n';
                QCoreApplication::exit(4);
                return;
            }
            QTextStream(stdout) << "screenshot: " << path << '\n';
            QCoreApplication::quit();
        });
    }

    return application.exec();
}
