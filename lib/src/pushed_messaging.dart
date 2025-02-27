// Copyright (c) 2023, Friflex LLC. Please see the AUTHORS file
// for details. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pushed_messaging/pushed_messaging.dart';
import 'package:pushed_messaging/src/aurora_push_message.dart';
import 'pushed_messaging_platform_interface.dart';

enum ServiceStatus { notActive, disconnected, active }

/// Сервис для получения пуш уведомлений от ОС Аврора и Аврора Центра.
class PushedMessaging {
  // const PushedMessaging();

  static String? get token => PushedMessagingPlatform.pushToken;

  static ServiceStatus get status => PushedMessagingPlatform.status;

  /// Инициализация пуш сервиса.
  ///
  /// Можно вызывать несколько раз, но не имеет практического смысла.
  Future<String> init(BackgroundHandler bgHandler,
      {required String applicationId}) {
    return PushedMessagingPlatform.instance
        .init(bgHandler, applicationId: applicationId);
  }

  /// [Stream] с приходящими пушами от Аврора центра или Pushed.
  Stream<Map<dynamic, dynamic>> get onMessage =>
      PushedMessagingPlatform.onMessage;

  /// [Stream] с состоянием соединения Аврора центра или Pushed.
  Stream<ServiceStatus> get onStatus => PushedMessagingPlatform.onStatus;

}
