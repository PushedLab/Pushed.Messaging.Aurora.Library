import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pushed_messaging/pushed_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  String? _service_status = 'Service active';
  String? _client_token;
  String? _message_header;
  String? _message_body;
  // StreamSubscription? subs;
  late SharedPreferences prefs;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    print("State: $state");
    if (state == AppLifecycleState.resumed) {
      if (!mounted) return;
      // If you need to restore last messages or similar, do so here.
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initPlatformState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> initPlatformState() async {
    prefs = await SharedPreferences.getInstance();

    // Retrieve the token or generate a new one
    String token = PushedMessaging.token ?? "";

    // Save and update UI variables
    var title = prefs.getString("last_title") ?? "";
    var body = prefs.getString("last_body") ?? "";
    // await saveToDownloads(body);
    if (!mounted) return;

    PushedMessaging().onMessage.listen((message) async {
      print(message);
      print("Front: $message");
      String title = (message["title"]) ?? "";
      String body = (message["message"]) ?? "";
      if (title != "") await prefs.setString("last_title", title);
      if (body != "") await prefs.setString("last_body", body);

      if (title != null || body != null) {
        setState(() {
          _message_header = title;
          _message_body = body;
        });
      }
    });

    PushedMessaging().onStatus.listen((status) async {
      print('Status: $status');
      setState(() {
        if (status == ServiceStatus.active) _service_status = 'Service active';
        if (status == ServiceStatus.disconnected) {
          _service_status = 'Disconnected';
        }
        if (status == ServiceStatus.notActive) _service_status = 'Not active';
      });
    });

    setState(() {
      _client_token = token.isNotEmpty ? token : null; // Display the token
      _message_header = title.isNotEmpty ? title : null;
      _message_body = body.isNotEmpty ? body : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EmptyAppBar(),
      body: Builder(builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(top: 14.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                        child: Container(
                            child: Image.asset(
                      'assets/images/pushed_logo.png',
                      width: 100,
                      height: 50,
                    ))),
                  ],
                ),
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text('Service status',
                    style: Theme.of(context).textTheme.displayLarge)),
            Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(_service_status ?? "Empty",
                    style: Theme.of(context).textTheme.bodyMedium)),
            Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text('Client token',
                    style: Theme.of(context).textTheme.displayLarge)),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Builder(
                builder: (context) => SelectableText(
                  _client_token ?? "",
                  style: Theme.of(context).textTheme.bodyMedium,
                  enableInteractiveSelection: true, // Allows text selection
                ),
              ),
            ),
            if (_message_body != null || _message_header != null)
              Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text('Last message',
                      style: Theme.of(context).textTheme.displayLarge)),
            if (_message_body != null || _message_header != null)
              Padding(
                padding:
                    const EdgeInsets.only(left: 16.0, right: 16.0, top: 10),
                child: Card(
                    color: Color.fromRGBO(40, 41, 45, 1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)),
                    child: Container(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(_message_body ?? "Empty",
                                  textAlign: TextAlign.center,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ))),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 10),
              child: Card(
                color: const Color.fromRGBO(40, 41, 45, 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0)),
                child: InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.white,
                  enableFeedback: true,
                  onTap: () {
                    saveToDownloads(_client_token ?? '');
                    // Показать SnackBar с подтверждением действия
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Token copied to downloads folder'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const SizedBox(
                    height: 70,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.copy,
                            color: Color.fromRGBO(184, 121, 129, 1),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 12.0),
                            child: Text(
                              'Copy token',
                              style: const TextStyle(
                                fontFamily: "SFPro",
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          ],
        );
      }),
    );
  }
}

class EmptyAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  Size get preferredSize => Size(0.0, 0.0);
}


Future<void> saveToDownloads(String event) async {
  var tDir = await getDownloadsDirectory();
  await File(p.join(tDir!.path, "pushed.log")).writeAsString(
      "${DateTime.now().toString()}: $event\n",
      mode: FileMode.append);
}
