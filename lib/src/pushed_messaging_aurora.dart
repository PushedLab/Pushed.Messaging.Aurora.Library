import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pushed_messaging/src/pushed_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:path/path.dart' as p;

import 'package:pushed_messaging/src/aurora_push_exception.dart';
import 'package:pushed_messaging/src/aurora_push_message.dart';
import 'pushed_messaging_platform_interface.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<void> saveToDownloads(String event) async {
    try {
      var tDir = await getDownloadsDirectory();
      if (tDir == null) {
        print("Downloads directory is null.");
        return;
      }
      File logFile = File(p.join(tDir.path, "pushed.log"));
      await logFile.writeAsString(
        "${DateTime.now().toIso8601String()}: $event\n",
        mode: FileMode.append,
      );
    } catch (e, stackTrace) {
      print("Error saving log: $e");
      print(stackTrace);
    }
  }

  ///Запуск слушателей ивентов push daemon
  static void setAuroraMethodCallHandlers() {
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
          // initCompleter?.completeError(
          //   AuroraPushException(
          //     code: 'registration_error',

          //     message: message,
          //   ),
          // );
          // initCompleter?.complete('');
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

    onBackgroundMessage = bgHandler;

    try {
      await channel.invokeMethod('Messaging#init', {
        'applicationId': applicationId,
      });

      initCompleter = Completer();


      /// **Timeout Handling**
      final registrationId = await initCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          initCompleter?.completeError(AuroraPushException(
            code: 'response_timeout',
            message:
                'initialize(applicationId: $applicationId) returned TimeoutException',
          ));
          return ''; // Return empty string as fallback instead of crashing
        },
      );

      if (registrationId.isEmpty) {
        throw AuroraPushException(
          code: 'registration_failed',
          message: 'Registration ID is empty after timeout.',
        );
      }


      initCompleter = null;
      PushedMessagingPlatform.auroraRegistrationId = registrationId;

      final prefs = await SharedPreferences.getInstance();
      final oldToken = prefs.getString('token') ?? "";

      final newToken = await getNewToken(
        oldToken,
        auroraRegistrationId: registrationId,
      );

      await prefs.setString('token', newToken);
      PushedMessagingPlatform.pushToken = newToken;
      print("Got new push token: $newToken");

      await multipushedConnect(newToken, bgHandler);

      await setNewStatus(ServiceStatus.active);
      return registrationId;
    } on TimeoutException catch (e, s) {

      initCompleter = null;
      await setNewStatus(ServiceStatus.disconnected);

      return ''; // Return empty string instead of crashing
    } on Object catch (e, s) {

      initCompleter = null;
      rethrow;
    }
  }

  Future<void> multipushedConnect(
      String token, BackgroundHandler? onMessage) async {
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
        Uri.parse('wss://sub.pushed.ru/v2/open-websocket/$token'),
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
          multipushedConnect(token, onMessage);
        },
        onError: (error) {
          active = false;
          // attempt reconnection on error
          Future.delayed(const Duration(seconds: 1))
              .then((_) => multipushedConnect(token, onMessage));
        },
      );
    } catch (e) {
      active = false;
      // attempt reconnection
      Future.delayed(const Duration(seconds: 1))
          .then((_) => multipushedConnect(token, onMessage));
    }
  }
}
