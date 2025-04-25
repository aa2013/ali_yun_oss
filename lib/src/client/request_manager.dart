import 'dart:developer';

import 'package:dio/dio.dart';

/// OSS请求管理器
///
/// 负责管理阿里云OSS请求的取消令牌（CancelToken）,提供了创建、获取、取消和清理令牌的功能。
/// 该类与 OSSRequestHandler 密切协作,实现了请求的生命周期管理和取消控制。
///
/// 主要功能：
/// - 为每个请求创建和管理唯一的取消令牌
/// - 支持根据请求键（通常是文件键）取消特定请求
/// - 支持取消所有正在进行的请求
/// - 自动管理令牌资源,避免内存泄漏
class OSSRequestManager {
  /// 存储请求键与取消令牌的映射关系
  final Map<String, CancelToken> _tokens = <String, CancelToken>{};

  /// 请求ID计数器,用于生成唯一的请求ID
  int _requestId = 0;

  /// 默认构造函数
  ///
  /// 创建一个新的 OSS 请求管理器实例
  OSSRequestManager();

  /// 生成唯一请求ID
  ///
  /// 使用递增的计数器生成唯一的请求标识符,格式为 'request_X',其中 X 是递增的整数。
  /// 这确保了在应用生命周期内每个自动生成的请求ID都是唯一的。
  ///
  /// 返回一个新的唯一请求ID字符串
  String _generateRequestId() => 'request_${_requestId++}';

  /// 获取或创建CancelToken
  ///
  /// 根据提供的键获取现有的 CancelToken,如果不存在则创建新的令牌。
  /// 这确保了同一个键的多次调用会返回相同的 CancelToken 实例。
  ///
  /// 参数：
  /// - [key] 可选的请求键,可以是文件键或其他唯一标识。如果为 null,将自动生成一个唯一的请求ID
  ///
  /// 返回与指定键关联的 CancelToken 实例
  CancelToken getToken([String? key]) {
    // 如果没有提供键,生成一个唯一的请求ID
    final String requestKey = key ?? _generateRequestId();

    // 如果该键已存在令牌,返回现有的；否则创建新的
    return _tokens.putIfAbsent(requestKey, () => CancelToken());
  }

  /// 取消指定请求
  ///
  /// 根据提供的键取消相应的请求。如果找到并成功取消,该令牌将从管理器中移除。
  /// 如果指定的键不存在或已经被取消,则不执行任何操作。
  ///
  /// 参数：
  /// - [key] 要取消的请求的唯一键,通常是文件键或请求ID
  ///
  /// 注意：该方法不会抛出异常,即使指定的键不存在
  void cancelRequest(String key) {
    // 获取与键关联的取消令牌
    final CancelToken? token = _tokens[key];

    // 只有当令牌存在且未被取消时才执行取消操作
    if (token != null && !token.isCancelled) {
      token.cancel('Request cancelled by user');
      _tokens.remove(key); // 移除已取消的令牌
    }
  }

  /// 移除Token
  ///
  /// 从管理器中移除指定键的取消令牌,而不取消请求。
  /// 这通常在请求完成或失败后调用,以清理资源。
  ///
  /// 与 [cancelRequest] 不同,该方法只移除令牌而不取消请求。
  /// 如果指定的键不存在,则不执行任何操作。
  ///
  /// 参数：
  /// - [key] 要移除的取消令牌的唯一键
  void removeToken(String key) {
    _tokens.remove(key);
  }

  /// 取消所有请求
  ///
  /// 取消所有当前管理的请求,并清空令牌存储。
  /// 这在需要快速取消所有进行中的请求时非常有用,例如在应用退出或用户取消所有操作时。
  ///
  /// 该方法会：
  /// 1. 遍历所有已注册的取消令牌
  /// 2. 取消所有未被取消的请求
  /// 3. 清空令牌存储,释放资源
  ///
  /// 注意：该方法不会抛出异常,即使取消过程中出现问题
  void cancelAll() {
    try {
      // 首先创建一份令牌的副本,避免在遍历过程中修改集合
      final List<CancelToken> tokensToCancel = List<CancelToken>.from(
        _tokens.values,
      );

      // 取消所有未被取消的请求
      for (final CancelToken token in tokensToCancel) {
        if (!token.isCancelled) {
          token.cancel('All requests cancelled');
        }
      }
    } catch (e) {
      // 捕获并记录取消过程中的错误,但不中断清理过程
      log('Error during cancelAll: $e', level: 1000);
    } finally {
      // 无论取消是否成功,都清空令牌存储
      _tokens.clear();
    }
  }

  /// 获取当前活跃的请求数量
  ///
  /// 返回当前管理的未取消请求的数量。
  /// 这对于监控和调试很有用,可以帮助跟踪活跃的请求数量。
  ///
  /// 返回当前活跃（未取消）的请求数量
  int getActiveRequestCount() {
    // 过滤出未取消的令牌
    return _tokens.values
        .where((CancelToken token) => !token.isCancelled)
        .length;
  }

  /// 获取所有活跃请求的键
  ///
  /// 返回当前所有活跃（未取消）请求的键的列表。
  /// 这对于调试和日志记录很有用。
  ///
  /// 返回当前活跃请求的键的列表
  List<String> getActiveRequestKeys() {
    return _tokens.entries
        .where(
          (MapEntry<String, CancelToken> entry) => !entry.value.isCancelled,
        )
        .map((MapEntry<String, CancelToken> entry) => entry.key)
        .toList();
  }

  /// 检查指定请求是否活跃
  ///
  /// 检查指定键的请求是否存在且未被取消。
  /// 这对于在发起新请求前检查相同请求是否已在进行中很有用。
  ///
  /// 参数：
  /// - [key] 要检查的请求的唯一键
  ///
  /// 返回布尔值,表示请求是否活跃
  bool isRequestActive(String key) {
    final CancelToken? token = _tokens[key];
    return token != null && !token.isCancelled;
  }
}
