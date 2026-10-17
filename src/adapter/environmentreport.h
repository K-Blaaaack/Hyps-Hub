#pragma once

#include <QDateTime>
#include <QObject>
#include <QString>
#include <QVariantList>

namespace hyps {

/**
 * 上游 `init.sh --check` 报表的解析结果。
 *
 * 输出格式（已实测）：
 *   [Hyps] 环境检测
 *
 *   系统
 *     [✓] 运行用户                      kb
 *     [!] mingw-w64                     未安装：...
 *   必需项: 10/10 通过
 *   可选能力缺失: 3 项（...）
 *   配置待创建: 2 项（...）
 *
 * 若上游格式变化导致解析不到任何条目，保留原始文本供界面展示。
 */
class EnvironmentReport : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList groups READ groups NOTIFY changed)
    Q_PROPERTY(int requiredTotal READ requiredTotal NOTIFY changed)
    Q_PROPERTY(int requiredPassed READ requiredPassed NOTIFY changed)
    Q_PROPERTY(int requiredFailed READ requiredFailed NOTIFY changed)
    Q_PROPERTY(int warnings READ warnings NOTIFY changed)
    Q_PROPERTY(int configWarnings READ configWarnings NOTIFY changed)
    Q_PROPERTY(QString checkedAtText READ checkedAtText NOTIFY changed)
    Q_PROPERTY(QString rawText READ rawText NOTIFY changed)
    Q_PROPERTY(bool hasReport READ hasReport NOTIFY changed)
    Q_PROPERTY(QString summaryText READ summaryText NOTIFY changed)

public:
    explicit EnvironmentReport(QObject *parent = nullptr);

    QVariantList groups() const { return m_groups; }
    int requiredTotal() const { return m_requiredTotal; }
    int requiredPassed() const { return m_requiredPassed; }
    int requiredFailed() const { return m_requiredFailed; }
    int warnings() const { return m_warnings; }
    int configWarnings() const { return m_configWarnings; }
    QString checkedAtText() const;
    QString rawText() const { return m_rawText; }
    bool hasReport() const { return m_hasReport; }
    QString summaryText() const;

    void parse(const QString &text, const QDateTime &checkedAt = QDateTime::currentDateTime());
    void clear();

    bool loadFromFile(const QString &path);
    bool saveToFile(const QString &path) const;

    QDateTime checkedAt() const { return m_checkedAt; }

signals:
    void changed();

private:
    QVariantList m_groups;
    QString m_rawText;
    QDateTime m_checkedAt;
    int m_requiredTotal = 0;
    int m_requiredPassed = 0;
    int m_requiredFailed = 0;
    int m_warnings = 0;
    int m_configWarnings = 0;
    bool m_hasReport = false;
};

} // namespace hyps
