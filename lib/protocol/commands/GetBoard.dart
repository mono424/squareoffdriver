import 'package:squareoffdriver/SquareOff.dart';
import 'package:squareoffdriver/protocol/Answer.dart';
import 'package:squareoffdriver/protocol/Command.dart';

class GetBoard extends Command<Map<String, bool>> {
  final String code = "30";
  final String body = "R";
  final Answer<Map<String, bool>> answer = GetBoardReady();
}

class GetBoardReady extends Answer<Map<String, bool>> {
  final String code = "30";

  @override
  Map<String, bool> process(String msg) {
    List<bool> rawBoard = msg.split("#")[1].split("").map((e) => e == "1").toList();
    Map<String, bool> board = {};
    for (var i = 0; i < SquareOff.squares.length; i++) {
      board[SquareOff.squares[i]] = rawBoard[i];
    }
    return board;
  }
}