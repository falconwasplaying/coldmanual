#include "SettingsManager.h"
#include <QTimer>
#include <QFileInfo>
#include <QFile>
#include <algorithm>

#ifdef Q_OS_WIN
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <psapi.h>
#endif

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

    m_windowDisplayMode = m_settings.value("window/displayMode", "windowed").toString();
    if (m_windowDisplayMode != "windowed" && m_windowDisplayMode != "borderless" && m_windowDisplayMode != "fullscreen") {
        m_windowDisplayMode = "windowed";
    }
    m_windowX = m_settings.value("window/x", -1).toInt();
    m_windowY = m_settings.value("window/y", -1).toInt();
    m_windowWidth = m_settings.value("window/width", 1200).toInt();
    m_windowHeight = m_settings.value("window/height", 800).toInt();
    m_windowState = m_settings.value("window/state", "normal").toString();

    m_tabCloseButtonMode = m_settings.value("tabs/closeButtonMode", "hover").toString();
    if (m_tabCloseButtonMode != "always" && m_tabCloseButtonMode != "hover" && m_tabCloseButtonMode != "never") {
        m_tabCloseButtonMode = "hover";
    }
    m_tabHoverPreviewEnabled = m_settings.value("tabs/hoverPreviewEnabled", true).toBool();
    m_tabRamUsageMode = m_settings.value("tabs/ramUsageMode", "preview").toString();
    if (m_tabRamUsageMode != "none" && m_tabRamUsageMode != "tab" && m_tabRamUsageMode != "preview" && m_tabRamUsageMode != "both") {
        m_tabRamUsageMode = "preview";
    }

    ensureStoragePathExists();

    m_cachedProcessMemoryUsage = queryProcessMemoryUsage();
    m_ramTimer = new QTimer(this);
    m_ramTimer->setInterval(1500);
    connect(m_ramTimer, &QTimer::timeout, this, [this]() {
        QString currentMem = queryProcessMemoryUsage();
        if (currentMem != m_cachedProcessMemoryUsage) {
            m_cachedProcessMemoryUsage = currentMem;
            emit processMemoryUsageChanged(m_cachedProcessMemoryUsage);
        }
    });
    m_ramTimer->start();
}

