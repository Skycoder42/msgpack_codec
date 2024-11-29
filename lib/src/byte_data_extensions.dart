import 'dart:typed_data';

import 'common.dart';

extension ByteDataExtensions on ByteData {
  @pragma('vm:prefer-inline')
  void setUint64Safe(int byteOffset, int value, [Endian endian = Endian.big]) =>
      setUint64(byteOffset, value, endian);

  @pragma('vm:prefer-inline')
  void setInt64Safe(int byteOffset, int value, [Endian endian = Endian.big]) =>
      setInt64(byteOffset, value, endian);

  @pragma('vm:prefer-inline')
  int getUint64Safe(int byteOffset, [Endian endian = Endian.big]) =>
      getUint64(byteOffset, endian);

  @pragma('vm:prefer-inline')
  int getInt64Safe(int byteOffset, [Endian endian = Endian.big]) =>
      getInt64(byteOffset, endian);

  void setBigUint64(
    int byteOffset,
    BigInt value, [
    Endian endian = Endian.big,
  ]) {
    if (!value.isValidInt) {
      throw FormatError(
        'Value is too big to be serialized as a 64 bit integer',
      );
    }
    setUint64(byteOffset, value.toUnsigned(64).toInt(), endian);
  }

  void setBigInt64(
    int byteOffset,
    BigInt value, [
    Endian endian = Endian.big,
  ]) {
    if (!value.isValidInt) {
      throw FormatError(
        'Value is too big/small to be serialized as a 64 bit integer',
      );
    }
    setInt64(byteOffset, value.toSigned(64).toInt(), endian);
  }

  @pragma('vm:prefer-inline')
  BigInt getBigUint64(int byteOffset, [Endian endian = Endian.big]) =>
      BigInt.from(getUint64(byteOffset, endian));

  @pragma('vm:prefer-inline')
  BigInt getBigInt64(int byteOffset, [Endian endian = Endian.big]) =>
      BigInt.from(getInt64(byteOffset, endian));
}
