// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:msgpack_dart/src/codec.dart';
import 'package:msgpack_dart/src/common/msgpack_timestamp.dart';
import 'package:msgpack_dart/src/writer/float.dart';
import 'package:test/test.dart';

import 'test_utils.dart' if (dart.library.js_interop) 'test_utils_js.dart';

//
// Tests taken from msgpack2 (https://github.com/butlermatt/msgpack2)
//

Matcher isString = predicate((e) => e is String, 'is a String');
Matcher isInt = predicate((e) => e is int, 'is an int');
Matcher isMap = predicate((e) => e is Map, 'is a Map');
Matcher isList = predicate((e) => e is List, 'is a List');

void main() {
  test('Test Pack null', packNull);

  group('Test Pack Boolean', () {
    test('Pack boolean false', packFalse);
    test('Pack boolean true', packTrue);
  });

  group('Test Pack Ints', () {
    test('Pack Positive FixInt', packPositiveFixInt);
    test('Pack Negative FixInt', packFixedNegative);
    test('Pack Uint8', packUint8);
    test('Pack Uint16', packUint16);
    test('Pack Uint32', packUint32);
    test('Pack Uint64', packUint64);
    test('Pack Int8', packInt8);
    test('Pack Int16', packInt16);
    test('Pack Int32', packInt32);
    test('Pack Int64', packInt64);
  });

  group('Test Pack Floats', () {
    test('Pack Float32', packFloat32);
    test('Pack Float64 (double)', packDouble);
  });

  test('Pack 5-character string', packString5);
  test('Pack 22-character string', packString22);
  test('Pack 256-character string', packString256);
  test('Pack string array', packStringArray);
  test('Pack int-to-string map', packIntToStringMap);

  group('Test Pack Binary', () {
    test('Pack Bin8', packBin8);
    test('Pack Bin16', packBin16);
    test('Pack Bin32', packBin32);
    test('Pack ByteData', packByteData);
  });

  group('Test Pack Extensions', () {
    test('Pack timestamp32', packTimestamp32);
    test('Pack timestamp64', packTimestamp64);
    test('Pack timestamp96', packTimestamp96);
  });

  test('Test Unpack Null', unpackNull);

  group('Test Unpack boolean', () {
    test('Unpack boolean false', unpackFalse);
    test('Unpack boolean true', unpackTrue);
  });

  group('Test Unpack Ints', () {
    test('Unpack Positive FixInt', unpackPositiveFixInt);
    test('Unpack Negative FixInt', unpackNegativeFixInt);
    test('Unpack Uint8', unpackUint8);
    test('Unpack Uint16', unpackUint16);
    test('Unpack Uint32', unpackUint32);
    test('Unpack Uint64', unpackUint64);
    test('Unpack Int8', unpackInt8);
    test('Unpack Int16', unpackInt16);
    test('Unpack Int32', unpackInt32);
    test('Unpack Int64', unpackInt64);
  });

  group('Test Unpack Floats', () {
    test('Unpack Float32', unpackFloat32);
    test('Unpack Float64 (double)', unpackDouble);
  });

  test('Unpack 5-character string', unpackString5);
  test('Unpack 22-character string', unpackString22);
  test('Unpack 256-character string', unpackString256);
  test('Unpack string array', unpackStringArray);
  test('Unpack int-to-string map', unpackIntToStringMap);

  group('Test Large Array and Map', () {
    test('Large Array', largeArray);
    test('Very Large Array', veryLargeArray);
    test('Large Map', largeMap);
    test('Very Large Map', veryLargeMap);
  });

  group('Test Unpack Extensions', () {
    test('Unpack timestamp32', unpackTimestamp32);
    test('Unpack timestamp64', unpackTimestamp64);
    test('Unpack timestamp96', unpackTimestamp96);
  });
}

void largeArray() {
  final list = <String>[];
  for (var i = 0; i < 16; ++i) {
    list.add('Item $i');
  }

  final serialized = msgPack.encode(list);
  final deserialized = msgPack.decode(serialized) as List;
  expect(deserialized, list);
}

void veryLargeArray() {
  final list = <String>[];
  for (var i = 0; i < 65536; ++i) {
    list.add('Item $i');
  }

  final serialized = msgPack.encode(list);
  final deserialized = msgPack.decode(serialized) as List;
  expect(deserialized, list);
}

