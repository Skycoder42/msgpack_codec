// coverage:ignore-file

class MsgpackFormatException implements Exception {
  MsgpackFormatException(this.message);

  final String message;

  @override
  String toString() => 'MsgpackFormatException: $message';
}
