#pragma once

#include <QObject>
#include <QVariantList>

namespace hyps {

/**
 * 用于文件选择对话框的最小目录浏览模型（不依赖平台原生对话框，
 * 在 Wayland / niri 等没有统一文件选择器的环境下也能工作）。
 */
class DirectoryModel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList entries READ entries NOTIFY changed)
    Q_PROPERTY(QString path READ path NOTIFY changed)
    Q_PROPERTY(QString parentPath READ parentPath NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(bool showHidden READ showHidden WRITE setShowHidden NOTIFY showHiddenChanged)
    Q_PROPERTY(bool foldersOnly READ foldersOnly WRITE setFoldersOnly NOTIFY foldersOnlyChanged)
    Q_PROPERTY(QString nameFilter READ nameFilter WRITE setNameFilter NOTIFY nameFilterChanged)

public:
    explicit DirectoryModel(QObject *parent = nullptr);

    QVariantList entries() const { return m_entries; }
    QString path() const { return m_path; }
    QString parentPath() const;
    QString error() const { return m_error; }
    bool showHidden() const { return m_showHidden; }
    void setShowHidden(bool show);
    bool foldersOnly() const { return m_foldersOnly; }
    void setFoldersOnly(bool foldersOnly);
    QString nameFilter() const { return m_nameFilter; }
    void setNameFilter(const QString &filter);

    Q_INVOKABLE void setPath(const QString &path);
    Q_INVOKABLE void goUp();
    Q_INVOKABLE void refresh();
    Q_INVOKABLE QString homePath() const { return m_homePath; }
    Q_INVOKABLE bool isDirectory(const QString &path) const;

signals:
    void changed();
    void errorChanged();
    void showHiddenChanged();
    void foldersOnlyChanged();
    void nameFilterChanged();

private:
    void rebuild();

    QString m_path;
    QString m_homePath;
    QString m_error;
    QString m_nameFilter;
    QVariantList m_entries;
    bool m_showHidden = false;
    bool m_foldersOnly = true;
};

} // namespace hyps