void largeMap() {
  final map = <int, String>{};
  for (var i = 0; i < 16; ++i) {
    map[i] = 'Item $i';
  }
  final serialized = msgPack.encode(map);
  final deserialized = msgPack.decode(serialized) as Map;
  expect(deserialized, map);
}

void veryLargeMap() {
  final map = <int, String>{};
  for (var i = 0; i < 65536; ++i) {
    map[i] = 'Item $i';
  }
  final serialized = msgPack.encode(map);
  final deserialized = msgPack.decode(serialized) as Map;
  expect(deserialized, map);
}

void packNull() {
  final List<int> encoded = msgPack.encode(null);
  expect(encoded, orderedEquals([0xc0]));
}

void packFalse() {
  final List<int> encoded = msgPack.encode(false);
  expect(encoded, orderedEquals([0xc2]));
}

void packTrue() {
  final List<int> encoded = msgPack.encode(true);
  expect(encoded, orderedEquals([0xc3]));
}

void packPositiveFixInt() {
  final List<int> encoded = msgPack.encode(1);
  expect(encoded, orderedEquals([1]));
}

void packFixedNegative() {
  final List<int> encoded = msgPack.encode(-16);
  expect(encoded, orderedEquals([240]));
}

void packUint8() {
  final List<int> encoded = msgPack.encode(128);
  expect(encoded, orderedEquals([204, 128]));
}

void packUint16() {
  final List<int> encoded = msgPack.encode(32768);
  expect(encoded, orderedEquals([205, 128, 0]));
}

void packUint32() {
  final List<int> encoded = msgPack.encode(2147483648);
  expect(encoded, orderedEquals([206, 128, 0, 0, 0]));
}

void packUint64() {
  final List<int> encoded = msgPack.encode(uint64TestValue);
  expect(
    encoded,
    orderedEquals(uint64Packed),
  );
}

void packInt8() {
  final List<int> encoded = msgPack.encode(-128);
  expect(encoded, orderedEquals([208, 128]));
}

void packInt16() {
  final List<int> encoded = msgPack.encode(-32768);
  expect(encoded, orderedEquals([209, 128, 0]));
}

void packInt32() {
  final List<int> encoded = msgPack.encode(-2147483648);
  expect(encoded, orderedEquals([210, 128, 0, 0, 0]));
}

void packInt64() {
  final List<int> encoded = msgPack.encode(int64TestValue);
  expect(encoded, orderedEquals(int64Packed));
}

void packFloat32() {
  final List<int> encoded = msgPack.encode(const Float(3.14));
  expect(encoded, orderedEquals([202, 64, 72, 245, 195]));
}

void packDouble() {
  final List<int> encoded = msgPack.encode(3.14);
  expect(
    encoded,
    orderedEquals([0xcb, 0x40, 0x09, 0x1e, 0xb8, 0x51, 0xeb, 0x85, 0x1f]),
  );
}

void packString5() {
  final List<int> encoded = msgPack.encode('hello');
  expect(encoded, orderedEquals([165, 104, 101, 108, 108, 111]));
}

void packString22() {
  final List<int> encoded = msgPack.encode('hello there, everyone!');
  expect(
    encoded,
    orderedEquals([
      182,
      104,
      101,
      108,
      108,
      111,
      32,
      116,
      104,
      101,
      114,
      101,
      44,
      32,
      101,
      118,
      101,
      114,
      121,
      111,
      110,
      101,
      33,
    ]),
  );
}

void packString256() {
  final List<int> encoded = msgPack.encode(
    // ignore: lines_longer_than_80_chars
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
  );
  expect(encoded, hasLength(259));
  expect(encoded.sublist(0, 3), orderedEquals([218, 1, 0]));
  expect(encoded.sublist(3, 259), everyElement(65));
}

void packBin8() {
  final data = Uint8List.fromList(List.filled(32, 65));
  final List<int> encoded = msgPack.encode(data);
  expect(encoded.length, equals(34));
  expect(encoded.getRange(0, 2), orderedEquals([0xc4, 32]));
  expect(encoded.getRange(2, encoded.length), orderedEquals(data));
}

void packBin16() {
  final data = Uint8List.fromList(List.filled(256, 65));
  final List<int> encoded = msgPack.encode(data);
  expect(encoded.length, equals(256 + 3));
  expect(encoded.getRange(0, 3), orderedEquals([0xc5, 1, 0]));
  expect(encoded.getRange(3, encoded.length), orderedEquals(data));
}

