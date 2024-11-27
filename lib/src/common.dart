part of '../msgpack_dart.dart';

class FormatError implements Exception {
  FormatError(this.message);

  final String message;

  @override
  String toString() => 'FormatError: $message';
}
