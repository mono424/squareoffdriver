import 'dart:async';
import 'dart:typed_data';

import 'package:example/ble_scanner.dart';
import 'package:example/device_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:squareoffdriver/SquareOff.dart';
import 'package:squareoffdriver/SquareOffCommunicationClient.dart';
import 'package:squareoffdriver/protocol/model/GameEvent.dart';
import 'package:squareoffdriver/protocol/model/PieceUpdate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final _ble = FlutterReactiveBle();
  final _scanner = BleScanner(ble: _ble, logMessage: print);
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: _scanner),
        StreamProvider<BleScannerState>(
          create: (_) => _scanner.state,
          initialData: const BleScannerState(
            discoveredDevices: [],
            scanIsInProgress: false,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter example',
        home: MyApp(),
      ),
    ),
  );
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

class _MyHomePageState extends State<MyHomePage> {
  final flutterReactiveBle = FlutterReactiveBle();

  final bleServiceId = Uuid.parse("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
  final bleReadCharacteristic = Uuid.parse("6e400003-b5a3-f393-e0a9-e50e24dcca9e");
  final bleWriteCharacteristic = Uuid.parse("6e400002-b5a3-f393-e0a9-e50e24dcca9e");

  SquareOff connectedBoard;
  StreamSubscription<ConnectionStateUpdate> boardBtStream;
  StreamSubscription<List<int>> boardBtInputStream;
  bool loading = false;
  bool ackEnabled = true;

  void connectBle() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();

    String deviceId = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => DeviceListScreen()));

    setState(() {
      loading = true;
    });

    boardBtStream = flutterReactiveBle.connectToDevice(
      id: deviceId,
      servicesWithCharacteristicsToDiscover: { bleServiceId: [bleReadCharacteristic, bleWriteCharacteristic] },
      // connectionTimeout: const Duration(seconds: 5),
    ).listen((e) async {
      print(e);
      if (e.connectionState == DeviceConnectionState.connected) {
        List<DiscoveredService> services = await flutterReactiveBle.discoverServices(e.deviceId);

        QualifiedCharacteristic read;
        QualifiedCharacteristic write;
        for (var service in services) {
          for (var characteristicId in service.characteristicIds) {
            if (characteristicId == bleReadCharacteristic) {
              read = QualifiedCharacteristic(
                serviceId: service.serviceId,
                characteristicId: bleReadCharacteristic,
                deviceId: e.deviceId
              );
            }

            if (characteristicId == bleWriteCharacteristic) {
              write = QualifiedCharacteristic(
                serviceId: service.serviceId,
                characteristicId: bleWriteCharacteristic,
                deviceId: e.deviceId
              );
            }
          }
        }

        SquareOffCommunicationClient squareOffCommunicationClient = SquareOffCommunicationClient(
          (v) => flutterReactiveBle.writeCharacteristicWithResponse(write, value: v),
        );
        boardBtInputStream = flutterReactiveBle
            .subscribeToCharacteristic(read)
            .listen((list) {
              squareOffCommunicationClient.handleReceive(Uint8List.fromList(list));
            });
          
        // connect to board and initialize
        SquareOff nBoard = SquareOff();
        await nBoard.init(squareOffCommunicationClient);
        print("squareOffBoard connected");

        // set connected board
        setState(() {
          connectedBoard = nBoard;
          loading = false;
        });
      }
    });
    boardBtStream.onDone(() {
      setState(() {
        loading = false;
      });
    });
  }

  Map<String, String> lastData;

  // LEDPattern ledpattern = LEDPattern();

  void toggleLed(String square) {
    // ledpattern.setSquare(square, !ledpattern.getSquare(square));
    // connectedBoard.setLEDs(ledpattern);
    // setState(() {});
  }

  void disconnectBle() {
    boardBtInputStream.cancel();
    boardBtStream.cancel();
    setState(() {
      boardBtInputStream = null;
      boardBtStream = null;
      connectedBoard = null;
    });
  }

  void testLeds() async {
    List<String> squares = [];
    for (var square in SquareOff.squares) {
      squares.add(square);
      while (squares.length > 4) squares.removeAt(0);
      await connectedBoard.setLeds(squares);
    }
    await connectedBoard.setLeds([]);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text("squareoff example"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: TextButton(
            child: Text(connectedBoard == null ? "Try to connect to board (BLE)" : (boardBtStream != null ? "Disconnect" : "")),
            onPressed: !loading && connectedBoard == null ? connectBle : (boardBtStream != null && !loading ? disconnectBle : null),
          )),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                child: Text("New Game"),
                onPressed: !loading && connectedBoard != null ? () => connectedBoard.newGame() : null
              ),
              TextButton(
                child: Text("Test LEDS"),
                onPressed: !loading && connectedBoard != null ? testLeds : null
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                child: Text("White won"),
                onPressed: !loading && connectedBoard != null ? () => connectedBoard.triggerGameEvent(GameEvent.whiteWins) : null
              ),
              TextButton(
                child: Text("Black won"),
                onPressed: !loading && connectedBoard != null ? () => connectedBoard.triggerGameEvent(GameEvent.blackWins) : null
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                child: Text("King in Check"),
                onPressed: !loading && connectedBoard != null ? () => connectedBoard.triggerGameEvent(GameEvent.kingInCheck) : null
              ),
              TextButton(
                child: Text("Draw"),
                onPressed: !loading && connectedBoard != null ? () => connectedBoard.triggerGameEvent(GameEvent.draw) : null
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                child: Text("Get Board"),
                onPressed: !loading && connectedBoard != null ? () => connectedBoard.getBoard() : null
              ),
            ],
          ),
          Center( child: StreamBuilder(
            stream: connectedBoard?.getFieldUpdateStream(),
            builder: (context, AsyncSnapshot<FieldUpdate> snapshot) {
              if (!snapshot.hasData && lastData == null) return Text("- no data -");

              Map<String, String> fieldUpdate = snapshot.data ?? lastData;
              lastData = fieldUpdate;
              List<Widget> rows = [];
              
              for (var i = 0; i < 8; i++) {
                List<Widget> cells = [];
                for (var j = 0; j < 8; j++) {
                    MapEntry<String, String> entry = fieldUpdate.entries.toList()[i * 8 + j];
                    cells.add(
                      TextButton(
                        onPressed: () => toggleLed(entry.key),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(width / 8 - 4, width / 8 - 4),
                          alignment: Alignment.centerLeft
                        ),
                        child: Container(
                          padding: EdgeInsets.only(bottom: 2),
                          width: width / 8 - 4,
                          height: width / 8 - 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: /*ledpattern.getSquare(entry.key) ? Colors.blueAccent :*/ Colors.black54,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(entry.key, style: TextStyle(color: Colors.white)),
                                Text(entry.value ?? ".", style: TextStyle(color: Colors.white, fontSize: 8)),
                              ],
                            )
                          ),
                        ),
                      )
                    );
                }
                rows.add(Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: cells,
                ));
              }

              return Column(
                children: rows,
              );
            }
          )),
        ],
      ),
    );
  }
}
