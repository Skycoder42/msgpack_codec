import 'dart:convert';
import 'dart:typed_data';

import 'byte_data_extensions.dart'
    if (dart.library.js_interop) 'byte_data_extensions_js.dart';
import 'common.dart';

abstract class ExtDecoder {
  /// Return null if the data cannot be decoded
  dynamic decodeObject(int extType, Uint8List data);
}

class Deserializer {
  final ExtDecoder? _extDecoder;
  final codec = const Utf8Codec();
  final Uint8List _list;
  final ByteData _data;
  int _offset = 0;

  Deserializer(
    Uint8List list, {
    ExtDecoder? extDecoder,
    this.copyBinaryData = false,
  })  : _list = list,
        _data = ByteData.view(list.buffer, list.offsetInBytes),
        _extDecoder = extDecoder;

  /// If false, decoded binary data buffers will reference underlying input
  /// buffer and thus may change when the content of input buffer changes.
  ///
  /// If true, decoded buffers are copies and the underlying input buffer is
  /// free to change after decoding.
  final bool copyBinaryData;

  dynamic decode() {
    final u = _list[_offset++];
    if (u <= 127) {
      return u;
    } else if ((u & 0xE0) == 0xE0) {
      // negative small integer
      return u - 256;
    } else if ((u & 0xE0) == 0xA0) {
      return _readString(u & 0x1F);
    } else if ((u & 0xF0) == 0x90) {
      return _readArray(u & 0xF);
    } else if ((u & 0xF0) == 0x80) {
      return _readMap(u & 0xF);
    }
    switch (u) {
      case 0xc0:
        return null;
      case 0xc2:
        return false;
      case 0xc3:
        return true;
      case 0xcc:
        return _readUInt8();
      case 0xcd:
        return _readUInt16();
      case 0xce:
        return _readUInt32();
      case 0xcf:
        return _readUInt64();
      case 0xd0:
        return _readInt8();
      case 0xd1:
        return _readInt16();
      case 0xd2:
        return _readInt32();
      case 0xd3:
        return _readInt64();
      case 0xca:
        return _readFloat();
      case 0xcb:
        return _readDouble();
      case 0xd9:
        return _readString(_readUInt8());
      case 0xda:
        return _readString(_readUInt16());
      case 0xdb:
        return _readString(_readUInt32());
      case 0xc4:
        return _readBuffer(_readUInt8());
      case 0xc5:
        return _readBuffer(_readUInt16());
      case 0xc6:
        return _readBuffer(_readUInt32());
      case 0xdc:
        return _readArray(_readUInt16());
      case 0xdd:
        return _readArray(_readUInt32());
      case 0xde:
        return _readMap(_readUInt16());
      case 0xdf:
        return _readMap(_readUInt32());
      case 0xd4:
        return _readExt(1);
      case 0xd5:
        return _readExt(2);
      case 0xd6:
        return _readExt(4);
      case 0xd7:
        return _readExt(8);
      case 0xd8:
        return _readExt(16);
      case 0xc7:
        return _readExt(_readUInt8());
      case 0xc8:
        return _readExt(_readUInt16());
      case 0xc9:
        return _readExt(_readUInt32());
      default:
        throw FormatError('Invalid MessagePack format');
    }
  }

  int _readInt8() => _data.getInt8(_offset++);

  int _readUInt8() => _data.getUint8(_offset++);

  int _readUInt16() {
    final res = _data.getUint16(_offset);
    _offset += 2;
    return res;
  }

  int _readInt16() {
    final res = _data.getInt16(_offset);
    _offset += 2;
    return res;
  }

  int _readUInt32() {
    final res = _data.getUint32(_offset);
    _offset += 4;
    return res;
  }

  int _readInt32() {
    final res = _data.getInt32(_offset);
    _offset += 4;
    return res;
  }

  int _readUInt64() {
    final res = _data.getUint64Safe(_offset);
    _offset += 8;
    return res;
  }

  int _readInt64() {
    final res = _data.getInt64Safe(_offset);
    _offset += 8;
    return res;
  }

  BigInt _readBigUInt64() {
    final res = _data.getBigUint64(_offset);
    _offset += 8;
    return res;
  }

  BigInt _readBigInt64() {
    final res = _data.getBigInt64(_offset);
    _offset += 8;
    return res;
  }

  double _readFloat() {
    final res = _data.getFloat32(_offset);
    _offset += 4;
    return res;
  }

  double _readDouble() {
    final res = _data.getFloat64(_offset);
    _offset += 8;
    return res;
  }

  Uint8List _readBuffer(int length) {
    final res =
        Uint8List.view(_list.buffer, _list.offsetInBytes + _offset, length);
    _offset += length;
    return copyBinaryData ? Uint8List.fromList(res) : res;
  }

  String _readString(int length) {
    final list = _readBuffer(length);
    final len = list.length;
    for (var i = 0; i < len; ++i) {
      if (list[i] > 127) {
        return codec.decode(list);
      }
    }
    return String.fromCharCodes(list);
  }

  List<dynamic> _readArray(int length) {
    final res = List<dynamic>.filled(length, null);
    for (var i = 0; i < length; ++i) {
      res[i] = decode();
    }
    return res;
  }

  Map<dynamic, dynamic> _readMap(int length) {
    final res = <dynamic, dynamic>{};
    var remainingLength = length;
    while (remainingLength > 0) {
      res[decode()] = decode();
      --remainingLength;
    }
    return res;
  }

  dynamic _readExt(int length) => switch (_readUInt8()) {
        0xFF => _readTimestamp(length),
        final extType => _readCustomExt(extType, length),
      };

  DateTime _readTimestamp(int length) {
    int toMicroSecondsSafe(BigInt seconds, BigInt nanoSeconds) {
      final microSeconds =
          seconds * BigInt.from(1000000) + nanoSeconds ~/ BigInt.from(1000);
      if (!microSeconds.isValidInt) {
        throw FormatError(
          'timestamp is to big to be safely represented in dart',
        );
      }
      return microSeconds.toInt();
    }

    switch (length) {
      case 4:
        return DateTime.fromMillisecondsSinceEpoch(
          _readUInt32() * 1000,
          isUtc: true,
        );
      case 8:
        final value = _readBigUInt64();
        final nanoSeconds = value >> 34;
        final seconds = value & BigInt.from(0x00000003ffffffff);
        return DateTime.fromMicrosecondsSinceEpoch(
          toMicroSecondsSafe(seconds, nanoSeconds),
          isUtc: true,
        );
      case 12:
        final nanoSeconds = _readUInt32();
        final seconds = _readBigInt64();
        return DateTime.fromMicrosecondsSinceEpoch(
          toMicroSecondsSafe(seconds, BigInt.from(nanoSeconds)),
          isUtc: true,
        );
      default:
        return throw FormatError(
          'Unexpected timestamp length $length. Must be 4, 8 or 12 bytes',
        );
    }
  }

  dynamic _readCustomExt(int extType, int length) {
    final data = _readBuffer(length);
    final decoded = _extDecoder?.decodeObject(extType, data);
    if (decoded != null) {
      return decoded;
    }
    throw FormatError(
      "Don't know how to deserialize "
      '0x${extType.toRadixString(16).padLeft(2, '0')}',
    );
  }
}
