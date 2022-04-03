class SquareOffMessage {
  String _code;
  int _length;
  String _message;

  SquareOffMessage.parse(List<int> buffer, { bool checkParity = true }) {
    List<String> asciiChars = buffer.map((n) => String.fromCharCode(n)).toList();

    bool validEnding = false;
    for (int n in buffer) {
        String char = String.fromCharCode(n); // Maybe: (n & 127)
        asciiChars.add(char);
        if (char == "*") {
          validEnding = true;
          break;
        }
    }

    if (!validEnding) throw SquareOffUncompleteMessage();
    if (asciiChars.indexOf("#") < 1) {
      // no code in message
      throw SquareOffInvalidMessageException(asciiChars.length);
    }

    String message = asciiChars.join("");

    _code = message.split("#")[0];
    _length = asciiChars.length;
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
