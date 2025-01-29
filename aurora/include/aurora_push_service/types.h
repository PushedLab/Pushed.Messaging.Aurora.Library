/*
 * SPDX-FileCopyrightText: Copyright 2024 Open Mobile Platform LLC <community@omp.ru>
 * SPDX-License-Identifier: BSD-3-Clause
 */

#ifndef FLUTTER_PLUGIN_WORKMANAGER_PLUGIN_TYPES_H
#define FLUTTER_PLUGIN_WORKMANAGER_PLUGIN_TYPES_H

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>
#include <flutter/method_result_functions.h>

using EncodableMap = flutter::EncodableMap;
using EncodableValue = flutter::EncodableValue;
using MethodCall = flutter::MethodCall<EncodableValue>;
using MethodChannel = flutter::MethodChannel<EncodableValue>;
using MethodInvocationResultFuncs = flutter::MethodResultFunctions<>;
using MethodResult = flutter::MethodResult<EncodableValue>;
using Plugin = flutter::Plugin;
using PluginRegistrar = flutter::PluginRegistrar;
using SharedMethodResult = std::shared_ptr<MethodResult>;
using StandardMethodCodec = flutter::StandardMethodCodec;
using UniqueMethodResult = std::unique_ptr<MethodResult>;

#endif /* FLUTTER_PLUGIN_WORKMANAGER_PLUGIN_TYPES_H */