void packBin32() {
  final data = Uint8List.fromList(List.filled(65536, 65));
  final List<int> encoded = msgPack.encode(data);
  expect(encoded.length, equals(65536 + 5));
  expect(encoded.getRange(0, 5), orderedEquals([0xc6, 0, 1, 0, 0]));
  expect(encoded.getRange(5, encoded.length), orderedEquals(data));
}

void packByteData() {
  final data = ByteData.view(Uint8List.fromList(List.filled(32, 65)).buffer);
  final List<int> encoded = msgPack.encode(data);
  expect(encoded.length, equals(34));
  expect(encoded.getRange(0, 2), orderedEquals([0xc4, 32]));
  expect(
    encoded.getRange(2, encoded.length),
    orderedEquals(data.buffer.asUint8List()),
  );
}

void packStringArray() {
  final List<int> encoded = msgPack.encode(['one', 'two', 'three']);
  expect(
    encoded,
    orderedEquals([
      147,
      163,
      111,
      110,
      101,
      163,
      116,
      119,
      111,
      165,
      116,
      104,
      114,
      101,
      101,
    ]),
  );
}

void packIntToStringMap() {
  final List<int> encoded = msgPack.encode({1: 'one', 2: 'two'});
  expect(
    encoded,
    orderedEquals([130, 1, 163, 111, 110, 101, 2, 163, 116, 119, 111]),
  );
}

void packTimestamp32() {
  final timestamp = MsgpackTimestamp(BigInt.from(1605623935));
  final encoded = msgPack.encode(timestamp);
  expect(
    encoded,
    orderedEquals([
      // header
      0xd6, 0xFF,
      // seconds
      0x5F, 0xB3, 0xE0, 0x7F,
    ]),
  );
}

void packTimestamp64() {
  final timestamp = MsgpackTimestamp(
    BigInt.from(1605623935),
    BigInt.from(123456000),
  );
  // seconds(34): __00 0101 1111 1011 0011 1110 0000 0111 1111
  // nanoseconds(30): 0001 1101 0110 1111 0010 1000 0000 00__
  final encoded = msgPack.encode(timestamp);
  expect(
    encoded,
    orderedEquals([
      // header
      0xd7, 0xFF,
      // nanoseconds
      0x1D, 0x6F, 0x28,
      // nanoseconds + seconds
      0x00,
      // seconds
      0x5F, 0xB3, 0xE0, 0x7F,
    ]),
  );
}

void packTimestamp96() {
  final timestamp = MsgpackTimestamp(
    BigInt.from(-23198174465),
    BigInt.from(987655321),
  );
  final encoded = msgPack.encode(timestamp);
  expect(
    encoded,
    orderedEquals(
      [
        // header
        0xc7, 12, 0xFF,
        // nanoseconds
        0x3A, 0xDE, 0x6C, 0x99,
        // seconds
        0xFF, 0xFF, 0xFF, 0xFA, 0x99, 0x47, 0xF2, 0xFF,
      ],
    ),
  );
}

// Test unpacking
void unpackNull() {
  final data = Uint8List.fromList([0xc0]);
  final value = msgPack.decode(data);
  expect(value, isNull);
}

void unpackFalse() {
  final data = Uint8List.fromList([0xc2]);
  final value = msgPack.decode(data);
  expect(value, isFalse);
}

void unpackTrue() {
  final data = Uint8List.fromList([0xc3]);
  final value = msgPack.decode(data);
  expect(value, isTrue);
}

void unpackString5() {
  final data = Uint8List.fromList([165, 104, 101, 108, 108, 111]);
  final value = msgPack.decode(data);
  expect(value, isString);
  expect(value, equals('hello'));
}

void unpackString22() {
  final data = Uint8List.fromList([
    182,
    104,
    101,
    108,
    108,
    111,
    32,
    116,
    104,
    101,
    114,
    101,
    44,
    32,
    101,
    118,
    101,
    114,
    121,
    111,
    110,
    101,
    33,
  ]);
  final value = msgPack.decode(data);
  expect(value, isString);
  expect(value, equals('hello there, everyone!'));
}

void unpackPositiveFixInt() {
  final data = Uint8List.fromList([1]);
  final value = msgPack.decode(data);
  expect(value, isInt);
  expect(value, equals(1));
}

void unpackNegativeFixInt() {
  final data = Uint8List.fromList([240]);
  final value = msgPack.decode(data);
  expect(value, isInt);
  expect(value, equals(-16));
}

void unpackUint8() {
  final data = Uint8List.fromList([204, 128]);
  final value = msgPack.decode(data);
  expect(value, isInt);
  expect(value, equals(128));
}

