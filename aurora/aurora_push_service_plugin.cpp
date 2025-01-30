
#include "aurora_push_service/aurora_push_service_plugin.h"
#include <QtCore/QDebug>

void AuroraPushServicePlugin::RegisterWithRegistrar(PluginRegistrar *registrar)
{
    registrar->AddPlugin(
        std::make_unique<AuroraPushServicePlugin>(std::make_unique<PluginController>(registrar)));
}

AuroraPushServicePlugin::AuroraPushServicePlugin(std::unique_ptr<PluginController> plugin_controller)
    : m_plugin_controller(std::move(plugin_controller)) // Перемещаем указатель в поле класса
{
    qDebug() << Q_FUNC_INFO << "AuroraPushServicePlugin initialized";
}
