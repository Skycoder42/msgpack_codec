class FormatError implements Exception {
  FormatError(this.message);

  final String message;

  @override
  String toString() => 'FormatError: $message';
}
