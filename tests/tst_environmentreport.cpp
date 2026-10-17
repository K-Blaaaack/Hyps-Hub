#include <QtTest>
#include <QTemporaryDir>

#include "adapter/environmentreport.h"

using namespace hyps;

class TestEnvironmentReport : public QObject
{
    Q_OBJECT

private slots:
    void parsesRealReport();
    void handlesAnsiAndMissingSections();
    void persistsAndLoads();
};

namespace {

const char *reportText = R"REPORT([Hyps] 环境检测

系统
  [✓] 运行用户                      kb
  [✓] 内核                          Linux
  [✓] 图形会话                      wayland / niri

命令与工具链
  [✓] coreutils                     全部可用
  [!] mingw-w64                     未安装：终末地替身父进程模式不可用
  [i] uv                            未安装：原神 D3D12 unitypy 补丁将回退 bytes 实现

运行器
  [✓] umu-run                       /usr/bin/umu-run
  [✓] umu-dwproton                  umu-run + dwproton

图形
  [✓] GPU                           Intel
  [✓] Vulkan ICD                    5 个: intel_icd.json, nvidia_icd.json

配置
  [✓] 配置目录                      /home/kb/.config/hyps-hub/hyps
  [!] _common.conf                  不存在（初始化时复制示例）

必需项: 9/10 通过（1 项缺失）
可选能力缺失: 2 项（见上行 [!] 标记，安装对应依赖后可用）
配置待创建: 1 项（运行 ./init.sh 初始化会补齐）
)REPORT";

} // namespace

void TestEnvironmentReport::parsesRealReport()
{
    EnvironmentReport report;
    report.parse(QString::fromUtf8(reportText));

    QVERIFY(report.hasReport());
    QCOMPARE(report.requiredPassed(), 9);
    QCOMPARE(report.requiredTotal(), 10);
    QCOMPARE(report.requiredFailed(), 1);
    QCOMPARE(report.warnings(), 2);
    QCOMPARE(report.configWarnings(), 1);
    QCOMPARE(report.groups().size(), 5);

    const QVariantMap first = report.groups().first().toMap();
    QCOMPARE(first.value(QStringLiteral("title")).toString(), QStringLiteral("系统"));
    const QVariantList items = first.value(QStringLiteral("items")).toList();
    QCOMPARE(items.size(), 3);
    QCOMPARE(items.first().toMap().value(QStringLiteral("status")).toString(),
             QStringLiteral("ok"));
    QCOMPARE(items.first().toMap().value(QStringLiteral("name")).toString(),
             QStringLiteral("运行用户"));
    QCOMPARE(items.first().toMap().value(QStringLiteral("detail")).toString(),
             QStringLiteral("kb"));

    bool foundWarn = false;
    for (const QVariant &group : report.groups()) {
        for (const QVariant &item : group.toMap().value(QStringLiteral("items")).toList()) {
            if (item.toMap().value(QStringLiteral("name")).toString()
                == QLatin1String("mingw-w64")) {
                foundWarn = item.toMap().value(QStringLiteral("status")).toString()
                        == QLatin1String("warn");
            }
        }
    }
    QVERIFY(foundWarn);
}

void TestEnvironmentReport::handlesAnsiAndMissingSections()
{
    EnvironmentReport report;
    report.parse(QStringLiteral("\x1b[1m[Hyps] 环境检测\x1b[0m\n\n"
                                "系统\n"
                                "  \x1b[32m[✓]\x1b[0m 内核   Linux\n"
                                "\x1b[1m必需项:\x1b[0m 1/1 通过\n"));
    QVERIFY(report.hasReport());
    QCOMPARE(report.requiredTotal(), 1);
    QCOMPARE(report.groups().size(), 1);
    QVERIFY(!report.rawText().contains(QChar(0x1b)));

    EnvironmentReport empty;
    empty.parse(QStringLiteral("完全无法识别的输出\n"));
    QVERIFY(empty.hasReport());
    QVERIFY(empty.requiredTotal() == 0);
}

void TestEnvironmentReport::persistsAndLoads()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QString path = dir.filePath(QStringLiteral("env-report.json"));

    EnvironmentReport report;
    report.parse(QString::fromUtf8(reportText));
    QVERIFY(report.saveToFile(path));

    EnvironmentReport loaded;
    QVERIFY(loaded.loadFromFile(path));
    QCOMPARE(loaded.requiredPassed(), 9);
    QCOMPARE(loaded.requiredTotal(), 10);
    QCOMPARE(loaded.groups().size(), report.groups().size());
    QCOMPARE(loaded.checkedAtText(), report.checkedAtText());
}

QTEST_GUILESS_MAIN(TestEnvironmentReport)

#include "tst_environmentreport.moc"
