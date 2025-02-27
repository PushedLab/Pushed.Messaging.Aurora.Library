// Copyright (c) 2023, Friflex LLC. Please see the AUTHORS file
// for details. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pushed_messaging/src/pushed_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:pushed_messaging/src/aurora_push_exception.dart';
import 'package:pushed_messaging/src/aurora_push_message.dart';
import 'pushed_messaging_platform_interface.dart';

typedef BackgroundHandler = Future<void> Function(Map<dynamic, dynamic>);

class PushedMessagingAurora extends PushedMessagingPlatform {
  WebSocketChannel? webChannel;
  StreamSubscription? subs;
  bool active = false;

  // We store the user-provided background handler here:
  static BackgroundHandler? onBackgroundMessage;

  @visibleForTesting
  static const channel = MethodChannel('pushed_messaging');

  @visibleForTesting
  static Completer<String>? initCompleter;

  /// Set up method channel listeners.
  /// Make sure to call this once (e.g. in your plugin setup or main())
  /// so that we can handle incoming messages from the native side.
  static void setMethodCallHandlers() {
    WidgetsFlutterBinding.ensureInitialized();
    PushedMessagingAurora.channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'Messaging#onMessage':
          final messageMap = Map<String, dynamic>.from(call.arguments);
          final messageId = messageMap['messageId'];
          final dynamic traceId = messageMap['traceId'];
          final prefs = await SharedPreferences.getInstance();

          var lastMessageId = prefs.getString('lastMessageId');
          await PushedMessagingPlatform.confirmDelivered(
            PushedMessagingPlatform.pushToken!,
            messageId,
            'Aurora',
            traceId,
          );
          // Check if this messageId has already been processed
          if (lastMessageId != messageId) {
            // If not, add it to the stream and update the lastMessageId
            PushedMessagingPlatform.messageController.sink.add(messageMap);

            // Store the current messageId in SharedPreferences to avoid processing the same one again
            await prefs.setString('lastMessageId', messageId);

            print("Aurora messageid : $messageId");
            if (onBackgroundMessage != null) {
              await onBackgroundMessage!.call(messageMap);
            }
          } else {
            print("Duplicate message detected, skipping.");
          }

          // Optionally invoke background handler if present
          break;

        case 'Messaging#onReadinessChanged':
          final isAvailable = call.arguments as bool;
          if (!isAvailable) {
            initCompleter?.completeError(
              AuroraPushException(
                code: 'push_system_not_available',
                message: 'Push system is not available',
              ),
            );
          }
          break;

        case 'Messaging#onRegistrationError':
          // From the platform, we don't have a detailed reason.
          // We just pass the error upward.
          final message = call.arguments.toString();
          initCompleter?.completeError(
            AuroraPushException(
              code: 'registration_error',
              message: message,
            ),
          );
          break;

        case 'Messaging#applicationRegistered':
          final registrationId = call.arguments as String;
          initCompleter?.complete(registrationId);
          break;
      }
    });
  }

  @override
  Future<String> init(
    BackgroundHandler bgHandler, {
    required String applicationId,
  }) async {
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

    // Assign the user-provided background handler to our static reference
    onBackgroundMessage = bgHandler;

    await channel.invokeMethod('Messaging#init', {
      'applicationId': applicationId,
    });
    initCompleter = Completer();

    try {
      // We wait for 'Messaging#onReadinessChanged' and 'Messaging#applicationRegistered'
      // or for a possible error in 'Messaging#onRegistrationError'
      final registrationId = await initCompleter!.future.timeout(
        const Duration(seconds: 5),
      );

      initCompleter = null;
      PushedMessagingPlatform.auroraRegistrationId = registrationId;

      final prefs = await SharedPreferences.getInstance();
      final oldToken = prefs.getString('token') ?? "";

      // Suppose you have some logic to get a new token from your server:
      final newToken = await getNewToken(
        oldToken,
        auroraRegistrationId: registrationId,
      );
      await prefs.setString('token', newToken);
      PushedMessagingPlatform.pushToken = newToken;
      print("Got new push token: $newToken");

      if (newToken.isNotEmpty) {
        await connect(newToken, bgHandler);
      } else {
        await connect(oldToken, bgHandler);
      }

      // If for any reason you want to attempt re-connect with old token:
      // await connect(oldToken, bgHandler);
      await setNewStatus(ServiceStatus.active);
      return registrationId;
    } on TimeoutException catch (e, s) {
      initCompleter = null;
      await setNewStatus(ServiceStatus.disconnected);
      Error.throwWithStackTrace(
        AuroraPushException(
          code: 'response_timeout',
          message:
              'initialize(applicationId: $applicationId) returned TimeoutException',
        ),
        s,
      );
    } on Object {
      initCompleter = null;
      rethrow;
    }
  }

  Future<void> connect(String token, BackgroundHandler? onMessage) async {
    if (active) return;
    active = true;

    final prefs = await SharedPreferences.getInstance();

    // Load the lastMessageId from SharedPreferences before processing any messages.
    var lastMessageId = prefs.getString('lastMessageId');

    try {
      print("Connecting to WebSocket with token: $token");

      // Close any existing connections before starting the new one
      await subs?.cancel();
      await webChannel?.sink.close();

      webChannel = WebSocketChannel.connect(
        Uri.parse('wss://sub.pushed.dev/v2/open-websocket/$token'),
      );

      // Await WebSocket readiness
      await webChannel?.ready;

      // Ensure that the initial state is set and prevent processing duplicate messages.
      subs = webChannel?.stream.listen(
        (event) async {
          var message = utf8.decode(event);
          if (message != "ONLINE") {
            try {
              var payload = json.decode(message);

              if (payload is Map<String, dynamic>) {
                var messageId = payload["messageId"]?.toString() ?? "";
                var traceId = payload["mfTraceId"]?.toString() ?? "";
                print('Pushed messageId : $messageId');

                // Check if the messageId is different from the last processed messageId
                if (lastMessageId != messageId) {
                  // Store the new messageId in SharedPreferences to prevent future duplicates
                  await prefs.setString('lastMessageId', messageId);

                  // Acknowledge receipt to the server
                  var response = json.encode({
                    "messageId": messageId,
                    if (traceId.isNotEmpty) "mfTraceId": traceId
                  });
                  webChannel?.sink.add(utf8.encode(response));

                  // Parse the message data and call the background handler if needed
                  if (payload["data"] is String) {
                    try {
                      payload["data"] = json.decode(payload["data"]);
                    } catch (_) {
                      payload["data"] = {"body": payload["data"]};
                    }
                  }

                  // Format and process the message
                  final messageMap = {
                    "data": {
                      "title": payload["data"]["title"] ?? "",
                      "body":
                          payload["data"]["body"] ?? "You have a new message.",
                      "messageId": messageId, // Add messageId to the map
                    },
                  };
                  print('Message map: $messageMap');

                  // If we have a background handler, call it
                  if (onMessage != null) {
                    await onMessage(messageMap['data']!);
                  }

                  // Update the lastMessageId after processing the message
                  lastMessageId = messageId;
                } else {
                  print("Duplicate message detected, skipping.");
                }
              }
            } catch (e) {
              print("Error processing pushed message: $e");
            }
          }
        },
        onDone: () async {
          active = false;
          // attempt reconnection after a brief delay
          await Future.delayed(const Duration(seconds: 1));
          connect(token, onMessage);
        },
        onError: (error) {
          active = false;
          // attempt reconnection on error
          Future.delayed(const Duration(seconds: 1))
              .then((_) => connect(token, onMessage));
        },
      );
    } catch (e) {
      active = false;
      // attempt reconnection
      Future.delayed(const Duration(seconds: 1))
          .then((_) => connect(token, onMessage));
    }
  }

}
