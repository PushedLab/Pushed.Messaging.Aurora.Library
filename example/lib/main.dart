import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pushed_demo_aurora/org_freedesktop_notifications.dart';
import 'package:pushed_messaging/pushed_messaging.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'main_screen.dart';

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

late OrgFreedesktopNotifications object;
int? activePush;

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "PushedMessaging":
        await PushedMessaging().init(
          backgroundMessage,
          applicationId: 'appfluttest_cumsutpp82rl9tjniai0',
        );
        await Future.delayed(const Duration(seconds: 900));
        return Future.value(true);
      default:
        return Future.value(false);
    }
  });
}

@pragma('vm:entry-point')
Future<void> backgroundMessage(Map<dynamic, dynamic> message) async {
  try {
    // Initialize SharedPreferences to save notification data
    final prefs = await SharedPreferences.getInstance();

    print("Aurora Background Message: $message");

    // Extract title and body from the message payload
    String title = message["title"] ?? "Уведомление";
    String body = message["message"] ?? message["body"] ?? "Новое уведомление";

    if (title.isNotEmpty) await prefs.setString("last_title", title);
    if (body.isNotEmpty) await prefs.setString("last_body", body);

    // final FlutterLocalNotificationsPlugin notifications =
    //     FlutterLocalNotificationsPlugin();

    // // Display the notification using Aurora notification system
    // await notifications.show(
    //     0, // Notification ID (can be any unique value)
    //     title != '' ? title : "Уведомление", // Notification title
    //     body, // Notification body
    //     null // Optional payload data
    //     );

    // Initialize DBus client
    final client = DBusClient.session();
    object = OrgFreedesktopNotifications(
        client,
        'org.freedesktop.Notifications',
        DBusObjectPath('/org/freedesktop/Notifications'));

    // Close the last active notification if any
    if (activePush != null) {
      await object.callCloseNotification(activePush!);
    }

    // Display notification using OrgFreedesktopNotifications
    activePush = await object.callNotify(
      "MultiPushed",
      0,
      ' ', // App Icon (empty)
      title != '' ? title : "Уведомление",
      body,
      ["deny", 'Закрыть'], 
      {
        "x-nemo-feedback": const DBusString("sms_exists"),
        "urgency": const DBusByte(2),
        "x-aurora-essential": const DBusBoolean(true),
        "x-aurora-silent-actions": DBusArray.string(["deny"])
      },
      -1,
    );

    print("Notification sent: $title - $body");
  } catch (e) {
    print("Error in notification: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PushedMessaging().init(
    backgroundMessage,
    applicationId: 'appfluttest_cumsutpp82rl9tjniai0',
  );

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  await Workmanager().registerPeriodicTask(
    '1',
    'PushedMessaging',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    final ThemeData theme = ThemeData(
      // Define the default brightness and colors.
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color.fromRGBO(15, 15, 15, 1),
      // 240,244,247,1
      primaryColor: const Color.fromRGBO(249, 250, 254, 1),
      //accentColor: Colors.cyan[600],
      // Define the default font family.
      fontFamily: 'Roboto',
      // Define the default TextTheme. Use this to specify the default
      // text styling for headlines, titles, bodies of text, and more.
      textTheme: TextTheme(
        displayLarge: GoogleFonts.roboto(
            fontSize: 22.0,
            color: const Color.fromRGBO(249, 250, 254, 1),
            fontWeight: FontWeight.w700),
        bodyMedium: const TextStyle(
          fontSize: 18.0,
          color: Color.fromRGBO(249, 250, 254, 1),
          fontFamily: 'Roboto',
        ),
      ),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', ''), // English
        const Locale('ru', ''), // Russian (or any other supported locales)
      ],
      localeResolutionCallback:
          (Locale? loc, Iterable<Locale> supportedLocales) {
        // Fallback to the first supported locale if no match is found
        for (Locale supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == loc?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      theme: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(secondary: Colors.cyan[600]),
      ),
      home: MainScreen(),
    );
  }
}
