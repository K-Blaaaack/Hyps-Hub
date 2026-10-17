#pragma once

#include <QAbstractListModel>
#include <QSortFilterProxyModel>
#include <QString>
#include <QVector>

namespace hyps {

/**
 * 结构化日志模型：stdout / stderr / 系统提示分行保存。
 *
 * 绑定一个 QSortFilterProxyModel 做增量过滤；日志有上限，超出后按批删除最旧的行，
 * 完整日志由 TaskManager 同步落盘。
 */
class LogModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(int count READ totalCount NOTIFY countChanged)
    Q_PROPERTY(int visibleCount READ visibleCount NOTIFY visibleCountChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(bool truncated READ truncated NOTIFY truncatedChanged)
    Q_PROPERTY(int maxLines READ maxLines WRITE setMaxLines NOTIFY maxLinesChanged)
    Q_PROPERTY(QAbstractItemModel *filtered READ filtered CONSTANT)

public:
    enum Stream { Stdout = 0, Stderr = 1, System = 2 };
    Q_ENUM(Stream)

    enum Roles {
        TextRole = Qt::UserRole + 1,
        StreamRole,
        NumberRole,
    };

    explicit LogModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int totalCount() const { return static_cast<int>(m_lines.size()); }
    int visibleCount() const;
    QAbstractItemModel *filtered() { return m_proxy; }

    QString filter() const { return m_filter; }
    void setFilter(const QString &filter);

    bool truncated() const { return m_truncated; }
    int maxLines() const { return m_maxLines; }
    void setMaxLines(int maxLines);

    /** 追加一段原始输出，按 \n / \r 分行（\r 进度行也会成为独立行）。 */
    void appendChunk(const QString &chunk, int stream);
    void appendLine(const QString &line, int stream);
    void clear();

    QString fullText() const;
    QString filteredText() const;

    Q_INVOKABLE void copyAllToClipboard() const;
    Q_INVOKABLE void copyFilteredToClipboard() const;

signals:
    void countChanged();
    void visibleCountChanged();
    void filterChanged();
    void truncatedChanged();
    void maxLinesChanged();

private:
    struct Line {
        QString text;
        int stream = Stdout;
    };

    void trimIfNeeded();

    QVector<Line> m_lines;
    QSortFilterProxyModel *m_proxy = nullptr;
    QString m_partial[2];
    QString m_filter;
    int m_maxLines = 5000;
    bool m_truncated = false;
};

} // namespace hyps
