import 'dart:async';

/// 一个简单的互斥锁实现,用于保护共享资源的访问。
///
/// 这个类提供了与 synchronized 包类似的功能,但使用 Dart 原生的 Completer 实现,
/// 不需要额外的依赖。
///
/// 使用示例:
/// ```dart
/// final lock = Lock();
///
/// // 同步执行
/// await lock.synchronized(() {
///   // 这段代码在任何时候只会有一个线程执行
///   print('执行受保护的代码');
///   return 'result';
/// });
///
/// // 异步执行
/// final result = await lock.synchronized(() async {
///   // 异步操作也会被正确保护
///   await Future.delayed(Duration(seconds: 1));
///   return 'async result';
/// });
/// ```
class Lock {
  /// 当前锁的状态
  bool _locked = false;

  /// 等待获取锁的队列
  final List<Completer<void>> _waitQueue = <Completer<void>>[];

  /// 在锁的保护下执行函数。
  ///
  /// 如果锁当前被占用,此调用将等待直到锁可用。
  /// 一旦获得锁,将执行 [computation] 函数,并在函数完成后释放锁。
  ///
  /// [computation] 可以是同步或异步函数,返回值将被传递给调用者。
  ///
  /// 返回 [computation] 的执行结果。
  Future<T> synchronized<T>(FutureOr<T> Function() computation) async {
    await _acquire();
    try {
      return await computation();
    } finally {
      _release();
    }
  }

  /// 获取锁。
  ///
  /// 如果锁当前可用,立即返回。
  /// 如果锁被占用,将等待直到锁被释放。
  Future<void> _acquire() async {
    if (!_locked) {
      _locked = true;
      return;
    }

    final Completer<void> completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  /// 释放锁。
  ///
  /// 如果有等待的调用者,将唤醒队列中的第一个。
  void _release() {
    if (_waitQueue.isNotEmpty) {
      final Completer<void> completer = _waitQueue.removeAt(0);
      completer.complete();
    } else {
      _locked = false;
    }
  }
}
