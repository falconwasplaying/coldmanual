#pragma once

#include <QObject>
#include <QTimer>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class NetworkManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isOnline READ isOnline NOTIFY isOnlineChanged)
    Q_PROPERTY(bool isChecking READ isChecking NOTIFY isCheckingChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(bool simulateOffline READ simulateOffline WRITE setSimulateOffline NOTIFY simulateOfflineChanged)

public:
    explicit NetworkManager(QObject* parent = nullptr);
    ~NetworkManager() override;

    bool isOnline() const;
    bool isChecking() const { return m_isChecking; }
    QString statusMessage() const { return m_statusMessage; }
    bool simulateOffline() const { return m_simulateOffline; }
    void setSimulateOffline(bool simulate);

    Q_INVOKABLE void checkConnectivity();

signals:
    void isOnlineChanged(bool isOnline);
    void isCheckingChanged(bool isChecking);
    void statusMessageChanged(const QString& statusMessage);
    void simulateOfflineChanged(bool simulateOffline);
    void connectivityRestored();
    void connectivityLost();

private slots:
    void onProbeFinished(QNetworkReply* reply);
    void onPeriodicCheck();

private:
    void setupNetworkInformation();
    void performProbe();
    void setIsOnline(bool online, const QString& reason = QString());
    void setIsChecking(bool checking);
    bool checkSystemAdapterStatus() const;

    bool m_isOnline{true};
    bool m_isChecking{false};
    bool m_simulateOffline{false};
    QString m_statusMessage{QStringLiteral("Connected")};
    bool m_usesNetworkInfo{false};

    QNetworkAccessManager* m_nam{nullptr};
    QTimer* m_periodicTimer{nullptr};
    QNetworkReply* m_activeProbeReply{nullptr};
};
