import 'package:dio/dio.dart';

/// 阿里云OSS请求通用参数
///
/// 该类封装了各种OSS操作共用的请求参数,用于自定义请求行为。
/// 它允许在不同的OSS操作中使用一致的参数结构,简化了API设计。
///
/// 主要用途：
/// - 指定自定义的存储空间（覆盖全局配置）
/// - 设置请求时间（用于签名）
/// - 选择签名算法（V1或V4）
/// - 提供自定义请求选项（头部、超时等）
/// - 管理请求取消机制
/// - 监控下载进度
///
/// 示例：
/// ```dart
/// final params = OSSRequestParams(
///   bucketName: 'custom-bucket',
///   isV1Signature: true,
///   options: Options(headers: {'x-oss-object-acl': 'private'}),
///   onReceiveProgress: (count, total) {
///     print('进度: ${count/total * 100}%');
///   },
/// );
///
/// final response = await ossClient.getObject('example.txt', params: params);
/// ```
class OSSRequestParams {
  /// 存储空间名称
  ///
  /// 可选的自定义存储空间名称,如果提供,将覆盖全局配置中的默认存储空间。
  /// 这允许在同一个客户端实例中访问不同的存储空间。
  final String? bucketName;

  /// 请求时间
  ///
  /// 可选的请求时间,用于生成请求签名。如果不提供,将使用当前时间。
  /// 这在需要精确控制请求时间戳的场景中非常有用。
  final DateTime? dateTime;

  /// 是否使用V1签名算法
  ///
  /// 指定是否使用阿里云OSS V1版本的签名算法。
  /// - true: 使用V1签名算法（旧版）
  /// - false: 使用V4签名算法（默认,更安全）
  ///
  /// 大多数情况下应使用V4签名,除非需要兼容旧版系统。
  final bool isV1Signature;

  /// 请求配置选项
  ///
  /// Dio的请求配置选项,可用于设置自定义头部、超时、响应类型等。
  /// 这些选项将与签名头部合并,并应用于最终的HTTP请求。
  final Options? options;

  /// 用于取消请求的令牌
  ///
  /// 可选的取消令牌,用于取消正在进行的请求。
  /// 这在需要取消长时间运行的操作（如大文件上传或下载）时非常有用。
  final CancelToken? cancelToken;

  /// 响应接收进度回调
  ///
  /// 可选的进度回调函数,用于监控下载进度。
  /// 回调函数接收两个参数：已接收的字节数和总字节数。
  /// 这在需要在UI上显示下载进度条时非常有用。
  final ProgressCallback? onReceiveProgress;

  /// 构造函数
  ///
  /// 创建一个新的 [OSSRequestParams] 实例,包含指定的参数。
  ///
  /// 参数：
  /// - [bucketName] 可选的存储空间名称
  /// - [dateTime] 可选的请求时间
  /// - [isV1Signature] 是否使用V1签名算法,默认为 false（使用V4签名）
  /// - [options] 可选的Dio请求配置
  /// - [cancelToken] 可选的取消令牌
  /// - [onReceiveProgress] 可选的下载进度回调
  const OSSRequestParams({
    this.bucketName,
    this.dateTime,
    this.isV1Signature = false,
    this.options,
    this.cancelToken,
    this.onReceiveProgress,
  });

  /// 创建一个包含可选修改的新实例
  ///
  /// 这个方法允许基于现有实例创建一个新的 [OSSRequestParams] 实例,
  /// 只更新指定的属性,保持其他属性不变。
  ///
  /// 参数：
  /// - [bucketName] 新的存储空间名称
  /// - [dateTime] 新的请求时间
  /// - [isV1Signature] 新的签名算法设置
  /// - [options] 新的请求配置
  /// - [cancelToken] 新的取消令牌
  /// - [onReceiveProgress] 新的进度回调
  ///
  /// 返回一个新的 [OSSRequestParams] 实例
  ///
  /// 示例：
  /// ```dart
  /// final newParams = params.copyWith(
  ///   bucketName: 'another-bucket',
  ///   options: Options(headers: {'x-oss-object-acl': 'public-read'}),
  /// );
  /// ```
  OSSRequestParams copyWith({
    String? bucketName,
    DateTime? dateTime,
    bool? isV1Signature,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return OSSRequestParams(
      bucketName: bucketName ?? this.bucketName,
      dateTime: dateTime ?? this.dateTime,
      isV1Signature: isV1Signature ?? this.isV1Signature,
      options: options ?? this.options,
      cancelToken: cancelToken ?? this.cancelToken,
      onReceiveProgress: onReceiveProgress ?? this.onReceiveProgress,
    );
  }

  /// 返回实例的字符串表示
  ///
  /// 提供了一个可读性强的字符串表示,便于调试和日志记录。
  @override
  String toString() {
    return 'OSSRequestParams(bucketName: $bucketName, '
        'dateTime: $dateTime, '
        'isV1Signature: $isV1Signature, '
        'options: $options, '
        'cancelToken: ${cancelToken != null ? '已设置' : '未设置'}, '
        'onReceiveProgress: ${onReceiveProgress != null ? '已设置' : '未设置'})';
  }
}
