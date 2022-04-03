import 'package:squareoffdriver/protocol/Answer.dart';
import 'package:squareoffdriver/protocol/model/PieceUpdate.dart';

class FieldUpdateAnswer extends Answer<FieldUpdate> {
  final String code = "0";

  @override
  FieldUpdate process(String msg) {
    String body = msg.split("#")[1];
    return FieldUpdate(
      field: body.substring(0, 2),
      type: body.substring(2, 3) == "u" ? FieldUpdateType.pickUp : FieldUpdateType.setDown
    );
  }
}