import 'package:squareoffdriver/protocol/Answer.dart';
import 'package:squareoffdriver/protocol/Command.dart';
import 'package:squareoffdriver/protocol/model/BatteryStatus.dart';

class RequestBattery extends Command<BatteryStatus> {
  final String code = "4";
  final String body = "";
  final Answer<BatteryStatus> answer = BatteryStatusAnswer();
}

class BatteryStatusAnswer extends Answer<BatteryStatus> {
  final String code = "22";

  @override
  BatteryStatus process(String msg) {
    return BatteryStatus(double.parse(msg.split("#")[1].replaceAll("*", "")));
  }
}