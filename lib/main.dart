import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:bubble/bubble.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:tuple/tuple.dart';
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
  static const handleStyle = TextStyle(fontSize: 13.0, color: Colors.blueGrey);

  int _counter = 0;
  bool _requiresScrolling = false;
  bool _setHandle = false;

  _MyHomePageState() {
    interactor.init();
    interactor.connectedUsersCount.addListener(() {
      setState(() {});
    });

    interactor.setMessageCallback(callback: (MyMessage msg) {
      setState(() {
        _messages.add(msg);
        _requiresScrolling = true;
      });
    });

    // _messages.add(MyMessage("Hello Joe", true));
    // _messages.add(MyMessage("Hello Mike", false));
    // _messages.add(MyMessage("Hello Robert", true));
    // _messages.add(MyMessage("Hello Mike", false));
  }

  Widget _buildMessage(MyMessage msg) {
    return Bubble(
      child: Column(
        children: [
          Text(
            msg.handle,
            style: handleStyle,
            textAlign: msg.mine ? TextAlign.right : TextAlign.left,
          ),
          Text(
            msg.text,
            style: textStyle,
            textAlign: msg.mine ? TextAlign.right : TextAlign.left,
          ),
        ],
      ),
      style: msg.mine ? styleMe : styleSomebody,
    );
  }

  void _sendMessage(String str) {
    if (str.isEmpty) return;

    if (!_setHandle) {
      print("Setting handle ${str}");
      _setHandle = true;
      interactor.setHandle(str);
      return;
    }

    print("Sending a message: " + str);
    MyMessage msg = MyMessage(str, "Я", true);
    setState(() {
      _messages.add(msg);
      _requiresScrolling = true;
    });

    interactor.sendMessage(msg);
  }

  void _scrollToTheEnd() {
    _messageScrollController.animateTo(
      _messageScrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 200),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _messageTextController.dispose();
    interactor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_requiresScrolling) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _scrollToTheEnd();
      });

      _requiresScrolling = false;
    }
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 220, 220, 235),
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Column(children: [
        Text(
          "Disc: ${interactor.discoveredUsersCount.value} | Connecting: ${interactor.connectingUsersCount.value} | Connected: ${interactor.connectedUsersCount.value}",
          style: textStyle,
        ),
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
  final randomNumberGenerator = Random(DateTime.now().millisecondsSinceEpoch);

  // Set for storing message IDs that were already used. TODO flush old ones somehow.
  final usedRandomIds = Set<int>();
  // Set for storing message IDs that were already received. TODO flush old ones somehow.
  final receivedHandlesIds = Set<Tuple2<String, int>>();

  String myHandle;

  StreamSubscription subscription;
  StreamSubscription receivedDataSubscription;
  Function(MyMessage) messageCallback;

  bool isInit = false;

  final discoveredUsersCount = ValueNotifier<int>(0);
  final connectingUsersCount = ValueNotifier<int>(0);
  final connectedUsersCount = ValueNotifier<int>(0);

  void setMessageCallback({Function(MyMessage) callback}) {
    messageCallback = callback;
  }

  void setHandle(String newHandle) {
    myHandle = newHandle;
  }

  // Function for getting a randomId for a new message
  int getRandomId() {
    int n = 0;

    do {
      n = randomNumberGenerator.nextInt(1 << 32); // Generate id
    } while (usedRandomIds.contains(n));

    return n;
  }

  // Function for checking whether the message has already been received
  bool alreadyProcessed(NetworkMessage msg) {
    var pair = Tuple2(msg.handle, msg.randomId);

    return receivedHandlesIds
        .contains(pair); // Check that a message was not previously received
  }

  void sendMessage(MyMessage msg) {
    print("Sending message to ${connectedDevices.length} devices");
    final nm = NetworkMessage.fromMyMessage(msg, getRandomId(), myHandle);

    sendNetworkMessage(nm);
  }

  void sendNetworkMessage(NetworkMessage msg) {
    connectedDevices.forEach((Device d) {
      print("Sending message ${msg.text} to ${d.deviceId}");
      nearbyService.sendMessage(d.deviceId, jsonEncode(msg));
    });
  }

  void dispose() {
    subscription?.cancel();
    receivedDataSubscription?.cancel();
    nearbyService.stopBrowsingForPeers();
    nearbyService.stopAdvertisingPeer();
  }

  void init() async {
    if (!isInit) {
      messageCallback = (MyMessage) {}; // callback stub

      await nearbyService.init(
          serviceType: "ad_hoc_msg",
          strategy: Strategy.P2P_CLUSTER,
          callback: (isRunning) async {
            await nearbyService.stopAdvertisingPeer();
            nearbyService.startAdvertisingPeer();

            await nearbyService.stopBrowsingForPeers();
            nearbyService.startBrowsingForPeers();
          });
      subscription =
          nearbyService.stateChangedSubscription(callback: (devicesList) {
        devicesList?.forEach((element) {
          print(
              " deviceId: ${element.deviceId} | deviceName: ${element.deviceName} | state: ${element.state}");

          if (element.state == SessionState.notConnected)
            nearbyService.invitePeer(
                deviceID: element.deviceId, deviceName: element.deviceName);

          // if (Platform.isAndroid) {
          //   if (element.state == SessionState.connected) {
          //     nearbyService.stopBrowsingForPeers();
          //   } else {
          //     nearbyService.startBrowsingForPeers();
          //   }
          // }
        });

        devices.clear();
        devices.addAll(devicesList);

        connectedDevices.clear();
        connectedDevices.addAll(devicesList
            .where((d) => d.state == SessionState.connected)
            .toList());

        discoveredUsersCount.value = devices.length;
        connectingUsersCount.value = devices
            .where((d) => d.state == SessionState.connecting)
            .toList()
            .length;
        connectedUsersCount.value = connectedDevices.length;

        connectedUsersCount.notifyListeners();
        discoveredUsersCount.notifyListeners();
        connectingUsersCount.notifyListeners();
      });

      receivedDataSubscription =
          nearbyService.dataReceivedSubscription(callback: (data) {
        NetworkMessage nm = NetworkMessage.fromJson(
            jsonDecode(data['message'])); // Parse the message
        print("Received message: ${jsonEncode(data)}"); // Message reception

        // Check that message was not processed and it is not a message of mine
        if (!alreadyProcessed(nm) && nm.handle != myHandle) {
          receivedHandlesIds
              .add(Tuple2(nm.handle, nm.randomId)); // Mark received

          sendNetworkMessage(nm); // Resend this shit
          messageCallback(MyMessage.fromNetworkMessage(nm));
        }
      });

      isInit = true;
    }
  }
}
