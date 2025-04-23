import 'dart:io';

import 'package:dio/dio.dart';

import 'error_type.dart';

/// OSS 操作过程中发生的特定异常。
///
/// 该类封装了阿里云OSS操作过程中可能出现的各种错误，并提供了丰富的上下文信息以便于调试和错误处理。
/// 每个异常实例都包含一个 [OSSErrorType] 类型，用于分类错误，便于客户端代码进行错误处理和恢复。
///
/// 使用示例：
/// ```dart
/// try {
///   await ossClient.putObject(file, 'example.txt');
/// } catch (e) {
///   if (e is OSSException) {
///     print('错误类型: ${e.type}');
///     print('错误消息: ${e.message}');
///     print('状态码: ${e.statusCode}');
///     print('OSS错误码: ${e.ossErrorCode}');
///
///     // 根据错误类型处理
///     switch (e.type) {
///       case OSSErrorType.accessDenied:
///         // 处理访问被拒绝错误
///         break;
///       case OSSErrorType.notFound:
///         // 处理资源不存在错误
///         break;
///       // 处理其他错误类型...
///     }
///   }
/// }
/// ```
class OSSException implements Exception {
  /// 错误的类型
  ///
  /// 使用 [OSSErrorType] 枚举来分类错误，便于客户端代码进行错误处理和恢复。
  /// 可以使用 switch 语句根据错误类型执行不同的处理逻辑。
  final OSSErrorType type;

  /// 错误描述信息
  ///
  /// 提供了关于错误的详细文字描述，适合在日志中记录或展示给用户。
  /// 这个字段始终会被设置，并包含关于错误的有用信息。
  final String message;

  /// 原始的 Dio 响应对象 (如果可用)
  ///
  /// 当错误与 HTTP 响应相关时，这个字段包含原始的 [Response] 对象。
  /// 可以从中获取状态码、响应头、响应体等详细信息。
  /// 在网络错误或请求未到达服务器时，该字段可能为 null。
  final Response? response;

  /// 导致错误的原始异常 (如果可用)
  ///
  /// 当 [OSSException] 是由另一个异常引起的，这个字段包含原始的异常对象。
  /// 常见的原始异常类型包括 [DioException]、[FileSystemException] 等。
  /// 这对于调试和错误分析非常有用。
  final Object? originalError;

  /// 导致错误的请求选项 (如果可用)
  ///
  /// 包含导致错误的请求的详细信息，如 URL、方法、头部等。
  /// 当错误发生在请求发送前或请求过程中时，这个字段包含 [RequestOptions] 对象。
  /// 如果错误与特定请求无关，该字段可能为 null。
  final RequestOptions? requestOptions;

  /// OSS 返回的特定错误码 (从响应体解析，如果可用)
  ///
  /// 当阿里云OSS服务器返回错误时，会提供一个特定的错误码，如 'AccessDenied'、'NoSuchKey' 等。
  /// 这个字段包含从 XML 响应中提取的错误码，可用于更精确地识别错误原因。
  /// 如果响应中没有错误码或无法解析，该字段为 null。
  final String? ossErrorCode;

  /// HTTP 状态码 (从响应提取，如果可用)
  ///
  /// 当错误与 HTTP 响应相关时，这个属性提供了 HTTP 状态码，如 403（禁止访问）、404（不存在）等。
  /// 这是从 [response] 对象中提取的便捷属性。
  /// 如果 [response] 为 null，该属性也为 null。
  int? get statusCode => response?.statusCode;

  /// 创建一个新的 OSS 异常
  ///
  /// 构造函数接受各种上下文信息，以提供关于错误的详细信息。
  /// 只有 [type] 和 [message] 是必需的，其他参数是可选的，可以根据错误情况提供。
  ///
  /// 参数：
  /// - [type] 错误类型，使用 [OSSErrorType] 枚举来分类错误
  /// - [message] 错误描述信息，提供关于错误的详细文字描述
  /// - [response] 原始的 Dio 响应对象（如果可用）
  /// - [originalError] 导致错误的原始异常（如果可用）
  /// - [requestOptions] 导致错误的请求选项（如果可用）
  /// - [ossErrorCode] OSS 返回的特定错误码（如果可用）
  ///
  /// 示例：
  /// ```dart
  /// throw OSSException(
  ///   type: OSSErrorType.accessDenied,
  ///   message: '没有访问权限',
  ///   response: dioResponse,
  ///   ossErrorCode: 'AccessDenied',
  /// );
  /// ```
  const OSSException({
    required this.type,
    required this.message,
    this.response,
    this.originalError,
    this.requestOptions,
    this.ossErrorCode,
  });

