import 'dart:js_interop';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'format_error.dart';

@JS('Number.isSafeInteger')
external bool _isSafeInteger(int value);

@internal
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
    final bigI = getBigUint64(byteOffset, endian);
    if (!bigI.isValidInt) {
      throw FormatError(
        'Value is too big to be serialized as a 64 bit integer',
      );
    }
    return bigI.toInt();
  }

  int getInt64Safe(int byteOffset, [Endian endian = Endian.big]) {
    final bigI = getBigInt64(byteOffset, endian);
    if (!bigI.isValidInt) {
      throw FormatError(
        'Value is too big/small to be serialized as a 64 bit integer',
      );
    }
    return bigI.toInt();
  }

  @pragma('vm:prefer-inline')
  void setBigUint64(
    int byteOffset,
    BigInt value, [
    Endian endian = Endian.big,
  ]) =>
      _setBigInt64(byteOffset, value, endian);

  @pragma('vm:prefer-inline')
  void setBigInt64(
    int byteOffset,
    BigInt value, [
    Endian endian = Endian.big,
  ]) =>
      _setBigInt64(byteOffset, value, endian);

  @pragma('vm:prefer-inline')
  BigInt getBigUint64(int byteOffset, [Endian endian = Endian.big]) =>
      _getBigInt64(byteOffset, endian).toUnsigned(64);

  @pragma('vm:prefer-inline')
  BigInt getBigInt64(int byteOffset, [Endian endian = Endian.big]) =>
      _getBigInt64(byteOffset, endian).toSigned(64);

  void _setBigInt64(
    int byteOffset,
    BigInt value, [
    Endian endian = Endian.big,
  ]) {
    if (value.bitLength > 64) {
      throw FormatError(
        'Value is too big/small to be serialized as a 64 bit integer',
      );
    }

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
