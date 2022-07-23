import 'package:squareoffdriver/protocol/Command.dart';
import 'package:squareoffdriver/protocol/model/GameEvent.dart';

class TriggerGameEvent extends Command<void> {
  final String code = "27";
  String body;

  TriggerGameEvent(GameEvent event) {
    switch (event) {
      case GameEvent.kingInCheck:
        body = "ck";
        return;
      case GameEvent.blackWins:
        body = "bl";
        return;
      case GameEvent.whiteWins:
        body = "wt";
        return;
      case GameEvent.draw:
        body = "dw";
        return;
      default:
        throw new ArgumentError("Unknown event: $event");
    }
  }
}
