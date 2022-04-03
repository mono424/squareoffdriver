enum FieldUpdateType {
  setDown, pickUp
}

class FieldUpdate {
  final FieldUpdateType type;
  final String field;

  FieldUpdate({this.type, this.field});
}