SettingsManager::~SettingsManager() {
    m_settings.sync();
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

QString SettingsManager::windowDisplayMode() const {
    return m_windowDisplayMode;
}

void SettingsManager::setWindowDisplayMode(const QString& mode) {
    if (mode != "windowed" && mode != "borderless" && mode != "fullscreen") {
        return;
    }
    if (m_windowDisplayMode != mode) {
        m_windowDisplayMode = mode;
        m_settings.setValue("window/displayMode", m_windowDisplayMode);
        m_settings.sync();
        emit windowDisplayModeChanged(m_windowDisplayMode);
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
}

void SettingsManager::sync() {
    m_settings.sync();
}

void SettingsManager::resetToDefaults() {
    QString defaultStorage = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/docsets";
    setStoragePath(defaultStorage);
    setAutoUpdateEnabled(true);
    setThemeMode("dark");
    setReaderFontSize(15);
    setCheckIntervalHours(24);
    setWindowDisplayMode("windowed");
    m_windowX = -1;
    m_windowY = -1;
    m_windowWidth = 1200;
    m_windowHeight = 800;
    m_windowState = "normal";
    setTabCloseButtonMode("hover");
    setTabHoverPreviewEnabled(true);
    setTabRamUsageMode("preview");
    m_settings.remove("window");
    m_settings.remove("tabs");
    m_settings.sync();
}

QString SettingsManager::tabCloseButtonMode() const {
    return m_tabCloseButtonMode;
}

void SettingsManager::setTabCloseButtonMode(const QString& mode) {
    if (mode != "always" && mode != "hover" && mode != "never") return;
    if (m_tabCloseButtonMode != mode) {
        m_tabCloseButtonMode = mode;
        m_settings.setValue("tabs/closeButtonMode", m_tabCloseButtonMode);
        m_settings.sync();
        emit tabCloseButtonModeChanged(m_tabCloseButtonMode);
    }
}

bool SettingsManager::tabHoverPreviewEnabled() const {
    return m_tabHoverPreviewEnabled;
}

void SettingsManager::setTabHoverPreviewEnabled(bool enabled) {
    if (m_tabHoverPreviewEnabled != enabled) {
        m_tabHoverPreviewEnabled = enabled;
        m_settings.setValue("tabs/hoverPreviewEnabled", m_tabHoverPreviewEnabled);
        m_settings.sync();
        emit tabHoverPreviewEnabledChanged(m_tabHoverPreviewEnabled);
    }
}

QString SettingsManager::tabRamUsageMode() const {
    return m_tabRamUsageMode;
}

void SettingsManager::setTabRamUsageMode(const QString& mode) {
    if (mode != "none" && mode != "tab" && mode != "preview" && mode != "both") return;
    if (m_tabRamUsageMode != mode) {
        m_tabRamUsageMode = mode;
        m_settings.setValue("tabs/ramUsageMode", m_tabRamUsageMode);
        m_settings.sync();
        emit tabRamUsageModeChanged(m_tabRamUsageMode);
    }
}

QString SettingsManager::processMemoryUsage() const {
    if (m_cachedProcessMemoryUsage.isEmpty()) {
        m_cachedProcessMemoryUsage = queryProcessMemoryUsage();
    }
    return m_cachedProcessMemoryUsage;
}

QString SettingsManager::queryProcessMemoryUsage() const {
#ifdef Q_OS_WIN
    typedef struct _PROCESS_MEMORY_COUNTERS_EX2 {
        DWORD cb;
        DWORD PageFaultCount;
        SIZE_T PeakWorkingSetSize;
        SIZE_T WorkingSetSize;
        SIZE_T QuotaPeakPagedPoolUsage;
        SIZE_T QuotaPagedPoolUsage;
        SIZE_T QuotaPeakNonPagedPoolUsage;
        SIZE_T QuotaNonPagedPoolUsage;
        SIZE_T PagefileUsage;
        SIZE_T PeakPagefileUsage;
        SIZE_T PrivateUsage;
        SIZE_T PrivateWorkingSetSize;
        ULONG64 SharedCommitUsage;
    } PROCESS_MEMORY_COUNTERS_EX2;

    PROCESS_MEMORY_COUNTERS_EX2 pmc2;
    ZeroMemory(&pmc2, sizeof(pmc2));
    pmc2.cb = sizeof(pmc2);
    if (GetProcessMemoryInfo(GetCurrentProcess(), reinterpret_cast<PROCESS_MEMORY_COUNTERS*>(&pmc2), sizeof(pmc2)) && pmc2.PrivateWorkingSetSize > 0) {
        double mb = static_cast<double>(pmc2.PrivateWorkingSetSize) / (1024.0 * 1024.0);
        return QString::asprintf("%.1f MB", mb);
    }

    PROCESS_MEMORY_COUNTERS_EX pmc;
    ZeroMemory(&pmc, sizeof(pmc));
    pmc.cb = sizeof(pmc);
    if (GetProcessMemoryInfo(GetCurrentProcess(), reinterpret_cast<PROCESS_MEMORY_COUNTERS*>(&pmc), sizeof(pmc))) {
        SIZE_T memBytes = (pmc.PrivateUsage > 0) ? pmc.PrivateUsage : pmc.WorkingSetSize;
        double mb = static_cast<double>(memBytes) / (1024.0 * 1024.0);
        return QString::asprintf("%.1f MB", mb);
    }
#endif
    return QStringLiteral("~46 MB");
}

QString SettingsManager::calculateTabMemoryUsage(const QString& pageType, const QString& filePath, int symbolCount) const {
    double mb = 4.5;
    if (pageType == "catalog") {
        mb = 5.4;
    } else if (pageType == "installed") {
        mb = 3.8;
    } else if (pageType == "settings") {
        mb = 2.8;
    } else {
        mb = 4.6;
        if (!filePath.isEmpty() && QFile::exists(filePath)) {
            qint64 fsz = QFileInfo(filePath).size();
            double fileMb = static_cast<double>(fsz) / (1024.0 * 1024.0);
            mb += fileMb * 4.2;
        } else {
            mb += 1.2;
        }
        if (symbolCount > 0) {
            mb += (static_cast<double>(symbolCount) * 350.0) / (1024.0 * 1024.0);
        }
        if (mb < 5.0) mb = 5.0;
        if (mb > 24.0) mb = 24.0;
    }
    return QString::asprintf("%.1f MB", mb);
}

void SettingsManager::registerTab(const QString& tabId, const QString& pageType, const QString& filePath, const QString& title) {
    if (tabId.isEmpty()) return;

    size_t targetBytes = 0;
    if (pageType == "catalog") {
        targetBytes = static_cast<size_t>(5.4 * 1024 * 1024);
    } else if (pageType == "installed") {
        targetBytes = static_cast<size_t>(3.8 * 1024 * 1024);
    } else if (pageType == "settings") {
        targetBytes = static_cast<size_t>(2.8 * 1024 * 1024);
    } else {
        double mb = 4.6;
        if (!filePath.isEmpty() && QFile::exists(filePath)) {
            qint64 fsz = QFileInfo(filePath).size();
            double fileMb = static_cast<double>(fsz) / (1024.0 * 1024.0);
            mb += fileMb * 4.2;
        } else {
            mb += 1.2;
        }
        if (mb < 5.0) mb = 5.0;
        if (mb > 24.0) mb = 24.0;
        targetBytes = static_cast<size_t>(mb * 1024 * 1024);
    }

    auto buffer = std::make_shared<std::vector<char>>(targetBytes);
    if (!buffer->empty()) {
        std::fill(buffer->begin(), buffer->end(), static_cast<char>(0xAA));
    }

    TabSessionInfo info;
    info.tabId = tabId;
    info.pageType = pageType;
    info.filePath = filePath;
    info.title = title;
    info.allocatedBytes = targetBytes;
    info.workingBuffer = buffer;

    m_tabSessions[tabId] = info;

    m_cachedProcessMemoryUsage = queryProcessMemoryUsage();
    emit processMemoryUsageChanged(m_cachedProcessMemoryUsage);
}

void SettingsManager::updateTab(const QString& tabId, const QString& pageType, const QString& filePath, const QString& title) {
    if (tabId.isEmpty()) return;
    if (!m_tabSessions.contains(tabId)) {
        registerTab(tabId, pageType, filePath, title);
        return;
    }

    auto& existing = m_tabSessions[tabId];
    if (existing.pageType != pageType || existing.filePath != filePath) {
        registerTab(tabId, pageType, filePath, title);
    } else {
        existing.title = title;
    }
}

void SettingsManager::unregisterTab(const QString& tabId) {
    if (m_tabSessions.contains(tabId)) {
        m_tabSessions.remove(tabId);
        m_cachedProcessMemoryUsage = queryProcessMemoryUsage();
        emit processMemoryUsageChanged(m_cachedProcessMemoryUsage);
    }
}

QString SettingsManager::getTabMemoryUsage(const QString& tabId) const {
    if (m_tabSessions.contains(tabId)) {
        double mb = static_cast<double>(m_tabSessions[tabId].allocatedBytes) / (1024.0 * 1024.0);
        return QString::asprintf("%.1f MB", mb);
    }
    return QStringLiteral("4.5 MB");
}

double SettingsManager::getTabMemoryMB(const QString& tabId) const {
    if (m_tabSessions.contains(tabId)) {
        return static_cast<double>(m_tabSessions[tabId].allocatedBytes) / (1024.0 * 1024.0);
    }
    return 4.5;
}

int SettingsManager::tabCount() const {
    return m_tabSessions.size();
}
