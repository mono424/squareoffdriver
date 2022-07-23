import 'package:squareoffdriver/protocol/Command.dart';

class SetLeds extends Command<void> {
  final String code = "25";
  String body = "";

  SetLeds(List<String> squares) {
    body = squares.join("").toLowerCase();
  }
}