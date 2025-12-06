import 'dart:async';
import 'package:flutter/material.dart';

/// Debouncer untuk mencegah multiple calls dalam waktu singkat
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Extension untuk performance optimization
extension ListExtensions<T> on List<T> {
  /// Batch update untuk mengurangi rebuild
  List<T> batchUpdate(List<T> newItems) {
    return [...this, ...newItems];
  }
}

/// Memoization untuk expensive calculations
class Memoizer<T> {
  T? _cachedValue;
  bool _hasValue = false;

  T call(T Function() computation) {
    if (!_hasValue) {
      _cachedValue = computation();
      _hasValue = true;
    }
    return _cachedValue!;
  }

  void clear() {
    _cachedValue = null;
    _hasValue = false;
  }
}
