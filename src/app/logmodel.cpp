#include "app/logmodel.h"

#include <QClipboard>
#include <QGuiApplication>

namespace hyps {

LogModel::LogModel(QObject *parent)
    : QAbstractListModel(parent)
{
    m_proxy = new QSortFilterProxyModel(this);
    m_proxy->setSourceModel(this);
    m_proxy->setFilterRole(TextRole);
    m_proxy->setFilterCaseSensitivity(Qt::CaseInsensitive);
    m_proxy->setDynamicSortFilter(true);

    connect(m_proxy, &QAbstractItemModel::rowsInserted, this, &LogModel::visibleCountChanged);
    connect(m_proxy, &QAbstractItemModel::rowsRemoved, this, &LogModel::visibleCountChanged);
    connect(m_proxy, &QAbstractItemModel::modelReset, this, &LogModel::visibleCountChanged);
}

int LogModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return static_cast<int>(m_lines.size());
}

QVariant LogModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_lines.size()) {
        return {};
    }
    const Line &line = m_lines.at(index.row());
    switch (role) {
    case TextRole:
        return line.text;
    case StreamRole:
        return line.stream;
    case NumberRole:
        return index.row() + 1;
    default:
        return {};
    }
}

QHash<int, QByteArray> LogModel::roleNames() const
{
    return {
        {TextRole, QByteArrayLiteral("text")},
        {StreamRole, QByteArrayLiteral("stream")},
        {NumberRole, QByteArrayLiteral("lineNumber")},
    };
}

int LogModel::visibleCount() const
{
    return m_proxy->rowCount();
}

void LogModel::setFilter(const QString &filter)
{
    if (m_filter == filter) {
        return;
    }
    m_filter = filter;
    m_proxy->setFilterFixedString(filter);
    emit filterChanged();
    emit visibleCountChanged();
}

void LogModel::setMaxLines(int maxLines)
{
    const int clamped = qBound(100, maxLines, 200000);
    if (m_maxLines == clamped) {
        return;
    }
    m_maxLines = clamped;
    emit maxLinesChanged();
    trimIfNeeded();
}

void LogModel::appendChunk(const QString &chunk, int stream)
{
    if (chunk.isEmpty()) {
        return;
    }
    const int index = (stream == Stderr) ? 1 : 0;
    m_partial[index] += chunk;

    const QString &buffer = m_partial[index];
    int start = 0;
    for (int i = 0; i < buffer.size(); ++i) {
        const QChar ch = buffer.at(i);
        if (ch == QLatin1Char('\n') || ch == QLatin1Char('\r')) {
            if (i > start) {
                appendLine(buffer.mid(start, i - start), stream);
            }
            start = i + 1;
        }
    }
    m_partial[index] = buffer.mid(start);
    if (m_partial[index].size() > 64 * 1024) {
        appendLine(m_partial[index].left(64 * 1024)
                           + QStringLiteral(" …[行已截断]"),
                   stream);
        m_partial[index].clear();
    }
}

void LogModel::appendLine(const QString &line, int stream)
{
    const int row = static_cast<int>(m_lines.size());
    beginInsertRows(QModelIndex(), row, row);
    m_lines.append(Line{line, stream});
    endInsertRows();
    emit countChanged();
    trimIfNeeded();
}

void LogModel::trimIfNeeded()
{
    if (static_cast<int>(m_lines.size()) <= m_maxLines) {
        return;
    }
    const int removeCount = qMax(1, m_maxLines / 10);
    const int clamped = qMin(removeCount, static_cast<int>(m_lines.size()));
    beginRemoveRows(QModelIndex(), 0, clamped - 1);
    m_lines.remove(0, clamped);
    endRemoveRows();
    if (!m_truncated) {
        m_truncated = true;
        emit truncatedChanged();
    }
    emit countChanged();
}

void LogModel::clear()
{
    beginResetModel();
    m_lines.clear();
    m_partial[0].clear();
    m_partial[1].clear();
    endResetModel();
    if (m_truncated) {
        m_truncated = false;
        emit truncatedChanged();
    }
    emit countChanged();
    emit visibleCountChanged();
}

QString LogModel::fullText() const
{
    QString text;
    text.reserve(m_lines.size() * 80);
    for (const Line &line : m_lines) {
        text += line.text;
        text += QLatin1Char('\n');
    }
    return text;
}

QString LogModel::filteredText() const
{
    QString text;
    for (int row = 0; row < m_proxy->rowCount(); ++row) {
        const QModelIndex index = m_proxy->index(row, 0);
        text += index.data(TextRole).toString();
        text += QLatin1Char('\n');
    }
    return text;
}

void LogModel::copyAllToClipboard() const
{
    if (auto *clipboard = QGuiApplication::clipboard()) {
        clipboard->setText(fullText());
    }
}

void LogModel::copyFilteredToClipboard() const
{
    if (auto *clipboard = QGuiApplication::clipboard()) {
        clipboard->setText(filteredText());
    }
}

} // namespace hyps
