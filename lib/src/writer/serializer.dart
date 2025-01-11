import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../common/format_error.dart';
import '../common/msgpack_timestamp.dart';
import 'data_writer.dart';
import 'ext_encoder.dart';
import 'float.dart';

@internal
class Serializer {
  final DataWriterBase _writer;
  final Encoding _codec;
  final ExtEncoder? _extEncoder;

  Serializer(this._writer, this._codec, this._extEncoder);

  void encode(dynamic d) {
    if (d == null) return _writer.writeUint8(0xc0);
    if (d is bool) return _writer.writeUint8(d ? 0xc3 : 0xc2);
    if (d is int) return d >= 0 ? _writePositiveInt(d) : _writeNegativeInt(d);
    if (d is Float) return _writeFloat(d);
    if (d is double) return _writeDouble(d);
    if (d is String) return _writeString(d);
    if (d is Uint8List) return _writeBinary(d);
    if (d is Iterable) return _writeIterable(d);
    if (d is ByteData) {
      return _writeBinary(
        d.buffer.asUint8List(d.offsetInBytes, d.lengthInBytes),
      );
    }
    if (d is Map) return _writeMap(d);
    if (_extEncoder != null && _writeExt(d)) {
      return;
    }
    // run built-in extensions AFTER the custom ones
    if (d is MsgpackTimestamp) return _writeTimeStamp(d);
    throw FormatError("Don't know how to serialize $d");
  }

  void _writeNegativeInt(int n) {
    if (n >= -32) {
      _writer.writeInt8(n);
    } else if (n >= -128) {
      _writer.writeUint8(0xd0);
      _writer.writeInt8(n);
    } else if (n >= -32768) {
      _writer.writeUint8(0xd1);
      _writer.writeInt16(n);
    } else if (n >= -2147483648) {
      _writer.writeUint8(0xd2);
      _writer.writeInt32(n);
    } else {
      _writer.writeUint8(0xd3);
      _writer.writeInt64(n);
    }
  }

  void _writePositiveInt(int n) {
    if (n <= 127) {
      _writer.writeUint8(n);
    } else if (n <= 0xFF) {
      _writer.writeUint8(0xcc);
      _writer.writeUint8(n);
    } else if (n <= 0xFFFF) {
      _writer.writeUint8(0xcd);
      _writer.writeUint16(n);
    } else if (n <= 0xFFFFFFFF) {
      _writer.writeUint8(0xce);
      _writer.writeUint32(n);
    } else {
      _writer.writeUint8(0xcf);
      _writer.writeUint64(n);
    }
  }

  void _writeFloat(Float n) {
    _writer.writeUint8(0xca);
    _writer.writeFloat32(n.value);
  }

  void _writeDouble(double n) {
    _writer.writeUint8(0xcb);
    _writer.writeFloat64(n);
  }

  void _writeString(String s) {
    final encoded = _codec.encode(s);
    final length = encoded.length;
    if (length <= 31) {
      _writer.writeUint8(0xA0 | length);
    } else if (length <= 0xFF) {
      _writer.writeUint8(0xd9);
      _writer.writeUint8(length);
    } else if (length <= 0xFFFF) {
      _writer.writeUint8(0xda);
      _writer.writeUint16(length);
    } else if (length <= 0xFFFFFFFF) {
      _writer.writeUint8(0xdb);
      _writer.writeUint32(length);
    } else {
      throw FormatError('String is too long to be serialized with msgpack.');
    }
    _writer.writeBytes(encoded);
  }

  void _writeBinary(Uint8List buffer) {
    final length = buffer.length;
    if (length <= 0xFF) {
      _writer.writeUint8(0xc4);
      _writer.writeUint8(length);
    } else if (length <= 0xFFFF) {
      _writer.writeUint8(0xc5);
      _writer.writeUint16(length);
    } else if (length <= 0xFFFFFFFF) {
      _writer.writeUint8(0xc6);
      _writer.writeUint32(length);
    } else {
      throw FormatError('Data is too long to be serialized with msgpack.');
    }
    _writer.writeBytes(buffer);
  }

  void _writeIterable(Iterable<dynamic> iterable) {
    final length = iterable.length;

    if (length <= 0xF) {
      _writer.writeUint8(0x90 | length);
    } else if (length <= 0xFFFF) {
      _writer.writeUint8(0xdc);
      _writer.writeUint16(length);
    } else if (length <= 0xFFFFFFFF) {
      _writer.writeUint8(0xdd);
      _writer.writeUint32(length);
    } else {
      throw FormatError('Array is too big to be serialized with msgpack');
    }

    for (final item in iterable) {
      encode(item);
    }
  }

  void _writeMap(Map<dynamic, dynamic> map) {
    final length = map.length;

    if (length <= 0xF) {
      _writer.writeUint8(0x80 | length);
    } else if (length <= 0xFFFF) {
      _writer.writeUint8(0xde);
      _writer.writeUint16(length);
    } else if (length <= 0xFFFFFFFF) {
      _writer.writeUint8(0xdf);
      _writer.writeUint32(length);
    } else {
      throw FormatError('Map is too big to be serialized with msgpack');
    }

    for (final item in map.entries) {
      encode(item.key);
      encode(item.value);
    }
  }

  void _writeTimeStamp(MsgpackTimestamp timestamp) {
    final MsgpackTimestamp(:seconds, :nanoSeconds) = timestamp;

    if (seconds < BigInt.zero || seconds.bitLength > 34) {
      // value is too big for timestamp64
      _writer.writeBytes(const [0xc7, 12, 0xff]);
      _writer.writeUint32(nanoSeconds.toInt());
      _writer.writeBigInt64(seconds);
    } else {
      if (seconds.bitLength > 32 || nanoSeconds != BigInt.zero) {
        // value is too big or too precise for timestamp32
        _writer.writeBytes(const [0xd7, 0xff]);
        _writer.writeBigUint64((nanoSeconds << 34) | seconds);
      } else {
        _writer.writeBytes(const [0xd6, 0xff]);
        _writer.writeUint32(seconds.toInt());
      }
    }
  }

  bool _writeExt(dynamic object) {
    final type = _extEncoder?.extTypeForObject(object);
    if (type != null) {
      if (type < 0) {
        throw FormatError('Negative ext type is reserved');
      }
      final encoded = _extEncoder?.encodeObject(object);
      if (encoded == null) {
        throw FormatError('Unable to encode object. No Encoder specified.');
      }

      final length = encoded.length;
      if (length == 1) {
        _writer.writeUint8(0xd4);
      } else if (length == 2) {
        _writer.writeUint8(0xd5);
      } else if (length == 4) {
        _writer.writeUint8(0xd6);
      } else if (length == 8) {
        _writer.writeUint8(0xd7);
      } else if (length == 16) {
        _writer.writeUint8(0xd8);
      } else if (length <= 0xFF) {
        _writer.writeUint8(0xc7);
        _writer.writeUint8(length);
      } else if (length <= 0xFFFF) {
        _writer.writeUint8(0xc8);
        _writer.writeUint16(length);
      } else if (length <= 0xFFFFFFFF) {
        _writer.writeUint8(0xc9);
        _writer.writeUint32(length);
      } else {
        throw FormatError('Size must be at most 0xFFFFFFFF');
      }
      _writer.writeUint8(type);
      _writer.writeBytes(encoded);
      return true;
    }
    return false;
  }
}
