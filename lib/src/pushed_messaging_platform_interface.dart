// Copyright (c) 2023, Friflex LLC. Please see the AUTHORS file
// for details. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:pushed_messaging/pushed_messaging.dart';
import 'package:pushed_messaging/src/aurora_push_message.dart';
import 'package:pushed_messaging/src/pushed_messaging_aurora.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

abstract class PushedMessagingPlatform extends PlatformInterface {
  /// Constructs a PushedMessagingPlatform.
  PushedMessagingPlatform() : super(token: _token);

  static final Object _token = Object();

  static PushedMessagingPlatform? _instance;

  static var messageController =
      StreamController<Map<dynamic, dynamic>>.broadcast(sync: true);
  static var statusController =
      StreamController<ServiceStatus>.broadcast(sync: true);

  static ServiceStatus status = ServiceStatus.notActive;
  static String? pushToken;
  static String? auroraRegistrationId;
  static Stream<Map<dynamic, dynamic>> get onMessage =>
      messageController.stream;
  static Stream<ServiceStatus> get onStatus => statusController.stream;

  /// The default instance of [PushedMessagingPlatform] to use.
  ///
  /// Defaults to [MethodChannelAuroraPush].
  static PushedMessagingPlatform get instance {
    if (_instance == null) {
      PushedMessagingAurora.setMethodCallHandlers();
      instance = PushedMessagingAurora();
    }
    return _instance!;
  }

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PushedMessagingPlatform] when
  /// they register themselves.
  static set instance(PushedMessagingPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String> initialize(Function(Map<dynamic, dynamic>) bgHandler,
      {required String applicationId}) {
    throw UnimplementedError('init() has not been implemented.');
  }

  static Future<bool> confirmDelivered(
      String token, String messageId, String transport, String? traceId) async {
    var result = true;
    var basicAuth = "Basic ${base64.encode(utf8.encode('$token:$messageId'))}";
    try {
      await http
          .post(
              Uri.parse(
                  'https://pub.pushed.ru/v2/confirm?transportKind=$transport'),
              headers: {
                "Content-Type": "application/json",
                if (traceId != null) "mf-trace-id": traceId,
                "Authorization": basicAuth
              },
              body: "")
          .timeout(const Duration(seconds: 10),
              onTimeout: (() => throw Exception("TimeOut")));
    } catch (e) {
      result = false;
    }
    return (result);
  }

  Future<String> getNewToken(String token,
      {String? auroraRegistrationId}) async {
    var deviceSettings = [
      if (auroraRegistrationId != null)
        {"deviceToken": auroraRegistrationId, "transportKind": "AuroraCenter"},
    ];
    final body = json.encode(<String, dynamic>{
      "clientToken": token,
      if (deviceSettings.isNotEmpty) "deviceSetting": deviceSettings
    });
    try {
      var response = await http
          .post(Uri.parse('https://sub.pushed.ru/tokens'),
              headers: {"Content-Type": "application/json"}, body: body)
          .timeout(const Duration(seconds: 10),
              onTimeout: (() => throw Exception("TimeOut")));
      token = json.decode(response.body)["token"];
      print(token);
    } catch (e) {
      token = "";
    }
    return token;
  }
}
