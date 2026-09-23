#include "SettingsManager.h"

SettingsManager::SettingsManager(QObject* parent)
    : QObject(parent)
    , m_settings("ColdManual", "ColdManual")
{
    QString defaultStorage = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/docsets";
    m_storagePath = m_settings.value("storagePath", defaultStorage).toString();
    m_autoUpdateEnabled = m_settings.value("autoUpdateEnabled", true).toBool();
    m_themeMode = m_settings.value("themeMode", "dark").toString();
    m_readerFontSize = m_settings.value("readerFontSize", 15).toInt();
    m_checkIntervalHours = m_settings.value("checkIntervalHours", 24).toInt();

    ensureStoragePathExists();
}

void SettingsManager::ensureStoragePathExists() {
    QDir dir(m_storagePath);
    if (!dir.exists()) {
        dir.mkpath(".");
    }
}

QString SettingsManager::storagePath() const {
    return m_storagePath;
}

void SettingsManager::setStoragePath(const QString& path) {
    if (m_storagePath != path && !path.trimmed().isEmpty()) {
        m_storagePath = path;
        m_settings.setValue("storagePath", m_storagePath);
        ensureStoragePathExists();
        emit storagePathChanged(m_storagePath);
    }
}

bool SettingsManager::autoUpdateEnabled() const {
    return m_autoUpdateEnabled;
}

void SettingsManager::setAutoUpdateEnabled(bool enabled) {
    if (m_autoUpdateEnabled != enabled) {
        m_autoUpdateEnabled = enabled;
        m_settings.setValue("autoUpdateEnabled", m_autoUpdateEnabled);
        emit autoUpdateEnabledChanged(m_autoUpdateEnabled);
    }
}

QString SettingsManager::themeMode() const {
    return m_themeMode;
}

void SettingsManager::setThemeMode(const QString& mode) {
    if (m_themeMode != mode) {
        m_themeMode = mode;
        m_settings.setValue("themeMode", m_themeMode);
        emit themeModeChanged(m_themeMode);
    }
}

int SettingsManager::readerFontSize() const {
    return m_readerFontSize;
}

void SettingsManager::setReaderFontSize(int size) {
    if (m_readerFontSize != size && size >= 10 && size <= 32) {
        m_readerFontSize = size;
        m_settings.setValue("readerFontSize", m_readerFontSize);
        emit readerFontSizeChanged(m_readerFontSize);
    }
}

int SettingsManager::checkIntervalHours() const {
    return m_checkIntervalHours;
}

void SettingsManager::setCheckIntervalHours(int hours) {
    if (m_checkIntervalHours != hours && hours > 0) {
        m_checkIntervalHours = hours;
        m_settings.setValue("checkIntervalHours", m_checkIntervalHours);
        emit checkIntervalHoursChanged(m_checkIntervalHours);
    }
}

void SettingsManager::resetToDefaults() {
    QString defaultStorage = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/docsets";
    setStoragePath(defaultStorage);
    setAutoUpdateEnabled(true);
    setThemeMode("dark");
    setReaderFontSize(15);
    setCheckIntervalHours(24);
}
