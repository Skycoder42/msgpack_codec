// ignore_for_file: unnecessary_lambdas

import 'package:msgpack_dart/src/common/msgpack_timestamp.dart';
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
      final values = [
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
      ];

      for (final (en, ts, tn) in values) {
        test(
            'converts nanoseconds ($en) to seconds ($ts) and nanoseconds ($tn) '
            'and back', () {
          final timestamp = MsgpackTimestamp.fromNanoSecondsSinceEpoch(en);
          expect(timestamp.seconds, equals(ts));
          expect(timestamp.nanoSeconds, equals(tn));
          final restoreNanos = timestamp.nanoSecondsSinceEpoch;
          expect(restoreNanos, en);
        });
      }
    });

    group('datetime conversion', () {
      final values = [
        (DateTime.utc(1970), BigInt.from(0), BigInt.from(0)),
        (DateTime.utc(0), BigInt.from(-62167219200), BigInt.from(0)),
        (
          DateTime.utc(0, 1, 2, 3, 4, 5, 6, 7),
          BigInt.from(-62167121755),
          BigInt.from(6007000)
        ),
        (
          DateTime.utc(2024, 12, 10, 16, 38, 17, 44, 55),
          BigInt.from(1733848697),
          BigInt.from(44055000)
        ),
      ];

      for (final (dt, ts, tn) in values) {
        test(
            'converts $dt to seconds ($ts) and nanoseconds ($tn) '
            'and back', () {
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
        });
      }

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
  });
}
