import 'package:dart_aliyun_oss/src/client/client.dart';
import 'package:dart_aliyun_oss/src/interfaces/service.dart';
import 'package:dart_aliyun_oss/src/strategy/strategy.dart';

/// SignedUrlImpl 是阿里云 OSS 签名 URL 生成操作的实现
///
/// 该 mixin 提供了生成带有签名的 OSS URL 的功能,主要特点：
/// - 支持 V1 和 V4 签名算法
/// - 支持自定义过期时间
/// - 支持自定义请求头和查询参数
/// - 支持 STS 临时凭证
///
/// 使用注意：
/// 1. 该 mixin 需要与 IOSSService 一起使用
/// 2. 实现类需要提供 config 成员
/// 3. V1 签名适用于大多数场景,V4 签名提供更高的安全性
/// 4. 生成的 URL 有效期由 expires 参数控制,默认为 3600 秒（1小时）
///
/// 示例:
/// ```dart
/// // 生成带有 V1 签名的 URL
/// final url = client.signedUrl(
///   'example.txt',
///   method: 'GET',
///   expires: 7200, // 2小时有效期
///   isV1Signature: true,
/// );
///
/// // 生成带有 V4 签名的 URL
/// final url = client.signedUrl(
///   'example.txt',
///   method: 'PUT',
///   expires: 3600,
///   isV1Signature: false,
/// );
/// ```
mixin SignedUrlImpl on IOSSService {
  /// 生成带有签名的 OSS URL
  ///
  /// 根据提供的参数生成包含阿里云 OSS 签名的 URL,可用于临时授权访问 OSS 资源。
  /// 支持 V1 和 V4 签名算法,通过 [isV1Signature] 参数切换。
  ///
  /// 签名算法对比：
  /// - V1 签名（[isV1Signature]=true）：基于 HMAC-SHA1,生成的 URL 格式较简单
  /// - V4 签名（[isV1Signature]=false）：基于 HMAC-SHA256,提供更高的安全性
  ///
  /// 参数：
  /// - [fileKey] OSS 对象键（文件路径）
  /// - [method] HTTP 请求方法（GET、PUT、POST 等）,默认为 GET
  /// - [bucketName] 存储空间名称,如果不提供则使用配置中的默认值
  /// - [expires] 签名过期时间（秒）,默认 3600 秒（1小时）
  /// - [headers] 自定义请求头,将参与签名计算
  /// - [additionalHeaders] 需要参与签名的额外头名称集合（仅 V4 签名使用）
  /// - [dateTime] 用于签名的时间,如果不提供则使用当前时间
  /// - [isV1Signature] 是否使用 V1 签名算法,默认为 true（使用 V1 签名）
  ///
  /// 返回包含签名的完整 URL 字符串
  ///
  /// 注意事项：
  /// - 使用 V1 签名时,URL 有效期最长为 7 天（604800 秒）
  /// - 使用 STS 临时凭证时,URL 有效期不能超过 STS 凭证的有效期
  /// - 生成的 URL 可以直接在浏览器中访问,也可以在 HTTP 客户端中使用
  /// - 对于上传操作（PUT/POST）,需要确保请求的 Content-Type 与签名时一致
  String signedUrl(
    String fileKey, {
    String method = 'GET',
    String? bucketName,
    int expires = 3600,
    Map<String, dynamic>? headers,
    Set<String>? additionalHeaders,
    DateTime? dateTime,
    bool isV1Signature = true,
  }) {
    // 验证必要参数
    if (fileKey.isEmpty) {
      throw ArgumentError('fileKey 不能为空');
    }
    if (method.isEmpty) {
      throw ArgumentError('method 不能为空');
    }
    if (expires < 1) {
      throw ArgumentError('expires 必须大于 0');
    }

    // 使用配置中的默认值
    final OSSClient client = this as OSSClient;
    final String bucket = bucketName ?? client.config.bucketName;
    final String accessKeyId = client.config.accessKeyId;
    final String accessKeySecret = client.config.accessKeySecret;
    final String endpoint = client.config.endpoint;
    final String? securityToken = client.config.securityToken;

    // 根据签名算法选择不同的实现
    if (isV1Signature) {
      // 使用 V1 签名算法
      final Uri uri = AliOssV1SignUtils.signatureUri(
        accessKeyId: accessKeyId,
        accessKeySecret: accessKeySecret,
        endpoint: endpoint,
        method: method,
        bucket: bucket,
        key: fileKey,
        expires: expires,
        ossHeaders: headers,
        securityToken: securityToken,
        dateTime: dateTime,
      );
      return uri.toString();
    } else {
      // 使用 V4 签名算法
      // 验证区域信息
      final String region = client.config.region;
      if (region.isEmpty) {
        throw ArgumentError('使用 V4 签名时,config.region 不能为空');
      }

      final Uri uri = AliOssV4SignUtils.signatureUri(
        accessKeyId: accessKeyId,
        accessKeySecret: accessKeySecret,
        endpoint: endpoint,
        region: region,
        method: method,
        bucket: bucket,
        key: fileKey,
        expires: expires,
        headers: headers,
        additionalHeaders: additionalHeaders,
        securityToken: securityToken,
        dateTime: dateTime,
      );
      return uri.toString();
    }
  }
}
