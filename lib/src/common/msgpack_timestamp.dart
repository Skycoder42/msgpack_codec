import 'package:meta/meta.dart';

// coverage:ignore-start
class TimestampTruncatedException implements Exception {
  final String message;

  TimestampTruncatedException(this.message);

  @override
  String toString() => 'TimestampTruncatedException: $message';
}
// coverage:ignore-end

@immutable
class MsgpackTimestamp implements Comparable<MsgpackTimestamp> {
  static final _dateTimeOffsetMicroSecondsMax =
      // 100000000 * 24 * 60 * 60 * 1000 * 1000
      BigInt.parse('8640000000000000000');
  static final _nanosPerSecond = BigInt.from(1000000000);

  static final zero = MsgpackTimestamp(BigInt.zero);

  final BigInt seconds;
  final BigInt nanoSeconds;

  MsgpackTimestamp(this.seconds, [BigInt? nanoSeconds])
      : nanoSeconds = nanoSeconds ?? BigInt.zero,
        assert(seconds.bitLength <= 64, 'seconds must be at most 64 bits'),
        assert(
          nanoSeconds == null || !nanoSeconds.isNegative,
          'nanoseconds must be positive',
        ),
        assert(
          nanoSeconds == null || nanoSeconds.bitLength <= 32,
          'nanoseconds must be at most 32 bits',
        );

  factory MsgpackTimestamp.fromNanoSecondsSinceEpoch(BigInt nanoSeconds) {
    var seconds = nanoSeconds ~/ _nanosPerSecond;
    final nanoSecondsRemainder = nanoSeconds % _nanosPerSecond;
    if (nanoSeconds.isNegative && nanoSecondsRemainder > BigInt.zero) {
      seconds -= BigInt.one;
    }
    return MsgpackTimestamp(seconds, nanoSecondsRemainder);
  }

  factory MsgpackTimestamp.fromDateTime(DateTime dateTime) =>
      MsgpackTimestamp.fromNanoSecondsSinceEpoch(
        BigInt.from(dateTime.microsecondsSinceEpoch) * BigInt.from(1000),
      );

  BigInt get nanoSecondsSinceEpoch => seconds * _nanosPerSecond + nanoSeconds;

  DateTime toDateTime({bool truncate = false}) {
    if (!truncate && nanoSeconds % BigInt.from(1000) != BigInt.zero) {
      throw TimestampTruncatedException(
        'Cannot convert timestamp with nanoseconds to DateTime',
      );
    }

    var microSeconds = nanoSecondsSinceEpoch ~/ BigInt.from(1000);
    if (microSeconds.abs() >= _dateTimeOffsetMicroSecondsMax) {
      if (truncate) {
        microSeconds =
            _dateTimeOffsetMicroSecondsMax * BigInt.from(microSeconds.sign);
      } else {
        throw TimestampTruncatedException(
          'Cannot convert timestamp with more than 100000000 days epoch offset',
        );
      }
    }

    // coverage:ignore-start
    if (!microSeconds.isValidInt) {
      throw TimestampTruncatedException(
        'Timestamp cannot be represented as integer',
      );
    }
    // coverage:ignore-end

    final dateTime = DateTime.fromMicrosecondsSinceEpoch(
      microSeconds.toInt(),
      isUtc: true,
    );
    return dateTime;
  }

  @override
  int compareTo(MsgpackTimestamp other) =>
      nanoSecondsSinceEpoch.compareTo(other.nanoSecondsSinceEpoch);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    } else if (other is! MsgpackTimestamp) {
      return false;
    } else {
      return seconds == other.seconds && nanoSeconds == other.nanoSeconds;
    }
  }

  @override
  int get hashCode => Object.hash(seconds, nanoSeconds);

  @override
  String toString() => 'MsgpackTimestamp($seconds, $nanoSeconds)';
}
