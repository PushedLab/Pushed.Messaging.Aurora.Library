
#include "pushed_messaging/pushed_messaging_plugin.h"
#include <QtCore/QDebug>

void PushedMessagingPlugin::RegisterWithRegistrar(PluginRegistrar *registrar)
{
    registrar->AddPlugin(
        std::make_unique<PushedMessagingPlugin>(std::make_unique<PluginController>(registrar)));
}

PushedMessagingPlugin::PushedMessagingPlugin(std::unique_ptr<PluginController> plugin_controller)
    : m_plugin_controller(std::move(plugin_controller)) // Перемещаем указатель в поле класса
{
    qDebug() << Q_FUNC_INFO << "PushedMessagingPlugin initialized";
}
