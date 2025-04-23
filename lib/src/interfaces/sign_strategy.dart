/// 阿里云OSS签名策略接口
///
/// 该接口定义了生成阿里云OSS请求签名的方法。
/// 不同的实现类可以提供不同版本的签名算法，如V1签名和V4签名。
///
/// 当前支持的实现类：
/// - [AliOssV1SignStrategy] - 实现阿里云OSS V1版本签名算法
/// - [AliOssV4SignStrategy] - 实现阿里云OSS V4版本签名算法（更安全）
///
/// 客户端会根据配置或请求需求选择适当的签名策略。
abstract class IOSSSignStrategy {
  /// 生成带签名的HTTP请求头
  ///
  /// 根据提供的参数生成包含阿里云OSS认证签名的请求头。
  /// 不同的签名策略实现会使用不同的签名算法和头部格式。
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
  Map<String, dynamic> signHeaders({
    required String method,
    required Uri uri,
    required String bucket,
    required String fileKey,
    required Map<String, dynamic> headers,
    String? contentType,
    int? contentLength,
    DateTime? dateTime,
  });
}