void unpackUint16() {
  final data = Uint8List.fromList([205, 128, 0]);
  final value = msgPack.decode(data);
  expect(value, isInt);
  expect(value, equals(32768));
}

void unpackUint32() {
  final data = Uint8List.fromList([206, 128, 0, 0, 0]);
  final value = msgPack.decode(data);
  expect(value, isInt);
  expect(value, equals(2147483648));
}

void unpackUint64() {
  // Dart 2 doesn't support true Uint64 without using BigInt
  final data = Uint8List.fromList(uint64Packed);
  final value = msgPack.decode(data);
  expect(value, isInt);
  expect(value, equals(uint64TestValue));
}

void unpackInt8() {
  final data = Uint8List.fromList([208, 128]);
  final value = msgPack.decode(data);
  expect(value, isInt);
  expect(value, equals(-128));
}

void unpackInt16() {
  final data = Uint8List.fromList([209, 128, 0]);
  final value = msgPack.decode(data);
  expect(value, isInt);
  expect(value, equals(-32768));
}

void unpackInt32() {
  final data = Uint8List.fromList([210, 128, 0, 0, 0]);
  final value = msgPack.decode(data);
  expect(value, isInt);
  expect(value, equals(-2147483648));
}

void unpackInt64() {
  final data = Uint8List.fromList(int64Packed);
  final value = msgPack.decode(data);
  expect(value, isInt);
  expect(value, equals(int64TestValue));
}

void unpackFloat32() {
  final data = Uint8List.fromList([202, 64, 72, 245, 195]);
  final value = msgPack.decode(data);
  expect((value as double).toStringAsPrecision(3), equals('3.14'));
}

void unpackDouble() {
  final data = Uint8List.fromList(
    [0xcb, 0x40, 0x09, 0x1e, 0xb8, 0x51, 0xeb, 0x85, 0x1f],
  );
  final value = msgPack.decode(data);
  expect(value, equals(3.14));
}

void unpackString256() {
  final data = Uint8List.fromList([218, 1, 0, ...List.filled(256, 65)]);
  final value = msgPack.decode(data);
  expect(value, isString);
  expect(
    value,
    equals(
      // ignore: lines_longer_than_80_chars
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
    ),
  );
}

void unpackStringArray() {
  final data = Uint8List.fromList([
    147,
    163,
    111,
    110,
    101,
    163,
    116,
    119,
    111,
    165,
    116,
    104,
    114,
    101,
    101,
  ]);
  final value = msgPack.decode(data);
  expect(value, isList);
  expect(value, orderedEquals(['one', 'two', 'three']));
}

void unpackIntToStringMap() {
  final data = Uint8List.fromList(
    [130, 1, 163, 111, 110, 101, 2, 163, 116, 119, 111],
  );
  final value = msgPack.decode(data);
  expect(value, isMap);
  value as Map;
  expect(value[1], equals('one'));
  expect(value[2], equals('two'));
}

void unpackTimestamp32() {
  final data = Uint8List.fromList([
    // header
    0xd6, 0xFF,
    // seconds
    0x5F, 0xB3, 0xE0, 0x7F,
  ]);
  final value = msgPack.decode(data);

  expect(value, isA<MsgpackTimestamp>());
  expect(value, MsgpackTimestamp(BigInt.from(1605623935)));
}

void unpackTimestamp64() {
  final data = Uint8List.fromList([
    // header
    0xd7, 0xFF,
    // nanoseconds
    0x1D, 0x6F, 0x34,
    // nanoseconds + seconds
    0x54,
    // seconds
    0x5F, 0xB3, 0xE0, 0x7F,
  ]);
  final value = msgPack.decode(data);

  expect(value, isA<MsgpackTimestamp>());
  expect(
    value,
    MsgpackTimestamp(BigInt.from(1605623935), BigInt.from(123456789)),
  );
}

void unpackTimestamp96() {
  final data = Uint8List.fromList([
    // header
    0xc7, 12, 0xFF,
    // nanoseconds
    0x3A, 0xDE, 0x6C, 0x99,
    // seconds
    0xFF, 0xFF, 0xFF, 0xFA, 0x99, 0x47, 0xF2, 0xFF,
  ]);
  final value = msgPack.decode(data);

  expect(value, isA<MsgpackTimestamp>());
  expect(
    value,
    MsgpackTimestamp(BigInt.from(-23198174465), BigInt.from(987655321)),
  );
}
