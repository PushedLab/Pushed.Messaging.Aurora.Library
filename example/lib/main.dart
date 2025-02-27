import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pushed_messaging/pushed_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore_for_file: use_build_context_synchronously

@pragma('vm:entry-point')
Future<void> backgroundMessage(Map<dynamic, dynamic> message) async {
  // Ensure widgets and bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // await loggerAdd('Background message works');

  try {
    // Initialize SharedPreferences to save notification data
    final prefs = await SharedPreferences.getInstance();

    print("Aurora Background Message: $message");

    // Extract title and body from the message payload
    String title = (message["title"]) ?? "Уведомление";
    String body = (message["data"]?["body"]) ?? "";

    if (title.isNotEmpty) await prefs.setString("last_title", title);
    if (body.isNotEmpty) await prefs.setString("last_body", body);

    // Initialize the Aurora notification plugin
    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    // Display the notification using Aurora notification system
    await notifications.show(
        0, // Notification ID (can be any unique value)
        title, // Notification title
        body, // Notification body
        null // Optional payload data
        );

    // await addLog("Notification sent: $title - $body");
  } catch (e) {
    // await addLog("Error in notification: $e");
  }
}

void main() async {
  await PushedMessaging().init(backgroundMessage,
      applicationId: 'appfluttest_cumsutpp82rl9tjniai0');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initPlatformState(context);
  }

  final pushes = <AuroraPushMessage>[];
  final _auroraPushPlugin = PushedMessaging();
  StreamSubscription? messagesSubscription;
  String registrationId = '';
  int notificationCounterId = 0;
  bool wasInitialized = false;

  Future<void> initPlatformState(BuildContext context) async {
    setState(() {
      wasInitialized = false;
    });
    try {
      registrationId = await _auroraPushPlugin.init(
        // TODO: Add your applicationId from Aurora Center.
        backgroundMessage,
        applicationId: 'appfluttest_cumsutpp82rl9tjniai0',
      );
      if (registrationId.isNotEmpty) setState(() {});
      messagesSubscription ??=
          _auroraPushPlugin.onMessage.listen((event) async {
        if (!mounted) return;
        // setState(() {
        //   pushes.add(event);
        // });
        final notificationPlugin = FlutterLocalNotificationsPlugin();
        // await notificationPlugin.show(
        //   notificationCounterId++,
        //   "#$notificationCounterId ${event.title}",
        //   "${event.message}",
        //   null,
        // );
      });
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
    if (!mounted || registrationId.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Your registration id: $registrationId'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: registrationId));
          },
        ),
      ),
    );
    setState(() {
      wasInitialized = true;
    });
  }

  @override
  void dispose() {
    messagesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            if (!wasInitialized)
              const Text(
                'Tap FAB to initialize PushedMessaging.',
              ),
            if (registrationId.isNotEmpty)
              ListTile(
                title: Text(registrationId),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: registrationId),
                    );
                  },
                ),
              ),
            Expanded(
              child: ListView.builder(
                // Чтобы самые свежие пуши отображались в начале
                itemCount: pushes.length,
                itemBuilder: (context, index) {
                  final push = pushes.reversed.toList()[index];
                  return ListTile(
                    title: Text('Title: ${push.title}'),
                    subtitle: Text('Message: ${push.message}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListTileScreen(
                            title: push.title ?? '',
                            message: push.message ?? '',
                            data: push.data ?? '',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              tooltip: 'Long tap to re-initialize',
              onPressed: () async {
                await initPlatformState(context);
              },
              child: const Icon(Icons.replay),
            );
          },
        ),
      ),
    );
  }
}

class ListTileScreen extends StatelessWidget {
  const ListTileScreen({
    super.key,
    this.title = '',
    this.message = '',
    this.data = '',
  });

  final String title;
  final String message;
  final String data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push info'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.isNotEmpty)
            ListTile(
              title: Text('Title: $title'),
              onTap: () async {
                await Clipboard.setData(
                  ClipboardData(text: title),
                );
              },
            ),
          if (message.isNotEmpty)
            ListTile(
              title: Text('Message: $message'),
              onTap: () async {
                await Clipboard.setData(
                  ClipboardData(text: message),
                );
              },
            ),
          if (data.isNotEmpty)
            ListTile(
              title: Text('Data: $data'),
              onTap: () async {
                await Clipboard.setData(
                  ClipboardData(text: data),
                );
              },
            ),
        ],
      ),
    );
  }
}
