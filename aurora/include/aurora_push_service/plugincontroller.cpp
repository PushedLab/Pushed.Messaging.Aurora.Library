#include "plugincontroller.h"
#include "pluginservice.h"

#include <QtCore/QDebug>
#include <QtCore/QFile>
#include <QtCore/QJsonObject>
#include <QtCore/QJsonDocument>
#include <QtCore/QDebug>
#include <QtCore/QString>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlContext>
#include <QtQuick/QQuickView>
// #include <auroraapp.h>
#include <nemonotifications-qt5/notification.h>

#include <aurora_push_service/aurora_push_service_plugin.h>
#include <flutter/method_channel.h>

PluginController::PluginController(PluginRegistrar *registrar)
    : m_notificationsChannel(std::make_unique<MethodChannel>(
          registrar->messenger(),
          "friflex/aurora_push_service",
          &StandardMethodCodec::GetInstance())),
      m_notificationsClient(std::make_unique<Aurora::PushNotifications::Client>(qApp))

{
    m_notificationsChannel->SetMethodCallHandler([this](const MethodCall &call, UniqueMethodResult result)
                                                 { on_method_call(call, std::move(result)); });
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
    m_service = std::make_unique<PluginService>(qApp);

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
        return;
    }

    m_applicationId = applicationId;
    m_notificationsClient->setApplicationId(applicationId);
    m_notificationsClient->registrate();

    qDebug() << "Application ID set and registered.";
}

void PluginController::unimplemented(const EncodableValue *, UniqueMethodResult response)
{
    response->NotImplemented();
}
