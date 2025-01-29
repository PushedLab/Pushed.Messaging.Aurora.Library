// /*******************************************************************************
// ** Copyright (c) 2023, Friflex LLC. Please see the AUTHORS file
// ** for details. Use of this source code is governed by a
// ** BSD-style license that can be found in the LICENSE file.
// *******************************************************************************/

// //******************************************************************************
// //******************************************************************************

// #include "aurora_push_service/plugincontroller.h"
// #include "aurora_push_service/pluginservice.h"

// #include <aurora_push_service/aurora_push_service_plugin.h>
// #include <flutter/method_channel.h>

// #include <QtDBus/QtDBus>
// #include <QtCore/QString>

// //******************************************************************************
// //******************************************************************************
// class AuroraPushServicePlugin::impl
// {
//     friend class AuroraPushServicePlugin;

//     std::shared_ptr<PluginController> m_controller;
//     std::shared_ptr<PluginService> m_service;
// };

// //******************************************************************************
// //******************************************************************************
// AuroraPushServicePlugin::AuroraPushServicePlugin()
// // : PluginInterface(), m_p(new impl)
// {
//     qDebug() << Q_FUNC_INFO;
// }

// //******************************************************************************
// //******************************************************************************
// void AuroraPushServicePlugin::RegisterWithRegistrar(PluginRegistrar &registrar)
//     : m_channel(std::make_unique<MethodChannel>(
//           registrar->messenger(),
//           "be.tramckrijte.workmanager/background_channel_work_manager",
//           &StandardMethodCodec::GetInstance()))
// {

//     m_channel->SetMethodCallHandler([this](const MethodCall &call, UniqueMethodResult result)
//                                     { onMethodCall(call, std::move(result)); });

//     // registrar.RegisterMethodChannel("friflex/aurora_push_service",
//     //                                 MethodCodecType::Standard,
//     //                                 [this](const MethodCall &call)
//     //                                 {
//     //                                     this->onMethodCall(call);
//     //                                 });
// }

// //******************************************************************************
// //******************************************************************************
// void AuroraPushServicePlugin::onMethodCall(const MethodCall &call, UniqueMethodResult result)
// {
//     // const auto &method = call.GetMethod();

//     if (call.method_name() == "Messaging#init")
//     {
//         init(call, std::move(result));
//         return;
//     }

//     unimplemented(std::move(result));
// }

// //******************************************************************************
// //******************************************************************************
// void AuroraPushServicePlugin::init(const MethodCall &call, UniqueMethodResult result)
// {
//     qDebug() << Q_FUNC_INFO;

//     m_p->m_service.reset(new PluginService(qApp));
//     m_p->m_controller.reset(new PluginController(qApp));

//     QObject::connect(m_p->m_service.get(), &PluginService::guiRequested,
//                      m_p->m_controller.get(), &PluginController::showGui);

//     // ✅ Получаем applicationId с обработкой std::optional
//     std::optional<std::string> appIdOpt = call.arguments()->GetValue<std::string>("applicationId");

//     if (!appIdOpt.has_value() || appIdOpt->empty())
//     {
//         // call.SendErrorResponse("-1", "Empty application ID", nullptr);
//         result->Error("Empty application ID");
//         return;
//     }

//     const std::string applicationId = *appIdOpt; // Разыменовываем `std::optional`
//     m_p->m_controller->setApplicationId(QString::fromStdString(applicationId));

//     result->Success(true);
// }

// //******************************************************************************
// //******************************************************************************
// void AuroraPushServicePlugin::unimplemented(UniqueMethodResult result)
// {
//     //  TODO(mozerrr): заменить на void SendErrorResponse(const std::string &code, const std::string &message, const Encodable &details) const;
//     result->Success(true);
// }

#include "aurora_push_service/aurora_push_service_plugin.h"
#include <QtCore/QDebug>
void AuroraPushServicePlugin::RegisterWithRegistrar(PluginRegistrar *registrar)
{
    registrar->AddPlugin(std::make_unique<AuroraPushServicePlugin>());
}

AuroraPushServicePlugin::AuroraPushServicePlugin()
{
    qDebug() << Q_FUNC_INFO;
}

// void AuroraPushServicePlugin::initialize(const EncodableValue *, UniqueMethodResult result)
// {
//     result->Success();
// }
