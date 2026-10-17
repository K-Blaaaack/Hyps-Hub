#include "app/directorymodel.h"

#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <QRegularExpression>
#include <QUrl>

#include <utility>

namespace hyps {

DirectoryModel::DirectoryModel(QObject *parent)
    : QObject(parent)
{
    m_homePath = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    if (m_homePath.isEmpty()) {
        m_homePath = QDir::homePath();
    }
    m_path = m_homePath;
    rebuild();
}

QString DirectoryModel::parentPath() const
{
    if (m_path.isEmpty() || m_path == QLatin1String("/")) {
        return QStringLiteral("/");
    }
    QDir dir(m_path);
    if (!dir.cdUp()) {
        return QStringLiteral("/");
    }
    const QString parent = dir.absolutePath();
    return parent.isEmpty() ? QStringLiteral("/") : parent;
}

void DirectoryModel::setPath(const QString &newPath)
{
    QString candidate = newPath;
    if (candidate.startsWith(QLatin1String("file://"))) {
        candidate = QUrl(candidate).toLocalFile();
    }
    candidate = QDir::cleanPath(candidate.trimmed());
    if (candidate.isEmpty()) {
        candidate = m_homePath;
    }
    const QFileInfo info(candidate);
    if (info.exists() && info.isFile()) {
        candidate = info.absolutePath();
    }
    const QDir dir(candidate);
    if (!dir.exists()) {
        m_error = tr("目录不存在：%1").arg(candidate);
        emit errorChanged();
        return;
    }
    m_path = QDir::cleanPath(dir.absolutePath());
    if (!m_error.isEmpty()) {
        m_error.clear();
        emit errorChanged();
    }
    rebuild();
    emit changed();
}

void DirectoryModel::goUp()
{
    setPath(parentPath());
}

void DirectoryModel::refresh()
{
    rebuild();
    emit changed();
}

void DirectoryModel::setShowHidden(bool show)
{
    if (m_showHidden == show) {
        return;
    }
    m_showHidden = show;
    emit showHiddenChanged();
    rebuild();
    emit changed();
}

void DirectoryModel::setFoldersOnly(bool foldersOnly)
{
    if (m_foldersOnly == foldersOnly) {
        return;
    }
    m_foldersOnly = foldersOnly;
    emit foldersOnlyChanged();
    rebuild();
    emit changed();
}

void DirectoryModel::setNameFilter(const QString &filter)
{
    if (m_nameFilter == filter) {
        return;
    }
    m_nameFilter = filter;
    emit nameFilterChanged();
    rebuild();
    emit changed();
}

void DirectoryModel::rebuild()
{
    m_entries.clear();
    QDir dir(m_path);
    if (!dir.exists()) {
        return;
    }

    QFileInfoList infos = dir.entryInfoList(QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot
                                                    | QDir::Readable,
                                            QDir::DirsFirst | QDir::Name | QDir::IgnoreCase);
    QStringList namePatterns;
    if (!m_nameFilter.isEmpty()) {
        namePatterns = m_nameFilter.split(QLatin1Char(' '), Qt::SkipEmptyParts);
    }

    for (const QFileInfo &info : std::as_const(infos)) {
        const QString name = info.fileName();
        if (!m_showHidden && name.startsWith(QLatin1Char('.'))) {
            continue;
        }
        if (info.isDir()) {
            QVariantMap entry;
            entry.insert(QStringLiteral("name"), name);
            entry.insert(QStringLiteral("path"), info.absoluteFilePath());
            entry.insert(QStringLiteral("isDir"), true);
            entry.insert(QStringLiteral("size"), QString());
            m_entries.append(entry);
            continue;
        }
        if (m_foldersOnly || !info.isReadable()) {
            continue;
        }
        if (!namePatterns.isEmpty()) {
            bool matched = false;
            for (const QString &pattern : namePatterns) {
                const QRegularExpression re(
                        QRegularExpression::wildcardToRegularExpression(pattern),
                        QRegularExpression::CaseInsensitiveOption);
                if (re.match(info.fileName()).hasMatch()) {
                    matched = true;
                    break;
                }
            }
            if (!matched) {
                continue;
            }
        }
        QVariantMap entry;
        entry.insert(QStringLiteral("name"), name);
        entry.insert(QStringLiteral("path"), info.absoluteFilePath());
        entry.insert(QStringLiteral("isDir"), false);
        entry.insert(QStringLiteral("size"),
                     QString(QString::number(info.size() / 1024.0 / 1024.0, 'f', 1)
                             + QStringLiteral(" MB")));
        m_entries.append(entry);
    }
}

bool DirectoryModel::isDirectory(const QString &path) const
{
    return QFileInfo(path).isDir();
}

} // namespace hyps
