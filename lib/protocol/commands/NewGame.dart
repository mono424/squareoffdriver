import 'package:squareoffdriver/protocol/Answer.dart';
import 'package:squareoffdriver/protocol/Command.dart';

class NewGame extends Command<bool> {
  final String code = "14";
  final String body = "1";
  final Answer<bool> answer = NewGameReady();
}

class NewGameReady extends Answer<bool> {
  final String code = "14";

  @override
  bool process(String msg) {
    return msg.split("#")[1] == "GO*";
  }
}