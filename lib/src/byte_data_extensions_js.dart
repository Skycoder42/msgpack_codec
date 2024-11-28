import 'dart:js_interop';
import 'dart:typed_data';

import 'common.dart';

@JS('Number.MAX_SAFE_INTEGER')
external int get _maxSafeInteger;

@JS('Number.MIN_SAFE_INTEGER')
external int get _minSafeInteger;

@JS('Number.isSafeInteger')
external bool _isSafeInteger(int value);

extension ByteDataExtensions on ByteData {
  void setUint64Safe(int byteOffset, int value, [Endian endian = Endian.big]) {
    if (!_isSafeInteger(value)) {
      throw FormatError('Cannot convert unsafe integers!');
    }
    assert(!value.isNegative, 'Use setInt64Safe for negative integers');

    final bigI = BigInt.from(value);
    _setBigInt64(byteOffset, bigI, endian);
  }

  void setInt64Safe(int byteOffset, int value, [Endian endian = Endian.big]) {
    if (!_isSafeInteger(value)) {
      throw FormatError('Cannot convert unsafe integers!');
    }

    final bigI = BigInt.from(value);
    _setBigInt64(byteOffset, bigI, endian);
  }

  int getUint64Safe(int byteOffset, [Endian endian = Endian.big]) {
    final bigI = _getBigInt64(byteOffset, endian);
    if (bigI > BigInt.from(_maxSafeInteger)) {
      throw FormatError(
        'Cannot convert values bigger than $_maxSafeInteger in JS',
      );
    }
    return bigI.toInt();
  }

  int getInt64Safe(int byteOffset, [Endian endian = Endian.big]) {
    final bigI = _getBigInt64(byteOffset, endian).toSigned(64);
    if (bigI > BigInt.from(_maxSafeInteger)) {
      throw FormatError(
        'Cannot convert values bigger than $_maxSafeInteger in JS',
      );
    } else if (bigI < BigInt.from(_minSafeInteger)) {
      throw FormatError(
        'Cannot convert values smaller than $_minSafeInteger in JS',
      );
    }
    return bigI.toInt();
  }

  void _setBigInt64(
    int byteOffset,
    BigInt value, [
    Endian endian = Endian.big,
  ]) {
    var bigI = value;
    for (var i = 0; i < 8; i++) {
      final offset = endian == Endian.little ? i : 7 - i;
      setUint8(byteOffset + offset, bigI.toUnsigned(8).toInt());
      bigI >>= 8;
    }
  }

  BigInt _getBigInt64(int byteOffset, [Endian endian = Endian.big]) {
    var bigI = BigInt.zero;
    for (var i = 0; i < 8; i++) {
      final offset = endian == Endian.big ? i : 7 - i;
      final byte = getUint8(byteOffset + offset);
      bigI <<= 8;
      bigI += BigInt.from(byte);
    }
    return bigI;
  }
}
