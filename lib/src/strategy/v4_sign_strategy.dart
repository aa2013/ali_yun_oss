import 'package:dart_aliyun_oss/src/config/config.dart';
import 'package:dart_aliyun_oss/src/interfaces/sign_strategy.dart';
import 'package:dart_aliyun_oss/src/strategy/v4_sign_utils.dart';

/// 阿里云OSS V4版本签名策略实现
///
/// 该类实现了 [IOSSSignStrategy] 接口，提供阿里云OSS V4版本的签名算法。
/// V4签名算法是阿里云OSS的新版签名方式，基于 AWS Signature V4 算法。
///
/// 主要特点：
/// - 使用 HMAC-SHA256 算法生成签名，比 V1 签名更安全
/// - 签名过程包含多个步骤，生成规范请求、签名范围和签名字符串
/// - 生成的授权头格式为: `OSS4-HMAC-SHA256 Credential={AccessKeyId}/{Date}/{Region}/oss/aliyun_v4_request, Signature={Signature}`
/// - 支持区域特定的签名，增强了安全性
///
/// 这是推荐的签名策略，对于新应用应优先使用 V4 签名算法。
class AliOssV4SignStrategy implements IOSSSignStrategy {
  /// OSS 配置信息
  ///
  /// 包含访问密钥ID、访问密钥、端点和区域等认证信息。
  final OSSConfig _config;

  /// 构造函数
  ///
  /// 创建一个新的 [AliOssV4SignStrategy] 实例。
  ///
  /// 参数：
  /// - [_config] OSS 配置信息，包含访问密钥ID、密钥、端点和区域
  AliOssV4SignStrategy(this._config);

  /// 生成带签名的HTTP请求头
  ///
  /// 使用V4签名算法生成包含阿里云OSS认证签名的请求头。
  /// 该方法实现了 [IOSSSignStrategy] 接口中定义的 [signHeaders] 方法。
  ///
  /// 内部实现调用 [AliOssV4SignUtils.signedHeaders] 方法来生成签名头。
  /// 与 V1 签名不同，V4 签名需要额外的区域和端点信息。
  ///
  /// 参数：
  /// - [method] HTTP请求方法（GET、PUT、POST等）
  /// - [uri] 请求的完整URI，包含查询参数
  /// - [bucket] OSS存储空间名称
  /// - [fileKey] OSS对象键（文件路径）
  /// - [headers] 原始请求头，将被扩展并签名
  /// - [contentType] 请求内容类型（可选）
  /// - [contentLength] 请求内容长度（可选）
  /// - [dateTime] 用于签名的时间，如果不提供则使用当前时间
  ///
  /// 返回包含完整签名头部的Map，可直接用于HTTP请求
  @override
  Map<String, dynamic> signHeaders({
    required String method,
    required Uri uri,
    required String bucket,
    required String fileKey,
    required Map<String, dynamic> headers,
    String? contentType,
    int? contentLength,
    DateTime? dateTime,
  }) {
    return AliOssV4SignUtils.signedHeaders(
      accessKeyId: _config.accessKeyId,
      accessKeySecret: _config.accessKeySecret,
      endpoint: _config.endpoint,
      region: _config.region,
      method: method,
      bucket: bucket,
      key: fileKey,
      uri: uri,
      headers: headers,
      dateTime: dateTime,
    );
  }
}
