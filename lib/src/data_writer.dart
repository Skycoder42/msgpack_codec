import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'byte_data_extensions.dart'
    if (dart.library.js_interop) 'byte_data_extensions_js.dart';

const int _kScratchSizeInitial = 64;
const int _kScratchSizeRegular = 1024;

@internal
class DataWriter {
  Uint8List? _scratchBuffer;
  ByteData? scratchData;
  int scratchOffset = 0;

  void writeUint8(int i) {
    ensureSize(1);
    scratchData?.setUint8(scratchOffset, i);
    scratchOffset += 1;
  }

  void writeInt8(int i) {
    ensureSize(1);
    scratchData?.setInt8(scratchOffset, i);
    scratchOffset += 1;
  }

  void writeUint16(int i, [Endian endian = Endian.big]) {
    ensureSize(2);
    scratchData?.setUint16(scratchOffset, i, endian);
    scratchOffset += 2;
  }

  void writeInt16(int i, [Endian endian = Endian.big]) {
    ensureSize(2);
    scratchData?.setInt16(scratchOffset, i, endian);
    scratchOffset += 2;
  }

  void writeUint32(int i, [Endian endian = Endian.big]) {
    ensureSize(4);
    scratchData?.setUint32(scratchOffset, i, endian);
    scratchOffset += 4;
  }

  void writeInt32(int i, [Endian endian = Endian.big]) {
    ensureSize(4);
    scratchData?.setInt32(scratchOffset, i, endian);
    scratchOffset += 4;
  }

  void writeUint64(int i, [Endian endian = Endian.big]) {
    ensureSize(8);
    scratchData?.setUint64Safe(scratchOffset, i, endian);
    scratchOffset += 8;
  }

  void writeInt64(int i, [Endian endian = Endian.big]) {
    ensureSize(8);
    scratchData?.setInt64Safe(scratchOffset, i, endian);
    scratchOffset += 8;
  }

  void writeBigUint64(BigInt i, [Endian endian = Endian.big]) {
    ensureSize(8);
    scratchData?.setBigUint64(scratchOffset, i, endian);
    scratchOffset += 8;
  }

  void writeBigInt64(BigInt i, [Endian endian = Endian.big]) {
    ensureSize(8);
    scratchData?.setBigInt64(scratchOffset, i, endian);
    scratchOffset += 8;
  }

  void writeFloat32(double f, [Endian endian = Endian.big]) {
    ensureSize(4);
    scratchData?.setFloat32(scratchOffset, f, endian);
    scratchOffset += 4;
  }

  void writeFloat64(double f, [Endian endian = Endian.big]) {
    ensureSize(8);
    scratchData?.setFloat64(scratchOffset, f, endian);
    scratchOffset += 8;
  }

  // The list may be retained until takeBytes is called
  void writeBytes(List<int> bytes) {
    final length = bytes.length;
    if (length == 0) {
      return;
    }
    ensureSize(length);
    if (scratchOffset == 0) {
      // we can add it directly
      _builder.add(bytes);
    } else {
      // there is enough room in _scratchBuffer, otherwise _ensureSize
      // would have added _scratchBuffer to _builder and _scratchOffset would
      // be 0
      if (bytes is Uint8List) {
        _scratchBuffer?.setRange(
          scratchOffset,
          scratchOffset + length,
          bytes,
        );
      } else {
        for (var i = 0; i < length; i++) {
          _scratchBuffer?[scratchOffset + i] = bytes[i];
        }
      }
      scratchOffset += length;
    }
  }

  Uint8List takeBytes() {
    if (_builder.isEmpty) {
      // Just take scratch data
      final res = Uint8List.view(
        _scratchBuffer!.buffer,
        _scratchBuffer!.offsetInBytes,
        scratchOffset,
      );
      scratchOffset = 0;
      _scratchBuffer = null;
      scratchData = null;
      return res;
    } else {
      _appendScratchBuffer();
      return _builder.takeBytes();
    }
  }

  void ensureSize(int size) {
    if (_scratchBuffer == null) {
      // start with small scratch buffer, expand to regular later if needed
      _scratchBuffer = Uint8List(_kScratchSizeInitial);
      scratchData =
          ByteData.view(_scratchBuffer!.buffer, _scratchBuffer!.offsetInBytes);
    }
    final remaining = _scratchBuffer!.length - scratchOffset;
    if (remaining < size) {
      _appendScratchBuffer();
    }
  }

  void _appendScratchBuffer() {
    if (scratchOffset > 0) {
      if (_builder.isEmpty) {
        // We're still on small scratch buffer, move it to _builder
        // and create regular one
        _builder.add(
          Uint8List.view(
            _scratchBuffer!.buffer,
            _scratchBuffer!.offsetInBytes,
            scratchOffset,
          ),
        );
        _scratchBuffer = Uint8List(_kScratchSizeRegular);
        scratchData = ByteData.view(
          _scratchBuffer!.buffer,
          _scratchBuffer!.offsetInBytes,
        );
      } else {
        _builder.add(
          Uint8List.fromList(
            Uint8List.view(
              _scratchBuffer!.buffer,
              _scratchBuffer!.offsetInBytes,
              scratchOffset,
            ),
          ),
        );
      }
      scratchOffset = 0;
    }
  }

  final _builder = BytesBuilder(copy: false);
}
