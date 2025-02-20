// Copyright (c) 2023, Friflex LLC. Please see the AUTHORS file
// for details. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:pushed_messaging/src/aurora_push_exception.dart';
import 'package:pushed_messaging/src/aurora_push_message.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'pushed_messaging_platform_interface.dart';

class PushedMessagingAurora extends PushedMessagingPlatform {
  WebSocketChannel? webChannel;
  StreamSubscription? subs;
  Function? bgHandler;
  bool active = false;
  @visibleForTesting
  static const channel = MethodChannel('pushed_messaging');

  @visibleForTesting
  static Completer<String>? initCompleter;

  static void setMethodCallHandlers() {
    WidgetsFlutterBinding.ensureInitialized();
    PushedMessagingAurora.channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'Messaging#onMessage':
          final messageMap = Map<String, dynamic>.from(call.arguments);
          print(messageMap);
          PushedMessagingPlatform.messageController.sink.add(messageMap);
          break;
        case 'Messaging#onReadinessChanged':
          final isAvailable = call.arguments as bool;
          if (!isAvailable) {
            initCompleter?.completeError(AuroraPushException(
              code: 'push_system_not_available',
              message: 'todo: Push system is not available',
            ));
          }
          break;
        case 'Messaging#onRegistrationError':
          // На данный момент от платформы не приходит информация о причине
          // ошибки при регистрации. Также не понятно когда оно приходит.
          final message = call.arguments.toString();
          initCompleter?.completeError(AuroraPushException(
            code: 'registration_error',
            message: message,
          ));
          break;
        case 'Messaging#applicationRegistered':
          final registrationId = call.arguments as String;
          initCompleter?.complete(registrationId);
          break;
      }
    });
  }

  @override
  Future<String> initialize(Function(Map<dynamic, dynamic>) bgHandler,
      {required String applicationId}) async {
    if (initCompleter != null) {
      throw AuroraPushException(
        code: 'init_completer_not_finished',
        message:
            'initCompleter not finished. You must not call initialize before finishing.',
      );
    }
    if (applicationId.isEmpty) {
      throw AuroraPushException(
        code: 'application_id_empty',
        message:
            'ApplicationId is empty. Set applicationId from Aurora Center.',
      );
    }
    await channel.invokeMethod('Messaging#init', {
      'applicationId': applicationId,
    });
    initCompleter = Completer();
    // Ждем исполнения Messaging#onReadinessChanged и Messaging#applicationRegistered
    // Также может вернуться ошибка в Messaging#onRegistrationError
    try {
      // При возникновении нетипичных ошибок Aurora не возвращает ошибки,
      // поэтому нужно ставить timeout.
      final registrationId = await initCompleter!.future.timeout(
        const Duration(seconds: 5),
      );
      // Сбрасываем initCompleter чтобы не вызывать потенциальных ошибок с
      // получением нескольких колбеков от аврора-side плагина.
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";
      final newToken =
          await getNewToken(token, auroraRegistrationId: registrationId);

      PushedMessagingPlatform.pushToken = newToken;
      print(newToken);
      if (newToken.isNotEmpty) {
        await connect(newToken, bgHandler);
      }
      initCompleter = null;
      PushedMessagingPlatform.auroraRegistrationId = registrationId;

      await connect(token, bgHandler);
      return registrationId;
    } on TimeoutException catch (e, s) {
      initCompleter = null;

      /// Эта ошибка может происходить по разным причинам.
      ///
      /// К сожалению, сейчас api не предоставляет ошибок по каким именно
      /// причинам не удалось получить [registrationId].
      ///
      /// Для получения логов запуска пуш сервиса запустите приложение
      /// через консоль.
      ///
      /// Troubleshoot:
      /// * Проверьте подключение телефона к Аврора Центру.
      /// * Проверьте валидность [applicationId]. Если в консоли вы
      /// видите "Can not request push notifications right now", значит
      /// проблема с невалидным applicationId.
      /// * Проверьте интернет соединение пользователя.
      /// * Проверьте соединение с Аврора Центром.
      Error.throwWithStackTrace(
        AuroraPushException(
          code: 'response_timeout',
          message:
              'initialize(applicationId: $applicationId) вернул TimeoutException',
        ),
        s,
      );
    } on Object {
      initCompleter = null;
      rethrow;
    }
  }

  Future<void> connect(String token, Function? onMessage) async {
    final prefs = await SharedPreferences.getInstance();
    if (active) return;
    active = true;

    try {
      print("Connecting to WebSocket with token: $token");

      // Close any existing connections before starting a new one
      await subs?.cancel();
      webChannel?.sink.close();

      webChannel = WebSocketChannel.connect(
        Uri.parse('wss://sub.pushed.ru/v1/$token'),
      );

      await webChannel?.ready;
      // await setNewStatus(ServiceStatus.active);

      subs = webChannel?.stream.listen((event) async {
        var message = utf8.decode(event);
        // await addLog("Pushed message: $message");
        // await loggerAdd("Pushed message: $message");

        if (message != "ONLINE") {
          try {
            var payload = json.decode(message);

            if (payload is Map<String, dynamic>) {
              var messageId = payload["messageId"]?.toString() ?? "";
              var traceId = payload["mfTraceId"]?.toString() ?? "";

              var lastMessageId = prefs.getString('lastMessageId');
              if (lastMessageId != messageId) {
                // await loggerAdd("Processing pushed message");
                await prefs.setString('lastMessageId', messageId);

                var response = json.encode({
                  "messageId": messageId,
                  if (traceId.isNotEmpty) "mfTraceId": traceId
                });
                webChannel?.sink.add(utf8.encode(response));

                if (payload["data"] is String) {
                  try {
                    payload["data"] = json.decode(payload["data"]);
                  } catch (e) {
                    // await loggerAdd(
                    //     "Failed to parse 'data' as JSON, using raw string");
                    payload["data"] = {"body": payload["data"]};
                  }
                }

                // Handle received message callback
                final messageMap = {
                  "data": {
                    "title": payload["data"]["title"] ?? "",
                    "body": payload["data"]["body"] ?? "You have a new message."
                  }
                };

                if (onMessage != null) {
                  await onMessage(messageMap);
                }
              }
            } else {
              // await loggerAdd("Received unexpected message format: $message");
            }
          } catch (e) {
            // await loggerAdd("Error processing pushed message: $e");
          }
        }
      }, onDone: () async {
        active = false;
        // await setNewStatus(ServiceStatus.disconnected);
        await Future.delayed(const Duration(seconds: 1));
        connect(token, onMessage);
      });
    } catch (e) {
      // await loggerAdd("Error: $e");
      connect(token, onMessage);
    }
  }
}
