#include "NetworkManager.h"
#include <QNetworkInformation>
#include <QNetworkRequest>
#include <QUrl>
#include <QDebug>

#ifdef Q_OS_WIN
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <wininet.h>
#include <objbase.h>
#endif

NetworkManager::NetworkManager(QObject* parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
    , m_periodicTimer(new QTimer(this))
{
    // 1. Initial system adapter check
    bool adapterActive = checkSystemAdapterStatus();
    if (!adapterActive) {
        m_isOnline = false;
        m_statusMessage = QStringLiteral("Network adapter disconnected");
    }

    // 2. Setup Qt 6 OS-level Network Information if available
    setupNetworkInformation();

    // 3. Periodic sanity check timer (every 10 seconds)
    m_periodicTimer->setInterval(10000);
    connect(m_periodicTimer, &QTimer::timeout, this, &NetworkManager::onPeriodicCheck);
    m_periodicTimer->start();

    // 4. Perform initial probe if adapter is active
    if (adapterActive) {
        performProbe();
    }
}

NetworkManager::~NetworkManager() {
    if (m_periodicTimer) {
        m_periodicTimer->stop();
    }
    if (m_usesNetworkInfo) {
        auto* netInfo = QNetworkInformation::instance();
        if (netInfo) {
            netInfo->disconnect(this);
        }
    }
    if (m_activeProbeReply) {
        m_activeProbeReply->disconnect();
        m_activeProbeReply->abort();
        delete m_activeProbeReply;
        m_activeProbeReply = nullptr;
    }
}

bool NetworkManager::isOnline() const {
    if (m_simulateOffline) {
        return false;
    }
    return m_isOnline;
}

void NetworkManager::setSimulateOffline(bool simulate) {
    if (m_simulateOffline == simulate) return;
    m_simulateOffline = simulate;
    emit simulateOfflineChanged(m_simulateOffline);
    emit isOnlineChanged(isOnline());
    if (m_simulateOffline) {
        emit connectivityLost();
    } else {
        checkConnectivity();
    }
}

void NetworkManager::checkConnectivity() {
    if (m_simulateOffline) {
        setIsOnline(false, QStringLiteral("Simulated offline mode"));
        return;
    }

    if (!checkSystemAdapterStatus()) {
        setIsOnline(false, QStringLiteral("Network adapter disconnected"));
        return;
    }

    performProbe();
}

void NetworkManager::setupNetworkInformation() {
#ifndef Q_OS_WIN
    if (QNetworkInformation::instance() || QNetworkInformation::loadDefaultBackend()) {
        auto* netInfo = QNetworkInformation::instance();
        if (netInfo) {
            m_usesNetworkInfo = true;
            connect(netInfo, &QNetworkInformation::reachabilityChanged, this, [this](QNetworkInformation::Reachability reach) {
                if (m_simulateOffline) return;

                if (reach == QNetworkInformation::Reachability::Disconnected ||
                    reach == QNetworkInformation::Reachability::Local) {
                    setIsOnline(false, QStringLiteral("Network disconnected"));
                } else if (reach == QNetworkInformation::Reachability::Online) {
                    performProbe();
                }
            });
        }
    }
#endif
}

bool NetworkManager::checkSystemAdapterStatus() const {
#ifdef Q_OS_WIN
    DWORD flags = 0;
    BOOL connected = InternetGetConnectedState(&flags, 0);
    if (!connected) {
        return false;
    }
#endif
    return true;
}

void NetworkManager::performProbe() {
    if (m_simulateOffline) return;
    if (m_isChecking) return;

    if (!checkSystemAdapterStatus()) {
        setIsOnline(false, QStringLiteral("Network adapter disconnected"));
        return;
    }

    setIsChecking(true);

    if (m_activeProbeReply) {
        m_activeProbeReply->disconnect();
        m_activeProbeReply->abort();
        m_activeProbeReply->deleteLater();
        m_activeProbeReply = nullptr;
    }

    // Zero-overhead probe endpoint returning HTTP 204 No Content
    QNetworkRequest req(QUrl(QStringLiteral("http://www.gstatic.com/generate_204")));
    req.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);
    req.setTransferTimeout(2500); // 2.5 second timeout

    m_activeProbeReply = m_nam->head(req);
    connect(m_activeProbeReply, &QNetworkReply::finished, this, [this]() {
        if (m_activeProbeReply) {
            onProbeFinished(m_activeProbeReply);
        }
    });
}

void NetworkManager::onProbeFinished(QNetworkReply* reply) {
    if (!reply) return;
    reply->disconnect();
    reply->deleteLater();

    if (reply == m_activeProbeReply) {
        m_activeProbeReply = nullptr;
    }
    setIsChecking(false);

    if (m_simulateOffline) return;

    if (reply->error() == QNetworkReply::NoError) {
        int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (statusCode == 204 || (statusCode >= 200 && statusCode < 400)) {
            setIsOnline(true, QStringLiteral("Connected"));
            return;
        }
    }

    // If primary probe failed, mark as offline with descriptive reason
    setIsOnline(false, QStringLiteral("No internet connection"));
}

void NetworkManager::onPeriodicCheck() {
    if (m_simulateOffline) return;

    bool adapterActive = checkSystemAdapterStatus();
    if (!adapterActive) {
        if (m_isOnline) {
            setIsOnline(false, QStringLiteral("Network adapter disconnected"));
        }
        return;
    }

    // If currently offline, probe to detect restoration
    if (!m_isOnline) {
        performProbe();
    }
}

void NetworkManager::setIsOnline(bool online, const QString& reason) {
    bool effectiveBefore = isOnline();
    m_isOnline = online;
    m_statusMessage = online ? QStringLiteral("Connected") : (reason.isEmpty() ? QStringLiteral("Offline") : reason);

    bool effectiveAfter = isOnline();
    if (effectiveBefore != effectiveAfter) {
        emit isOnlineChanged(effectiveAfter);
        emit statusMessageChanged(m_statusMessage);
        if (effectiveAfter) {
            qDebug() << "NetworkManager: Connectivity restored (" << m_statusMessage << ")";
            emit connectivityRestored();
        } else {
            qDebug() << "NetworkManager: Connectivity lost (" << m_statusMessage << ")";
            emit connectivityLost();
        }
    }
}

void NetworkManager::setIsChecking(bool checking) {
    if (m_isChecking == checking) return;
    m_isChecking = checking;
    emit isCheckingChanged(m_isChecking);
}
