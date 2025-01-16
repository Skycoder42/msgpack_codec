import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:msgpack_dart2/src/codec.dart';
import 'package:msgpack_dart2/src/common/msgpack_timestamp.dart';
import 'package:msgpack_dart2/src/reader/ext_decoder.dart';
import 'package:msgpack_dart2/src/writer/ext_encoder.dart';
import 'package:test/test.dart';

part 'msgpack_test_suite_test.g.dart';

@immutable
class TestSuiteExt {
  final int id;
  final Uint8List bytes;

  const TestSuiteExt(this.id, this.bytes);

  @override
  bool operator ==(Object other) =>
      other is TestSuiteExt &&
      id == other.id &&
      const ListEquality<int>().equals(bytes, other.bytes);

  @override
  int get hashCode => Object.hash(id, bytes);

  @override
  String toString() => 'TestSuiteExt(id: $id, bytes: $bytes)';
}

class TestSuiteExtEncoder implements ExtEncoder {
  const TestSuiteExtEncoder();

  @override
  int? extTypeForObject(dynamic object) => switch (object) {
        TestSuiteExt(:final id) => id,
        _ => null,
      };

  @override
  Uint8List encodeObject(covariant TestSuiteExt object) => object.bytes;
}

class TestSuiteExtDecoder implements ExtDecoder {
  const TestSuiteExtDecoder();

  @override
  TestSuiteExt decodeObject(int id, Uint8List bytes) => TestSuiteExt(id, bytes);
}

Future<void> main() async {
  test(
    'validate test data is up to date',
    _validateUpToDate,
    testOn: 'vm',
  );

  final testData = _loadTestData();
  for (final MapEntry(key: testSuite, value: List<dynamic> testCases)
      in testData.entries) {
    group(testSuite, () {
      for (final testCase in testCases.cast<Map<String, dynamic>>()) {
        final msgpack = (testCase['msgpack'] as List).cast<String>();

        switch (testCase) {
          case {'nil': _}:
            _testValue(null, msgpack);
          case {'bool': final bool value}:
            _testValue(value, msgpack);
          case {'binary': final String value}:
            _testValue(_hexToBytes(value), msgpack.cast());
          case {'bignum': final String value}:
            final bigInt = BigInt.parse(value);
            _testValue(
              bigInt.isValidInt ? bigInt.toInt() : bigInt,
              msgpack,
              skip: bigInt.isValidInt
                  ? null
                  : '$bigInt cannot be converted to int',
            );
          case {'number': final num value}:
            _testValue(value, msgpack);
          case {'string': final String value}:
            _testValue(value, msgpack);
          case {'array': final List<dynamic> value}:
            _testValue(value, msgpack);
          case {'map': final Map<String, dynamic> value}:
            _testValue(value, msgpack);
          case {'timestamp': [final int seconds, final int nanoSeconds]}:
            final timestamp = MsgpackTimestamp(
              BigInt.from(seconds),
              BigInt.from(nanoSeconds),
            );
            _testValue(timestamp, msgpack);
          case {'ext': [final int id, final String bytes]}:
            _testValue(
              TestSuiteExt(id, _hexToBytes(bytes)),
              msgpack,
            );
          default:
            throw UnimplementedError('Unknown test case: $testCase');
        }
      }
    });
  }
}

const _testCodec = MsgpackCodec(
  extEncoder: TestSuiteExtEncoder(),
  extDecoder: TestSuiteExtDecoder(),
);

void _testValue(dynamic value, List<String> msgpack, {Object? skip}) {
  _testEncode(value, msgpack, skip: skip);
  _testEncodeChunked(value, msgpack, skip: skip);
  _testDecode(value, msgpack, skip: skip);
  _testDecodeChunked(value, msgpack, skip: skip);
}

void _testEncode(dynamic value, List<String> msgpack, {Object? skip}) {
  test(
    'serializes $value to any of $msgpack',
    skip: skip,
    () {
      final encoded = _testCodec.encode(value);
      expect(encoded, _hexEqualsAny(msgpack));
    },
  );
}

void _testEncodeChunked(dynamic value, List<String> msgpack, {Object? skip}) {
  test(
    'serializes $value to any of $msgpack (chunked)',
    skip: skip,
    () async {
      final encoded = Stream.value(value)
          .transform(_testCodec.encoder)
          .expand((chunk) => chunk)
          .toList();
      expect(encoded, completion(_hexEqualsAny(msgpack)));
    },
  );
}

void _testDecode(dynamic value, List<String> msgpack, {Object? skip}) {
  group('deserializes $value from', skip: skip, () {
    for (final representation in msgpack) {
      test('"$representation"', () {
        final decoded = _testCodec.decode(_hexToBytes(representation));
        expect(decoded, value);
      });
    }
  });
}

final _rng = Random.secure();

void _testDecodeChunked(dynamic value, List<String> msgpack, {Object? skip}) {
  group('deserializes $value from', skip: skip, () {
    for (final representation in msgpack) {
      test('"$representation" (chunked)', () {
        final bytes = _hexToBytes(representation);
        final chunks = <Uint8List>[];
        var offset = 0;
        while (offset < bytes.length) {
          final chunkSize = _rng.nextInt(bytes.length - offset) + 1;
          chunks.add(bytes.sublist(offset, offset + chunkSize));
          offset += chunkSize;
        }

        final decoded =
            Stream.fromIterable(chunks).transform(_testCodec.decoder).single;
        expect(decoded, completion(value));
      });
    }
  });
}

Matcher _hexEqualsAny(Iterable<String> hexRepresentations) => _AnyOf(
      hexRepresentations.map(_hexEquals).toList(),
    );

Matcher _hexEquals(String hexRepresentation) =>
    orderedEquals(_hexToBytes(hexRepresentation));

Uint8List _hexToBytes(String hexRepresentation) => hexRepresentation.isEmpty
    ? Uint8List(0)
    : Uint8List.fromList(
        hexRepresentation
            .split('-')
            .map((byte) => int.parse(byte, radix: 16))
            .toList(),
      );

class _AnyOf extends Matcher {
  final List<Matcher> _matchers;

  const _AnyOf(this._matchers);

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    for (final matcher in _matchers) {
      if (matcher.matches(item, matchState)) {
        return true;
      }
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.addAll('(', ' or ', ')', _matchers);
}
