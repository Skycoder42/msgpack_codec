// ignore_for_file: unnecessary_lambdas

import 'package:dart_test_tools/test.dart';
import 'package:msgpack_codec/src/common/msgpack_timestamp.dart';
import 'package:test/test.dart';

void main() {
  group('$MsgpackTimestamp', () {
    group('constructor', () {
      test('asserts if seconds are too large', () {
        expect(
          () => MsgpackTimestamp(BigInt.one << 64),
          throwsA(isA<AssertionError>()),
        );
        expect(
          () => MsgpackTimestamp(-BigInt.one << 65),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts if nanoseconds are negative', () {
        expect(
          () => MsgpackTimestamp(BigInt.one, -BigInt.one),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts if nanoseconds are too large', () {
        expect(
          () => MsgpackTimestamp(BigInt.one, BigInt.one << 32),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('nanoSecondsSinceEpoch conversion', () {
      testData('converts nanoseconds to timestamp and back', [
        (BigInt.from(0), BigInt.from(0), BigInt.from(0)),
        (BigInt.from(1), BigInt.from(0), BigInt.from(1)),
        (BigInt.from(-1), BigInt.from(-1), BigInt.from(999999999)),
        (BigInt.from(999999999), BigInt.from(0), BigInt.from(999999999)),
        (BigInt.from(-999999999), BigInt.from(-1), BigInt.from(1)),
        (BigInt.from(1000000000), BigInt.from(1), BigInt.from(0)),
        (BigInt.from(-1000000000), BigInt.from(-1), BigInt.from(0)),
        (BigInt.from(1000000001), BigInt.from(1), BigInt.from(1)),
        (BigInt.from(-1000000001), BigInt.from(-2), BigInt.from(999999999)),
        (
          BigInt.from(555444333222111),
          BigInt.from(555444),
          BigInt.from(333222111)
        ),
        (
          BigInt.from(-555444333222111),
          BigInt.from(-555445),
          BigInt.from(666777889)
        ),
      ], (fixture) {
        final (en, ts, tn) = fixture;
        final timestamp = MsgpackTimestamp.fromNanoSecondsSinceEpoch(en);
        expect(timestamp.seconds, equals(ts));
        expect(timestamp.nanoSeconds, equals(tn));
        final restoreNanos = timestamp.nanoSecondsSinceEpoch;
        expect(restoreNanos, en);
      });
    });

    group('datetime conversion', () {
      testData(
        'converts DateTime to timestamp and back',
        [
          (DateTime.utc(1970), BigInt.from(0), BigInt.from(0)),
          (DateTime.utc(0), BigInt.from(-62167219200), BigInt.from(0)),
          (
            DateTime.utc(0, 1, 2, 3, 4, 5, 6, 8),
            BigInt.from(-62167121755),
            BigInt.from(6008000)
          ),
          (
            DateTime.utc(2024, 12, 10, 16, 38, 17, 44, 55),
            BigInt.from(1733848697),
            BigInt.from(44055000)
          ),
        ],
        (fixture) {
          final (dt, ts, tn) = fixture;
          final timestamp = MsgpackTimestamp.fromDateTime(dt);
          expect(timestamp.seconds, equals(ts));
          expect(timestamp.nanoSeconds, equals(tn));
          final restoredDt = timestamp.toDateTime();
          expect(restoredDt.isUtc, isTrue);
          expect(restoredDt, dt);
          expect(
            timestamp.nanoSecondsSinceEpoch,
            BigInt.from(dt.microsecondsSinceEpoch) * BigInt.from(1000),
          );
        },
      );

      test('correctly handles timestamps with nanosecond values', () {
        final ts = MsgpackTimestamp(BigInt.one, BigInt.from(123456789));
        expect(
          () => ts.toDateTime(),
          throwsA(isA<TimestampTruncatedException>()),
        );
        expect(
          ts.toDateTime(truncate: true),
          DateTime.utc(1970, 1, 1, 0, 0, 1, 123, 456),
        );
      });

      test('correctly handles timestamps with very large timestamps', () {
        final tsPos = MsgpackTimestamp(BigInt.one << 63);
        expect(
          () => tsPos.toDateTime(),
          throwsA(isA<TimestampTruncatedException>()),
        );
        expect(
          tsPos.toDateTime(truncate: true),
          DateTime.utc(275760, 9, 13),
        );

        final tsNeg = MsgpackTimestamp(-BigInt.one << 63);
        expect(
          () => tsNeg.toDateTime(),
          throwsA(isA<TimestampTruncatedException>()),
        );
        expect(
          tsNeg.toDateTime(truncate: true),
          DateTime.utc(-271821, 4, 20),
        );
      });
    });

    testData(
      'compareTo correctly compares timestamps',
      [
        (
          MsgpackTimestamp(BigInt.from(10)),
          MsgpackTimestamp(BigInt.from(10)),
          0,
        ),
        (
          MsgpackTimestamp(BigInt.from(10)),
          MsgpackTimestamp(BigInt.from(20)),
          -1,
        ),
        (
          MsgpackTimestamp(BigInt.from(20)),
          MsgpackTimestamp(BigInt.from(10)),
          1,
        ),
      ],
      (fixture) {
        expect(fixture.$1.compareTo(fixture.$2).sign, fixture.$3);
      },
    );

    testData(
      'equality operator works correctly',
      [
        (MsgpackTimestamp.zero, MsgpackTimestamp.zero, true),
        (MsgpackTimestamp.zero, BigInt.zero, false),
        (MsgpackTimestamp(BigInt.one), MsgpackTimestamp(BigInt.one), true),
        (
          MsgpackTimestamp(BigInt.one, BigInt.one),
          MsgpackTimestamp(BigInt.one, BigInt.two),
          false
        ),
      ],
      (fixture) {
        expect(fixture.$1 == fixture.$2, fixture.$3);
        expect(fixture.$1.hashCode == fixture.$2.hashCode, fixture.$3);
      },
    );
  });
}
