import 'dart:convert';

class SquareOffMessage {
  String _code;
  int _length;
  String _message;

  SquareOffMessage.parse(List<int> buffer, { bool checkParity = true }) {
    List<String> asciiChars = buffer.map((n) => String.fromCharCode(n)).toList();

    int end = -1;
    for (var i = 0; i < asciiChars.length; i++) {
      if (asciiChars[i] == "*") {
        end = i;
        break;
      }
    }

    if (end == -1) throw SquareOffUncompleteMessage();
    if (asciiChars.indexOf("#") < 1) {
      // no code in message
      throw SquareOffInvalidMessageException(asciiChars.length);
    }

    String message = asciiChars.sublist(0, end + 1).join("");

    _code = message.split("#")[0];
    _length = message.length;
    _message = message;
  }
  
  String getCode() {
    return _code;
  }

  int getLength() {
    return _length;
  }

  String getMessage() {
    return _message;
  }
}

class SquareOffUncompleteMessage implements Exception {}
class SquareOffInvalidMessageException implements Exception {
  final int skipBytes;

  SquareOffInvalidMessageException(this.skipBytes);
}
