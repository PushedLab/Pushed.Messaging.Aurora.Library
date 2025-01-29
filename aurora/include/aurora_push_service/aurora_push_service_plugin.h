// /*******************************************************************************
// ** Copyright (c) 2023, Friflex LLC. Please see the AUTHORS file
// ** for details. Use of this source code is governed by a
// ** BSD-style license that can be found in the LICENSE file.
// *******************************************************************************/

// //******************************************************************************
// //******************************************************************************

// #ifndef FLUTTER_PLUGIN_AURORA_PUSH_SERVICE_PLUGIN_H
// #define FLUTTER_PLUGIN_AURORA_PUSH_SERVICE_PLUGIN_H

// #include <flutter/plugin_registrar.h>
// #include <aurora_push_service/globals.h>

// #include <QtCore/QObject>
// #include "types.h"
// #include <memory>

// //******************************************************************************
// //******************************************************************************
// class PLUGIN_EXPORT AuroraPushServicePlugin final : public Plugin
// {
// public:
//     AuroraPushServicePlugin();

//     static void RegisterWithRegistrar(PluginRegistrar &registrar);

// private:
//     void onMethodCall(const MethodCall &call, UniqueMethodResult result);
//     void init(const MethodCall &call, UniqueMethodResult result);
//     void unimplemented(UniqueMethodResult result);
//     std::unique_ptr<MethodChannel> m_channel;

// private:
//     class impl;
//     std::shared_ptr<impl> m_p;
// };

// #endif /* FLUTTER_PLUGIN_AURORA_PUSH_SERVICE_PLUGIN_H */
#ifndef FLUTTER_PLUGIN_AURORA_PUSH_SERVICE_PLUGIN_H
#define FLUTTER_PLUGIN_AURORA_PUSH_SERVICE_PLUGIN_H

#include <flutter/plugin_registrar.h>
#include <aurora_push_service/globals.h>
#include "types.h"
#include <memory>
#include <QtCore/QObject>

class PLUGIN_EXPORT AuroraPushServicePlugin final : public Plugin
{
public:
    AuroraPushServicePlugin();

    static void RegisterWithRegistrar(PluginRegistrar *registrar);

private:
    void onMethodCall(const MethodCall &call, UniqueMethodResult result);
    void init(const MethodCall &call, UniqueMethodResult result);
    void unimplemented(UniqueMethodResult result);
    std::unique_ptr<MethodChannel> m_channel;
};

#endif /* FLUTTER_PLUGIN_AURORA_PUSH_SERVICE_PLUGIN_H */