  /// 从 DioException 创建 OSSException
  ///
  /// 这个工厂方法提供了一种便捷的方式，将 [DioException] 转换为更特定的 [OSSException]。
  /// 它会尝试从响应中提取 OSS 错误码，并根据错误类型和状态码映射到适当的 [OSSErrorType]。
  ///
  /// 参数：
  /// - [error] 原始的 DioException 对象
  /// - [message] 可选的自定义错误消息，如果不提供，将使用 DioException 的消息
  /// - [defaultType] 当无法确定错误类型时使用的默认类型
  ///
  /// 返回一个新的 [OSSException] 实例
  ///
  /// 示例：
  /// ```dart
  /// try {
  ///   // 执行 OSS 操作
  /// } catch (e) {
  ///   if (e is DioException) {
  ///     throw OSSException.fromDioException(e, message: '上传文件失败');
  ///   }
  ///   rethrow;
  /// }
  /// ```
  factory OSSException.fromDioException(
    DioException error, {
    String? message,
    OSSErrorType defaultType = OSSErrorType.network,
  }) {
    // 尝试从响应中提取 OSS 错误码
    String? ossErrorCode;
    if (error.response?.data is String) {
      final String data = error.response!.data as String;
      if (data.contains('<Error>') && data.contains('<Code>')) {
        final RegExpMatch? match = RegExp(
          r'<Code>(.*?)</Code>',
        ).firstMatch(data);
        ossErrorCode = match?.group(1);
      }
    }

    // 确定错误类型
    OSSErrorType errorType;
    if (error.type == DioExceptionType.cancel) {
      errorType = OSSErrorType.requestCancelled;
    } else if (error.response?.statusCode == 403) {
      errorType = OSSErrorType.accessDenied;
    } else if (error.response?.statusCode == 404) {
      errorType = OSSErrorType.notFound;
    } else if (error.response?.statusCode != null &&
        error.response!.statusCode! >= 500) {
      errorType = OSSErrorType.serverError;
    } else {
      errorType = defaultType;
    }

    return OSSException(
      type: errorType,
      message: message ?? error.message ?? '网络请求错误',
      response: error.response,
      originalError: error,
      requestOptions: error.requestOptions,
      ossErrorCode: ossErrorCode,
    );
  }

  /// 从其他异常创建 OSSException
  ///
  /// 这个工厂方法提供了一种便捷的方式，将任意异常转换为 [OSSException]。
  /// 它会尝试根据异常类型确定适当的 [OSSErrorType]。
  ///
  /// 参数：
  /// - [error] 原始异常对象
  /// - [message] 可选的自定义错误消息，如果不提供，将使用原始异常的字符串表示
  /// - [type] 错误类型，默认为 [OSSErrorType.unknown]
  ///
  /// 返回一个新的 [OSSException] 实例
  ///
  /// 示例：
  /// ```dart
  /// try {
  ///   // 执行操作
  /// } catch (e) {
  ///   throw OSSException.fromError(e, message: '操作失败', type: OSSErrorType.fileSystem);
  /// }
  /// ```
  factory OSSException.fromError(
    Object error, {
    String? message,
    OSSErrorType type = OSSErrorType.unknown,
  }) {
    // 如果已经是 OSSException，直接返回
    if (error is OSSException) {
      return error;
    }

    // 如果是 DioException，使用专用的工厂方法
    if (error is DioException) {
      return OSSException.fromDioException(error, message: message);
    }

    // 根据异常类型确定错误类型
    OSSErrorType errorType = type;
    if (error is FileSystemException) {
      errorType = OSSErrorType.fileSystem;
    } else if (error is FormatException) {
      errorType = OSSErrorType.invalidResponse;
    } else if (error is ArgumentError) {
      errorType = OSSErrorType.invalidArgument;
    }

    return OSSException(
      type: errorType,
      message: message ?? error.toString(),
      originalError: error,
    );
  }

  @override
  /// 返回异常的字符串表示
  ///
  /// 生成一个格式化的字符串，包含错误类型、状态码、错误码、错误消息以及其他相关信息。
  /// 这个方法被用于日志记录和调试输出。
  String toString() {
    final StringBuffer sb = StringBuffer();
    sb.write('OSSException [${type.name}]');
    if (statusCode != null) {
      sb.write(' (Status: $statusCode');
      if (ossErrorCode != null) {
        sb.write(', Code: $ossErrorCode');
      }
      sb.write(')');
    }
    sb.write(': $message');
    if (requestOptions != null) {
      sb.write('\n  Request: ${requestOptions?.method} ${requestOptions?.uri}');
    }
    if (originalError != null) {
      sb.write('\n  Original Error: ${originalError.runtimeType}');
      // 可以选择性地包含原始错误的 toString()，但可能过长
      // sb.write('\n  Original Error Details: $originalError');
    }
    return sb.toString();
  }
}
