import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:bubble/bubble.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'utility/MyMessage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Нереально хайповый мессенджер'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _messages = <MyMessage>[];
  final _messageTextController = TextEditingController();
  final _messageScrollController = ScrollController();
  final interactor = NetworkInteractor();

  static const styleMe = BubbleStyle(
    nip: BubbleNip.rightBottom,
    margin: BubbleEdges.only(top: 10),
    padding: BubbleEdges.all(10),
    borderWidth: 2,
    stick: false,
    alignment: Alignment.topRight,
    color: Color.fromARGB(255, 212, 234, 244),
    radius: Radius.circular(20.0),
  );

  static const styleSomebody = BubbleStyle(
    nip: BubbleNip.leftBottom,
    margin: BubbleEdges.only(top: 10),
    padding: BubbleEdges.all(10),
    borderWidth: 2,
    stick: false,
    alignment: Alignment.topLeft,
    color: Color.fromARGB(255, 235, 244, 212),
    radius: Radius.circular(20.0),
  );

  static const textStyle = TextStyle(fontSize: 20.0);

  int _counter = 0;

  _MyHomePageState() {
    interactor.init();
    _messages.add(MyMessage("Hello Joe", true));
    _messages.add(MyMessage("Hello Mike", false));
    _messages.add(MyMessage("Hello Robert", true));
    _messages.add(MyMessage("Hello Mike", false));
  }

  Widget _buildMessage(MyMessage msg) {
    return Bubble(
      child: Text(msg.text, style: textStyle),
      style: msg.mine ? styleMe : styleSomebody,
    );
  }

  void _sendMessage(String str) {
    print("Sending a message: " + str);
    setState(() {
      _messages.add(MyMessage(str, true));
    });

    _messageScrollController
        .jumpTo(_messageScrollController.position.maxScrollExtent);
  }

  @override
  void dispose() {
    _messageTextController.dispose();
    interactor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 220, 220, 235),
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Column(children: [
        Expanded(
            child: ListView(
          padding: EdgeInsets.all(8),
          controller: _messageScrollController,
          children: _messages.map(_buildMessage).toList(),
        )),
        Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            padding: EdgeInsets.only(left: 10, bottom: 10, top: 10),
            height: 60,
            width: double.infinity,
            color: Colors.white,
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Write message...",
                      hintStyle: TextStyle(color: Colors.black54),
                      border: InputBorder.none,
                    ),
                    controller: _messageTextController,
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                FloatingActionButton(
                  onPressed: () {
                    _sendMessage(_messageTextController.text);
                    _messageTextController.clear();
                  },
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 18,
                  ),
                  backgroundColor: Colors.blue,
                  elevation: 0,
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class NetworkInteractor {
  final devices = <Device>[];
  final connectedDevices = <Device>[];
  final nearbyService = NearbyService();
  StreamSubscription subscription;
  StreamSubscription receivedDataSubscription;

  bool isInit = false;

  void dispose() {
    subscription?.cancel();
    receivedDataSubscription?.cancel();
    nearbyService.stopBrowsingForPeers();
    nearbyService.stopAdvertisingPeer();
  }

  void init() async {
    if (!isInit) {
      await nearbyService.init(
          serviceType: "ad_hoc_msg",
          strategy: Strategy.Wi_Fi_P2P,
          callback: (isRunning) async {
            // await nearbyService.stopAdvertisingPeer();
            // await nearbyService.startAdvertisingPeer();

            await nearbyService.stopBrowsingForPeers();
            await nearbyService.startBrowsingForPeers();
          });
      subscription =
          nearbyService.stateChangedSubscription(callback: (devicesList) {
        devicesList?.forEach((element) {
          print(
              " deviceId: ${element.deviceId} | deviceName: ${element.deviceName} | state: ${element.state}");

          if (Platform.isAndroid) {
            if (element.state == SessionState.connected) {
              nearbyService.stopBrowsingForPeers();
            } else {
              nearbyService.startBrowsingForPeers();
            }
          }
        });

        devices.clear();
        devices.addAll(devicesList);

        connectedDevices.clear();
        connectedDevices.addAll(devicesList
            .where((d) => d.state == SessionState.connected)
            .toList());
      });

      isInit = true;
    }
  }
}
