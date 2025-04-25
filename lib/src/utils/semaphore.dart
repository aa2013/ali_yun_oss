import 'dart:async';

/// 一个简单的信号量实现,用于限制同时执行的异步操作数量。
///
/// 信号量维护一个计数器,表示当前可用的“许可”。
/// 当一个操作想要执行时,它必须先调用 [acquire] 获取一个许可。
/// 如果计数器大于零,许可被授予,计数器减一。
/// 如果计数器为零,操作必须等待,直到其他操作调用 [release] 释放一个许可。
///
/// **重要提示:** 调用者必须确保每次成功调用 [acquire] 后,
/// 最终都会调用 [release] 来释放许可,即使在发生错误时也是如此。
/// 通常建议在 `try...finally` 块中使用,以确保 [release] 总能被执行。
///
/// ```dart
/// final semaphore = Semaphore(3); // 最多允许 3 个并发操作
///
/// Future<void> performTask() async {
///   await semaphore.acquire();
///   try {
///     // 执行需要限制并发的操作
///     print('Task started');
///     await Future.delayed(Duration(seconds: 1));
///     print('Task finished');
///   } finally {
///     semaphore.release();
///   }
/// }
///
/// // 启动多个任务
/// List<Future<void>> tasks = [];
/// for (int i = 0; i < 10; i++) {
///   tasks.add(performTask());
/// }
/// await Future.wait(tasks);
/// ```
class Semaphore {
  /// 允许的最大并发数量。
  final int _maxCount;

  /// 当前已获取但尚未释放的许可数量。
  int _currentCount = 0;

  /// 等待获取许可的操作队列。
  /// 每个 Completer 代表一个等待的操作。
  final List<Completer<void>> _waiters = [];

  /// 创建一个新的信号量实例。
  ///
  /// [maxCount] 必须大于 0,表示允许的最大并发操作数。
  /// 如果 [maxCount] 小于或等于 0,将抛出 [ArgumentError]。
  Semaphore(this._maxCount) {
    if (_maxCount <= 0) {
      throw ArgumentError('maxCount 必须大于 0');
    }
  }

  /// 获取一个信号量许可。
  ///
  /// 如果当前有可用的许可 (`_currentCount < _maxCount`),则立即授予许可,
  /// `_currentCount` 增加 1,并返回一个已完成的 Future。
  ///
  /// 如果没有可用的许可,此调用将异步等待,直到有其他操作调用 [release]
  /// 释放一个许可。一旦获得许可,`_currentCount` 不会立即增加（因为许可来自等待队列）,
  /// 而是由调用 [release] 的操作负责维护计数器的平衡。
  ///
  /// 返回一个 Future,该 Future 在获得许可时完成。
  Future<void> acquire() async {
    if (_currentCount < _maxCount) {
      _currentCount++;
      return Future.value();
    }

    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  /// 释放一个信号量许可。
  ///
  /// 如果有操作正在等待 ([_waiters] 不为空),则唤醒等待队列中的第一个操作,
  /// 让其获得许可。在这种情况下,`_currentCount` 不会改变,因为许可直接传递给了等待者。
  ///
  /// 如果没有操作在等待,则简单地将 `_currentCount` 减 1,表示一个许可已被释放回池中。
  ///
  /// **重要:** 调用者必须确保每次成功调用 [acquire] 后都调用此方法,
  /// 以避免死锁或资源泄漏。
  void release() {
    if (_waiters.isNotEmpty) {
      final completer = _waiters.removeAt(0);
      completer.complete();
    } else {
      _currentCount--;
    }
  }
}
