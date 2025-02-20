#include "plugincontroller.h"
#include "pluginservice.h"

#include <QtCore/QDebug>
#include <QtCore/QFile>
#include <QtCore/QJsonObject>
#include <QtCore/QJsonDocument>
#include <QtCore/QDebug>
#include <QtCore/QString>
#include <QtCore/QObject>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlContext>
#include <QtQuick/QQuickView>
// #include <auroraapp.h>
#include <nemonotifications-qt5/notification.h>

#include <pushed_messaging/pushed_messaging_plugin.h>
#include <flutter/method_channel.h>
#include <flutter/flutter_aurora.h>

PluginController::PluginController(PluginRegistrar *registrar)
    : m_notificationsChannel(std::make_unique<MethodChannel>(
          registrar->messenger(),
          "pushed_messaging",
          &StandardMethodCodec::GetInstance())),
      m_notificationsClient(std::make_unique<Aurora::PushNotifications::Client>(qApp))

{
    m_notificationsChannel->SetMethodCallHandler([this](const MethodCall &call, UniqueMethodResult result)
                                                 { on_method_call(call, std::move(result)); });

    // Подключаем сигналы от пуш-клиента к обработчикам
    connect(m_notificationsClient.get(),
            &Aurora::PushNotifications::Client::clientInactive,
            [this]()
            {
                qDebug() << "Aurora::PushNotifications::Client::clientInactive";
                // Возможно, тут стоит добавить перезапуск или уведомление пользователю
            });

    connect(m_notificationsClient.get(),
            &Aurora::PushNotifications::Client::pushSystemReadinessChanged,
            [this](bool status)
            {
                qWarning() << "Push system is" << (status ? "available" : "not available");
                m_notificationsChannel->InvokeMethod("Messaging#onReadinessChanged",
                                                     std::make_unique<EncodableValue>(EncodableValue(status)));
            });

    connect(m_notificationsClient.get(),
            &Aurora::PushNotifications::Client::registrationId,
            this,
            &PluginController::_setRegistrationId);

    connect(m_notificationsClient.get(),
            &Aurora::PushNotifications::Client::registrationError,
            [this]()
            {
                qDebug() << "Push system have problems with registrationId";
                m_notificationsChannel->InvokeMethod(
                    "Messaging#onRegistrationError",
                    std::make_unique<EncodableValue>(EncodableValue("Push system have problems with registrationId")));
            });

    connect(m_notificationsClient.get(),
            &Aurora::PushNotifications::Client::notifications,
            [this](const Aurora::PushNotifications::PushList &pushList)
            {
                for (const auto &push : pushList)
                {
                    QJsonDocument jsonDocument = QJsonDocument::fromJson(push.data.toUtf8());
                    QString notifyType = jsonDocument.object().value("mtype").toString();

                    if (notifyType == QStringLiteral("action"))
                    {
                        continue;
                    }

                    static QVariant defaultAction = Notification::remoteAction(QStringLiteral("default"), tr("Open app"),
                                                                               PluginService::notifyDBusService(),
                                                                               PluginService::notifyDBusPath(),
                                                                               PluginService::notifyDBusIface(),
                                                                               PluginService::notifyDBusMethod());

                    qDebug() << Q_FUNC_INFO << push.title << push.message;

                    EncodableMap pushParams;
                    pushParams.emplace(std::make_pair(EncodableValue("title"), EncodableValue(push.title.toStdString())));
                    pushParams.emplace(std::make_pair(EncodableValue("message"), EncodableValue(push.message.toStdString())));

                    // Notification notification;
                    // notification.setAppName(tr("Push Receiver"));
                    // notification.setSummary(push.title);
                    // notification.setBody(push.message);
                    // notification.setIsTransient(false);
                    // notification.setItemCount(1);
                    // notification.setHintValue("x-nemo-feedback", "sms_exists");
                    // notification.setRemoteAction(defaultAction);
                    // notification.setUrgency(Notification::Urgency::Critical);
                    // notification.publish();

                    m_notificationsChannel->InvokeMethod(
                        "Messaging#onMessage",
                        std::make_unique<EncodableValue>(EncodableValue(pushParams)));
                }
            });
}

void PluginController::on_method_call(const MethodCall &call, UniqueMethodResult result)
{

    if (call.method_name() == "Messaging#init")
    {
        init(call.arguments(), std::move(result));
        return;
    }
    unimplemented(call.arguments(), std::move(result));
}

void PluginController::init(const EncodableValue *args, UniqueMethodResult result)
{
    qDebug() << Q_FUNC_INFO;

    // Инициализация сервисов
    if (!m_service) // Создаём только если не существует
    {
        m_service = std::make_unique<PluginService>(qApp);
    }

    const std::string applicationId = args->GetValue<std::string>("applicationId").value_or("");

    if (applicationId.empty())
    {
        result->Error("-1", "Empty application ID", nullptr);
        return;
    }

    setApplicationId(QString::fromStdString(applicationId));

    result->Success(nullptr);
}

void PluginController::setApplicationId(const QString &applicationId)
{
    qDebug() << Q_FUNC_INFO << applicationId;

    if (applicationId.isEmpty())
    {
        qWarning() << "Empty application id, ignored";
        return;
    }

    if (m_applicationId == applicationId)
    {
        qDebug() << "Application ID is already set, skipping.";
        m_notificationsClient->registrate();
        return;
    }

    m_applicationId = applicationId;
    m_notificationsClient->setApplicationId(applicationId);
    m_notificationsClient->registrate();

    emit applicationIdChanged(applicationId);
    qDebug() << "Application ID set and registered.";
}

void PluginController::unimplemented(const EncodableValue *, UniqueMethodResult response)
{
    response->NotImplemented();
}

void PluginController::_setRegistrationId(const QString &registrationId)
{
    qDebug() << Q_FUNC_INFO << "Received registrationId:" << registrationId;

    // if (registrationId == m_registrationId)
    // {
    //     qDebug() << "Registration ID is the same, skipping...";
    //     return;
    // }

    m_registrationId = registrationId;

    qDebug() << "Sending registrationId to Flutter: " << registrationId.toStdString().c_str();

    m_notificationsChannel->InvokeMethod(
        "Messaging#applicationRegistered",
        std::make_unique<EncodableValue>(EncodableValue(m_registrationId.toStdString())));
}
