#pragma once

#include <QObject>
#include <QString>
#include <QSettings>
#include <QStandardPaths>
#include <QDir>

class SettingsManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString storagePath READ storagePath WRITE setStoragePath NOTIFY storagePathChanged)
    Q_PROPERTY(bool autoUpdateEnabled READ autoUpdateEnabled WRITE setAutoUpdateEnabled NOTIFY autoUpdateEnabledChanged)
    Q_PROPERTY(QString themeMode READ themeMode WRITE setThemeMode NOTIFY themeModeChanged)
    Q_PROPERTY(int readerFontSize READ readerFontSize WRITE setReaderFontSize NOTIFY readerFontSizeChanged)
    Q_PROPERTY(int checkIntervalHours READ checkIntervalHours WRITE setCheckIntervalHours NOTIFY checkIntervalHoursChanged)

public:
    explicit SettingsManager(QObject* parent = nullptr);

    QString storagePath() const;
    void setStoragePath(const QString& path);

    bool autoUpdateEnabled() const;
    void setAutoUpdateEnabled(bool enabled);

    QString themeMode() const;
    void setThemeMode(const QString& mode);

    int readerFontSize() const;
    void setReaderFontSize(int size);

    int checkIntervalHours() const;
    void setCheckIntervalHours(int hours);

    Q_INVOKABLE void resetToDefaults();

signals:
    void storagePathChanged(const QString& path);
    void autoUpdateEnabledChanged(bool enabled);
    void themeModeChanged(const QString& mode);
    void readerFontSizeChanged(int size);
    void checkIntervalHoursChanged(int hours);

private:
    QSettings m_settings;
    QString m_storagePath;
    bool m_autoUpdateEnabled{true};
    QString m_themeMode{"dark"};
    int m_readerFontSize{15};
    int m_checkIntervalHours{24};

    void ensureStoragePathExists();
};
