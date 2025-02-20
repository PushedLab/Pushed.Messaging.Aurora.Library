// Copyright (c) 2023, Friflex LLC. Please see the AUTHORS file
// for details. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pushed_messaging/src/aurora_push_message.dart';
import 'pushed_messaging_platform_interface.dart';

enum ServiceStatus { notActive, disconnected, active }

/// Сервис для получения пуш уведомлений от ОС Аврора и Аврора Центра.
class PushedMessaging {
  const PushedMessaging();
  
  static String? get token => PushedMessagingPlatform.pushToken;
  /// Инициализация пуш сервиса.
  ///
  /// Можно вызывать несколько раз, но не имеет практического смысла.
  Future<String> initialize(Function(Map<dynamic, dynamic>) bgHandler,
      {required String applicationId}) {
    return PushedMessagingPlatform.instance
        .initialize(bgHandler, applicationId: applicationId);
  }

  /// [Stream] с приходящими пушами от Аврора центра.
  ///
  /// По умолчанию они не показываются, поэтому нужно
  /// использовать [FlutterLocalNotificationsPlugin](https://gitlab.com/omprussia/flutter/flutter-plugins/-/tree/master/packages/flutter_local_notifications/flutter_local_notifications_aurora?ref_type=heads).
  Stream<Map<dynamic, dynamic>> get onMessage =>
      PushedMessagingPlatform.onMessage;

  Future<String?> getNewToken(String? token) async {
    return PushedMessagingPlatform.instance.getNewToken(token!);
  }
}
