#ifndef APPLICATIONCONTROLLER_H
#define APPLICATIONCONTROLLER_H

#include <push_client.h>

#include <flutter/method_channel.h>

#include <QtCore/QObject>
#include <memory>
#include "types.h"
#include "pluginservice.h"
// //******************************************************************************
// //******************************************************************************
class QQuickView;
class PluginController : public QObject
{
    Q_OBJECT

public:
    explicit PluginController(PluginRegistrar *registrar);

    QString applicationId() const;
    void setApplicationId(const QString &applicationId);

    QString registrationId() const;

signals:
    void applicationIdChanged(const QString &applicationId);
    void registrationIdChanged(const QString &registrationId);
    void pushMessageReceived(const Aurora::PushNotifications::Push &push);

private:
    void on_method_call(const MethodCall &call, UniqueMethodResult result);
    void unimplemented(const EncodableValue *args, UniqueMethodResult result);
    void init(const EncodableValue *args, UniqueMethodResult result);

    std::unique_ptr<MethodChannel> m_notificationsChannel;
    std::unique_ptr<PluginService> m_service;
    std::unique_ptr<Aurora::PushNotifications::Client> m_notificationsClient;

    QString m_applicationId;
    QString m_registrationId;

    QQuickView *m_view{nullptr};

private slots:
    void _setRegistrationId(const QString &registrationId);
};

#endif // APPLICATIONCONTROLLER_H
//******************************************************************************
//******************************************************************************
