// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:msgpack_dart2/msgpack_dart2.dart';

void main(List<String> args) {
  final data = {
    'name': 'John Doe',
    'age': 30,
    'isEmployed': true,
    'children': [
      {'name': 'Alice', 'age': 7},
      {'name': 'Bob', 'age': 10},
    ],
  };

  final encoded = msgPack.encode(data);

  print('Encoded: ${_toHexString(encoded)}');

  final decoded = msgPack.decode(encoded);

  print('Decoded: $decoded');
}

String _toHexString(Uint8List bytes) =>
    bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join('-');
