# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.1] - 2025-01-30
### Changed
- Improved exception handling
  - encoder and decoder now wrap all exceptions as `MsgpackFormatException`

## [2.0.0+1] - 2025-01-18
### Changed
- Initial automated release

## [2.0.0] - 2025-01-18
### Changed
- Forked the library to archive add the following:
  - Dart JS support
  - Timestamp extension
  - message pack codec with chunked conversion
  - more and better tests
  - various code cleanups and modernizations
- renamed to `msgpack_codec`

## 1.0.1 - 2023-01-12
- Remove dependency on dart:io

## 1.0.0 - 2021-03-11
- Migrated to null safety (thanks RootSoft)

## 0.0.7 - 2020-03-14
- Fix wrong length when writing ext8 (0xc7)

## 0.0.6 - 2019-09-20
- Accept any iterable when serializing, not just List
- Accept ByteData when serializing (will be deserialized as Uint8List)

## 0.0.5 - 2019-05-19
- Changed return value from `List<int>` to `Uint8List`.

[2.0.1]: https://github.com/Skycoder42/msgpack_codec/compare/v2.0.0+1...v2.0.1
[2.0.0+1]: https://github.com/Skycoder42/msgpack_codec/compare/v2.0.0...v2.0.0+1
[2.0.0]: https://github.com/Skycoder42/msgpack_codec/releases/tag/v2.0.0
