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

    m_windowX = m_settings.value("window/x", -1).toInt();
    m_windowY = m_settings.value("window/y", -1).toInt();
    m_windowWidth = m_settings.value("window/width", 1200).toInt();
    m_windowHeight = m_settings.value("window/height", 800).toInt();
    m_windowState = m_settings.value("window/state", "normal").toString();

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

int SettingsManager::windowX() const {
    return m_windowX;
}

int SettingsManager::windowY() const {
    return m_windowY;
}

int SettingsManager::windowWidth() const {
    return m_windowWidth;
}

int SettingsManager::windowHeight() const {
    return m_windowHeight;
}

QString SettingsManager::windowState() const {
    return m_windowState;
}

void SettingsManager::saveWindowGeometry(int x, int y, int width, int height, const QString& state) {
    if (state == "normal") {
        if (width >= 400 && height >= 300) {
            m_windowX = x;
            m_windowY = y;
            m_windowWidth = width;
            m_windowHeight = height;
        }
    }
    m_windowState = state;

    m_settings.setValue("window/x", m_windowX);
    m_settings.setValue("window/y", m_windowY);
    m_settings.setValue("window/width", m_windowWidth);
    m_settings.setValue("window/height", m_windowHeight);
    m_settings.setValue("window/state", m_windowState);
    m_settings.sync();
}

void SettingsManager::resetToDefaults() {
    QString defaultStorage = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/docsets";
    setStoragePath(defaultStorage);
    setAutoUpdateEnabled(true);
    setThemeMode("dark");
    setReaderFontSize(15);
    setCheckIntervalHours(24);
    m_windowX = -1;
    m_windowY = -1;
    m_windowWidth = 1200;
    m_windowHeight = 800;
    m_windowState = "normal";
    m_settings.remove("window");
    m_settings.sync();
}
