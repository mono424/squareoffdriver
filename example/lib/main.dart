import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:squareoffdriver/SquareOff.dart';
import 'package:squareoffdriver/SquareOffCommunicationClient.dart';
import 'package:squareoffdriver/protocol/model/PieceUpdate.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class LogEntry {
  final bool incomming;
  final String description;

  LogEntry(this.incomming, this.description);
}

class _MyHomePageState extends State<MyHomePage> {
  SquareOff connectedBoard;
  List<LogEntry> logs = [];

  Uuid _serviceId = Uuid.parse("49535343-fe7d-4ae5-8fa9-9fafd205e455");
  Uuid _characteristicReadId =
      Uuid.parse("49535343-1e4d-4bd9-ba61-23c647249616");
  Uuid _characteristicWriteId =
      Uuid.parse("49535343-8841-43f4-a8d4-ecbe34729bb3");
  Duration scanDuration = Duration(seconds: 10);
  List<DiscoveredDevice> devices = [];
  bool scanning = false;

  final flutterReactiveBle = FlutterReactiveBle();
  StreamSubscription<ConnectionStateUpdate> connection;

  Future<void> reqPermission() async {
    await Permission.locationWhenInUse.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
  }

  Future<void> listDevices() async {
    setState(() {
      scanning = true;
      devices = [];
    });

    await reqPermission();

    // Listen to scan results
    final sub = flutterReactiveBle.scanForDevices(
        withServices: [], scanMode: ScanMode.lowLatency).listen((device) async {
      if (!device.name.contains("Squareoff") ||
          devices.indexWhere((e) => e.id == device.id) > -1) return;

      setState(() {
        devices.add(device);
      });
    }, onError: (e) {
      print(e);
    });

    // Stop scanning
    Future.delayed(scanDuration, () {
      sub.cancel();
      setState(() {
        scanning = false;
      });
    });
  }

  void connect(DiscoveredDevice device) async {
    connection = flutterReactiveBle
    .connectToDevice(
      id: device.id,
      connectionTimeout: const Duration(seconds: 2),
    ).listen((connectionState) async {
      print(connectionState.connectionState);
      if (connectionState.connectionState == DeviceConnectionState.disconnected) {
        disconnect();
        return;
      }

      if (connectionState.connectionState != DeviceConnectionState.connected) {
        return;
      }

      final read = QualifiedCharacteristic(
          serviceId: _serviceId,
          characteristicId: _characteristicReadId,
          deviceId: device.id);
      final write = QualifiedCharacteristic(
          serviceId: _serviceId,
          characteristicId: _characteristicWriteId,
          deviceId: device.id);

      SquareOffCommunicationClient client =
          SquareOffCommunicationClient((v) => flutterReactiveBle.writeCharacteristicWithResponse(write, value: v));
      flutterReactiveBle
          .subscribeToCharacteristic(read)
          .listen(client.handleReceive);

      SquareOff nBoard = new SquareOff();
      await nBoard.init(client, initialDelay: Duration(seconds: 1));

      nBoard.getFieldUpdateStream().listen(onFieldUpdate);

      setState(() {
        connectedBoard = nBoard;
      });

    }, onError: (Object e) {
      print(e);
    });
  }

  void onFieldUpdate(FieldUpdate fieldUpdate) {
    logs.add(LogEntry(true, "FieldUpdate: " + fieldUpdate.field + " " + (fieldUpdate.type == FieldUpdateType.pickUp ? "PickUp" : "SetDown")));
    setState(() {});
  }

  void disconnect() async {
    connection.cancel();
    setState(() {
      connectedBoard = null;
    });
  }

  void newGame() async {
    logs.add(LogEntry(false, "NewGame"));
    setState(() {});
    try {
      await connectedBoard.newGame();
      logs.add(LogEntry(false, "NewGame Success"));
    } catch (e) {
      logs.add(LogEntry(false, "NewGame Fail"));
    }
    setState(() {});
  }

  Widget connectedBoardButtons() {
    return Column(
      children: [
        SizedBox(height: 25),
        TextButton(
            onPressed: newGame,
            child: Text("New Game")),
        TextButton(onPressed: disconnect, child: Text("Disconnect")),
      ],
    );
  }

  Widget logsView() {
    return SingleChildScrollView(
      child: Column(
        children: logs.map((entry) => Row(
          children: [
            Icon(entry.incomming ? Icons.arrow_back : Icons.arrow_forward, color: entry.incomming ? Colors.green : Colors.red),
            SizedBox(width: 12),
            Text(entry.description)
          ],
        )).toList()
      )
    );
  }

  Widget deivceList() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 25),
        Center(
            child: scanning
                ? CircularProgressIndicator()
                : TextButton(
                    child: Text("List Devices"),
                    onPressed: listDevices,
                  )),
        Flexible(
            child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) => ListTile(
                      title: Text(devices[index].name),
                      subtitle: Text(devices[index].id.toString()),
                      onTap: () => connect(devices[index]),
                    ))),
        SizedBox(height: 24)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = connectedBoard == null
        ? deivceList()
        : TabBarView(
            children: [
              connectedBoardButtons(),
              logsView(),
            ],
          );
    Widget appBar = connectedBoard == null
        ? AppBar(
            title: Text("squareoffdriver example"),
          )
        : AppBar(
            title: Text("squareoffdriver example"),
            bottom: TabBar(
              tabs: [
                Tab(text: "Actions"),
                Tab(text: "Logs"),
              ],
            ),
          );

    return DefaultTabController(
        length: 2, child: Scaffold(appBar: appBar, body: content));
  }
}
