import 'package:meta/meta.dart';

@immutable
final class Float {
  final double value;

  const Float(this.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    } else if (other is! Float) {
      return false;
    } else {
      return value == other.value;
    }
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}
