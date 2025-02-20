#ifndef FLUTTER_PLUGIN_AURORA_PUSH_SERVICE_PLUGIN_H
#define FLUTTER_PLUGIN_AURORA_PUSH_SERVICE_PLUGIN_H

#include <flutter/plugin_registrar.h>
#include <pushed_messaging/globals.h>
#include "types.h"
#include "plugincontroller.h"
#include <memory>
#include <QtCore/QObject>

class PLUGIN_EXPORT PushedMessagingPlugin final : public Plugin
{
public:
    PushedMessagingPlugin(std::unique_ptr<PluginController> plugin_controller);

    static void RegisterWithRegistrar(PluginRegistrar *registrar);

private:
    void onMethodCall(const MethodCall &call, UniqueMethodResult result);
    void init(const MethodCall &call, UniqueMethodResult result);
    void unimplemented(UniqueMethodResult result);
    std::unique_ptr<PluginController> m_plugin_controller;
};

#endif /* FLUTTER_PLUGIN_AURORA_PUSH_SERVICE_PLUGIN_H */
