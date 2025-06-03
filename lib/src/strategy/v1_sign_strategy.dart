import 'package:dart_aliyun_oss/src/config/config.dart';
import 'package:dart_aliyun_oss/src/interfaces/sign_strategy.dart';
import 'package:dart_aliyun_oss/src/strategy/v1_sign_utils.dart';

/// 阿里云OSS V1版本签名策略实现
///
/// 该类实现了 [IOSSSignStrategy] 接口，提供阿里云OSS V1版本的签名算法。
/// V1签名算法是阿里云OSS的旧版签名方式，基于 HMAC-SHA1 算法。
///
/// 主要特点：
/// - 使用 HMAC-SHA1 算法生成签名
/// - 签名字符串包含 HTTP 方法、内容类型、日期等信息
/// - 生成的授权头格式为: `OSS {AccessKeyId}:{Signature}`
///
/// 注意：对于新应用，建议使用更安全的 V4 签名算法。
class V1SignStrategy implements IOSSSignStrategy {
  /// 构造函数
  ///
  /// 创建一个新的 [V1SignStrategy] 实例。
  ///
  /// 参数：
  /// - [config] OSS 配置信息，包含访问密钥ID和密钥
  V1SignStrategy(this._config);

  /// OSS 配置信息
  ///
  /// 包含访问密钥ID、访问密钥等认证信息。
  final OSSConfig _config;

  /// 生成带签名的HTTP请求头
  ///
  /// 使用V1签名算法生成包含阿里云OSS认证签名的请求头。
  /// 该方法实现了 [IOSSSignStrategy] 接口中定义的 [signHeaders] 方法。
  ///
  /// 内部实现调用 [AliOssV1SignUtils.signedHeaders] 方法来生成签名头。
  ///
  /// 参数：
  /// - [method] HTTP请求方法（GET、PUT、POST等）
  /// - [uri] 请求的完整URI,包含查询参数
  /// - [bucket] OSS存储空间名称
  /// - [fileKey] OSS对象键（文件路径）
  /// - [headers] 原始请求头,将被扩展并签名
  /// - [contentType] 请求内容类型（可选）
  /// - [contentLength] 请求内容长度（可选）
  /// - [dateTime] 用于签名的时间,如果不提供则使用当前时间
  ///
  /// 返回包含完整签名头部的Map,可直接用于HTTP请求
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
    return AliOssV1SignUtils.signedHeaders(
      accessKeyId: _config.accessKeyId,
      accessKeySecret: _config.accessKeySecret,
      method: method,
      bucket: bucket,
      uri: uri,
      headers: headers,
      contentType: contentType,
      contentLength: contentLength,
      securityToken: _config.securityToken,
      dateTime: dateTime,
    );
  }
}
