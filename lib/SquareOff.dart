import 'dart:async';
import 'package:squareoffdriver/SquareOffCommunicationClient.dart';
import 'package:squareoffdriver/SquareOffMessage.dart';
import 'package:squareoffdriver/protocol/commands/FieldUpdate.dart';
import 'package:squareoffdriver/protocol/commands/NewGame.dart';
import 'package:squareoffdriver/protocol/model/PieceUpdate.dart';
import 'package:squareoffdriver/protocol/model/RequestConfig.dart';

class SquareOff {
  
  SquareOffCommunicationClient _client;

  StreamController _inputStreamController;
  Stream<SquareOffMessage> _inputStream;
  List<int> _buffer;
  String _version;

  static List<String> RANKS = ["a", "b", "c", "d", "e", "f", "g", "h"];
  static List<String> ROWS = ["1", "2", "3", "4", "5", "6", "7", "8"];
  static get SQUARES {
    List<String> squares = [];
    for (var row in ROWS) {
      for (var rank in RANKS.reversed.toList()) {
        squares.add(rank + row);
      }
    }
    return squares;
  }

  String get version => _version;

  SquareOff();

  Future<void> init(SquareOffCommunicationClient client, { Duration initialDelay = const Duration(milliseconds: 300) }) async {
    _client = client;

    _client.receiveStream.listen(_handleInputStream);
    _inputStreamController = new StreamController<SquareOffMessage>();
    _inputStream = _inputStreamController.stream.asBroadcastStream();

    await Future.delayed(initialDelay);
    
  }

  void _handleInputStream(List<int> chunk) {
    // print("R > " + chunk.map((n) => String.fromCharCode(n & 127)).toString());
    if (_buffer == null) {
      _buffer = chunk.toList();
    } else {
      _buffer.addAll(chunk);
    }

    if (_buffer.length > 1000) {
      _buffer.removeRange(0, _buffer.length - 1000);
    }

    do {
      try {
        SquareOffMessage message = SquareOffMessage.parse(_buffer);
        _inputStreamController.add(message);
        _buffer.removeRange(0, message.getLength());
        // print("[IMessage] valid (" + message.getCode() + ")");
      } on SquareOffInvalidMessageException catch (e) {
        skipBadBytes(e.skipBytes, _buffer);
        // print("[IMessage] invalid");
      } on SquareOffUncompleteMessage {
        // wait longer
        break;
      } catch (err) {
        // print("Unknown parse-error: " + err.toString());
        break;
      }
    } while (_buffer.length > 0);
  }

  Stream<SquareOffMessage> getInputStream() {
    return _inputStream;
  }

  void skipBadBytes(int start, List<int> buffer) {
    buffer.removeRange(0, start);
  }

  Stream<FieldUpdate> getFieldUpdateStream() {
    return getInputStream()
        .where(
            (SquareOffMessage msg) => msg.getCode() == FieldUpdateAnswer().code)
        .map((SquareOffMessage msg) => FieldUpdateAnswer().process(msg.getMessage()));
  }

  Future<bool> newGame({ RequestConfig config = const RequestConfig(0, const Duration(minutes: 5)) }) {
    return NewGame().request(_client, _inputStream, config);
  }

}
