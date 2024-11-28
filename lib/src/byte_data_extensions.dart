import 'dart:typed_data';

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
}
