import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// 阿里云OSS V1版本签名工具类
///
/// 用于生成阿里云OSS V1版本的签名和授权头信息。
/// 该类实现了基于 HMAC-SHA1 算法的签名生成过程，符合阿里云OSS API规范。
///
/// V1签名算法的主要步骤：
/// 1. 构建规范化的OSS头部（CanonicalizedOSSHeaders）
/// 2. 构建规范化的资源路径（CanonicalizedResource）
/// 3. 组合各元素构建待签名字符串
/// 4. 使用 HMAC-SHA1 算法计算签名并进行 Base64 编码
/// 5. 生成最终的授权头格式：`OSS {AccessKeyId}:{Signature}`
///
/// 注意：该类提供的是静态工具方法，不应该被实例化。
/// 对于新应用，建议使用更安全的 V4 签名算法。
class AliOssV1SignUtils {
  // 私有构造函数，防止实例化
  AliOssV1SignUtils._();

  /// OSS头部前缀常量
  static const String _ossHeaderPrefix = 'x-oss-';

  /// 生成阿里云OSS V1签名所需的Authorization头
  ///
  /// 根据提供的参数生成符合阿里云OSS V1版本规范的授权头字符串。
  /// 该方法实现了完整的V1签名过程,包括构建规范化头部、资源路径和计算签名。
  ///
  /// 签名过程：
  /// 1. 处理时间参数并格式化为 HTTP 日期格式
  /// 2. 处理安全令牌（如果提供）
  /// 3. 构建规范化的OSS头部
  /// 4. 构建规范化的资源路径
  /// 5. 组合各元素构建待签名字符串
  /// 6. 计算HMAC-SHA1签名并进行 Base64 编码
  /// 7. 生成最终的授权头格式：`OSS {AccessKeyId}:{Signature}`
  ///
  /// 参数：
  /// - [accessKeyId] 阿里云访问密钥ID
  /// - [accessKeySecret] 阿里云访问密钥
  /// - [method] HTTP方法（大写,如：PUT/GET）
  /// - [bucket] OSS存储空间名称
  /// - [uri] 完整的请求URI（用于解析查询参数）
  /// - [ossHeaders] 参与签名计算的自定义OSS头（可选）
  /// - [contentMd5] 请求体的MD5值（可选）
  /// - [contentType] 请求体的Content-Type（可选）
  /// - [securityToken] 安全令牌（STS临时凭证需要）
  /// - [dateTime] 指定请求时间（可选,默认为当前时间）
  ///
  /// 返回完整的授权头字符串,格式为 `OSS {AccessKeyId}:{Signature}`
  ///
  /// 示例：
  /// ```dart
  /// final authHeader = AliOssV1SignUtils.signature(
  ///   accessKeyId: 'your-access-key-id',
  ///   accessKeySecret: 'your-access-key-secret',
  ///   method: 'GET',
  ///   bucket: 'example-bucket',
  ///   uri: Uri.parse('https://example-bucket.oss-cn-hangzhou.aliyuncs.com/example.txt'),
  /// );
  /// // 结果如：'OSS your-access-key-id:Base64EncodedSignature'
  /// ```
  static String signature({
    required String accessKeyId,
    required String accessKeySecret,
    required String method,
    required String bucket,
    required Uri uri,
    Map<String, dynamic>? ossHeaders,
    String? contentMd5,
    String? contentType,
    String? securityToken,
    DateTime? dateTime,
    int? expires,
  }) {
    // 1. 处理时间参数
    final DateTime now = dateTime ?? DateTime.now().toUtc();
    final String date = HttpDate.format(now);

    // 处理安全令牌
    final Map<String, dynamic> headers = {...ossHeaders ?? {}};
    if (securityToken != null) {
      headers['$_ossHeaderPrefix-security-token'] = securityToken;
    }

    // 2. 构建规范OSS头
    final canonicalizedHeaders = _buildCanonicalizedHeaders(headers);

    // 3. 构建规范资源
    final canonicalizedResource = _buildCanonicalizedResource(uri, bucket);

    // 4. 构建待签名字符串
    String dateOrExpires;
    if (expires != null) {
      // 如果提供了过期时间，使用过期时间戳
      final int expiresTimestamp =
          (now.millisecondsSinceEpoch ~/ 1000) + expires;
      dateOrExpires = expiresTimestamp.toString();
    } else {
      // 否则使用日期
      dateOrExpires = date;
    }

    final stringToSign = [
      method.toUpperCase(),
      contentMd5 ?? '',
      contentType ?? '',
      dateOrExpires,
      canonicalizedHeaders,
      canonicalizedResource,
    ].join('\n');

    // 5. 计算签名
    final signature = _calculateSignature(accessKeySecret, stringToSign);

    // 6. 构建Authorization头
    return 'OSS $accessKeyId:$signature';
  }

  /// 生成包含签名的完整HTTP请求头
  ///
  /// 根据提供的参数生成包含阿里云OSS V1签名的完整HTTP请求头。
  /// 该方法不仅生成授权头,还会处理其他必要的头部,如内容类型、内容长度和日期等。
  ///
  /// 处理流程：
  /// 1. 从原始头部中提取并分离所有 x-oss-* 头部
  /// 2. 处理时间参数并格式化为 HTTP 日期格式
  /// 3. 调用 [signature] 方法生成授权头
  /// 4. 组装最终的请求头,包含所有原始头部、OSS头部、内容类型、内容长度、日期和授权头
  ///
  /// 参数：
  /// - [accessKeyId] 阿里云访问密钥ID
  /// - [accessKeySecret] 阿里云访问密钥
  /// - [method] HTTP方法（大写,如：PUT/GET）
  /// - [bucket] OSS存储空间名称
  /// - [uri] 完整的请求URI
  /// - [headers] 原始HTTP请求头（可选）
  /// - [contentMd5] 请求体的MD5值（可选）
  /// - [contentType] 请求体的Content-Type（可选）
  /// - [contentLength] 请求体的长度（可选）
  /// - [securityToken] 安全令牌（STS临时凭证需要）
  /// - [dateTime] 指定请求时间（可选,默认为当前时间）
  ///
  /// 返回包含完整签名头部的Map,可直接用于 HTTP 请求
  ///
  /// 示例：
  /// ```dart
  /// final headers = AliOssV1SignUtils.signedHeaders(
  ///   accessKeyId: 'your-access-key-id',
  ///   accessKeySecret: 'your-access-key-secret',
  ///   method: 'PUT',
  ///   bucket: 'example-bucket',
  ///   uri: Uri.parse('https://example-bucket.oss-cn-hangzhou.aliyuncs.com/example.txt'),
  ///   contentType: 'text/plain',
  ///   contentLength: 1024,
  ///   headers: {'x-oss-meta-author': 'example'},
  /// );
  /// // 结果包含如下头部：
  /// // {
  /// //   'x-oss-meta-author': 'example',
  /// //   'content-type': 'text/plain',
  /// //   'content-length': 1024,
  /// //   'Date': 'Wed, 15 Jun 2023 12:30:45 GMT',
  /// //   'Authorization': 'OSS your-access-key-id:Base64EncodedSignature'
  /// // }
  /// ```
  static Map<String, dynamic> signedHeaders({
    required String accessKeyId,
    required String accessKeySecret,
    required String method,
    required String bucket,
    required Uri uri,
    Map<String, dynamic>? headers,
    String? contentMd5,
    String? contentType,
    int? contentLength,
    String? securityToken,
    DateTime? dateTime,
  }) {
    // 若有 header,从 header 中提取 x-oss-* 头并移除
    final Map<String, dynamic> ossHeaders = {};
    final Map<String, dynamic> resultHeaders = {...headers ?? {}};

    if (resultHeaders.isNotEmpty) {
      final keysToRemove = <String>[];
      resultHeaders.forEach((key, value) {
        final lowerKey = key.toLowerCase();
        if (lowerKey.startsWith(_ossHeaderPrefix)) {
          ossHeaders[lowerKey] = value;
          keysToRemove.add(key);
        }
      });

      for (final key in keysToRemove) {
        resultHeaders.remove(key);
      }
    }

    // 处理时间参数
    final DateTime now = dateTime ?? DateTime.now().toUtc();
    final date = HttpDate.format(now);

    // 构建OSS签名
    final String sign = signature(
      accessKeyId: accessKeyId,
      accessKeySecret: accessKeySecret,
      method: method,
      uri: uri,
      bucket: bucket,
      ossHeaders: ossHeaders,
      contentType: contentType,
      contentMd5: contentMd5,
      securityToken: securityToken,
      dateTime: now,
      expires: null, // 不使用过期时间
    );

    // 组装最终请求头
    final Map<String, dynamic> finalHeaders = {
      ...ossHeaders,
      if (contentType != null) 'content-type': contentType,
      if (contentLength != null) 'content-length': contentLength,
      'Date': date,
      'Authorization': sign,
      ...resultHeaders,
    };

    return finalHeaders;
  }

  /// 构建规范化的OSS头部字符串
  ///
  /// 将所有以 x-oss- 开头的头部按照字典序排序,并以 `key:value` 格式拼接成字符串。
  /// 多个头部之间使用换行符分隔。
  ///
  /// 处理流程：
  /// 1. 过滤出所有以 x-oss- 开头的头部
  /// 2. 将头部名转换为小写,并对值进行去除首尾空格处理
  /// 3. 按照头部名的字典序排序
  /// 4. 将排序后的头部以 `key:value` 格式拼接,并用换行符分隔
  ///
  /// 参数：
  /// - [headers] 要处理的头部映射
  ///
  /// 返回规范化的OSS头部字符串,如果没有相关头部则返回空字符串
  static String _buildCanonicalizedHeaders(Map<String, dynamic> headers) {
    if (headers.isEmpty) return '';

    final entries =
        headers.entries
            .where(
              (entry) => entry.key.toLowerCase().startsWith(_ossHeaderPrefix),
            )
            .map(
              (entry) => MapEntry(
                entry.key.toLowerCase(),
                (entry.value?.toString() ?? '').trim(),
              ),
            )
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    final buffer = StringBuffer();
    for (var i = 0; i < entries.length; i++) {
      if (i > 0) buffer.write('\n');
      buffer.write('${entries[i].key}:${entries[i].value}');
    }

    return buffer.toString();
  }

  /// 构建规范化的资源路径字符串
  ///
  /// 生成符合阿里云OSS V1签名规范的规范化资源字符串。
  /// 格式为: `/bucket/object?param1=value1&param2=value2`
  ///
  /// 处理流程：
  /// 1. 组合存储空间名称和对象路径
  /// 2. 如果有查询参数,则添加到资源路径后
  /// 3. 对生成的路径进行 URL 解码,确保特殊字符正确处理
  ///
  /// 参数：
  /// - [uri] 请求的完整URI,包含路径和查询参数
  /// - [bucket] OSS存储空间名称
  ///
  /// 返回规范化的资源路径字符串
  static String _buildCanonicalizedResource(Uri uri, String bucket) {
    // 检查 uri.path 是否已经包含 bucket 名称
    String path = uri.path;
    if (path.startsWith('/$bucket/')) {
      // 如果路径已经包含 bucket 名称,则不需要再添加
      return Uri.decodeFull(
        '$path${uri.query.isNotEmpty ? '?' : ''}${uri.query}',
      );
    } else {
      // 否则,添加 bucket 名称
      return Uri.decodeFull(
        '/$bucket$path${uri.query.isNotEmpty ? '?' : ''}${uri.query}',
      );
    }
  }

  /// 计算HMAC-SHA1签名并进行Base64编码
  ///
  /// 使用HMAC-SHA1算法对待签名字符串进行签名,并将结果进行 Base64 编码。
  /// 这是阿里云OSS V1签名算法的核心步骤。
  ///
  /// 处理流程：
  /// 1. 使用访问密钥作为 HMAC-SHA1 算法的密钥
  /// 2. 对待签名字符串进行 HMAC-SHA1 计算,生成摘要
  /// 3. 将摘要进行 Base64 编码,生成最终的签名字符串
  ///
  /// 参数：
  /// - [secret] 阿里云访问密钥,用作 HMAC 算法的密钥
  /// - [stringToSign] 待签名的字符串,包含方法、内容类型、日期等信息
  ///
  /// 返回 Base64 编码后的签名字符串
  static String _calculateSignature(String secret, String stringToSign) {
    // 使用 HMAC-SHA1 算法计算签名
    final Hmac hmac = Hmac(sha1, utf8.encode(secret));
    final Digest digest = hmac.convert(utf8.encode(stringToSign));

    // 对签名进行 Base64 编码
    return base64.encode(digest.bytes);
  }

  /// 生成包含签名的URL
  ///
  /// 根据提供的参数生成包含阿里云OSS V1签名的URL。
  /// 该方法将签名信息作为URL的查询参数，可以直接用于访问OSS资源。
  /// 生成的URL格式为：`https://{bucket}.{endpoint}/{key}?OSSAccessKeyId={accessKeyId}&Expires={expires}&Signature={signature}`
  ///
  /// 签名过程：
  /// 1. 处理时间参数并计算过期时间戳
  /// 2. 构建规范资源路径 `/{bucket}/{key}`
  /// 3. 构建待签名字符串，格式为：
  ///    `{METHOD}\n{CONTENT-MD5}\n{CONTENT-TYPE}\n{EXPIRES}\n{RESOURCE}`
  /// 4. 使用HMAC-SHA1算法计算签名并进行Base64编码
  /// 5. 构建最终URL，包含必要的查询参数（OSSAccessKeyId、Expires、Signature）
  /// 6. 添加安全令牌和其他自定义参数（如果有）
  ///
  /// 参数：
  /// - [accessKeyId] 阿里云访问密钥ID
  /// - [accessKeySecret] 阿里云访问密钥
  /// - [endpoint] 阿里云OSS端点（如：oss-cn-hangzhou.aliyuncs.com）
  /// - [method] HTTP方法（大写，如：GET/PUT/POST/DELETE）
  /// - [bucket] OSS存储空间名称
  /// - [key] 对象键（文件路径）
  /// - [expires] 签名过期时间（秒），默认3600秒（1小时）
  /// - [ossHeaders] 参与签名计算的自定义OSS头（可选）
  /// - [contentMd5] 请求体的MD5值（可选）
  /// - [contentType] 请求体的Content-Type（可选）
  /// - [securityToken] 安全令牌（STS临时凭证需要）
  /// - [dateTime] 指定请求时间（可选，默认为当前时间）
  ///
  /// 返回包含签名的完整URL（Uri对象）
  ///
  /// 示例：
  /// ```dart
  /// final uri = AliOssV1SignUtils.signatureUri(
  ///   accessKeyId: 'your-access-key-id',
  ///   accessKeySecret: 'your-access-key-secret',
  ///   endpoint: 'oss-cn-hangzhou.aliyuncs.com',
  ///   method: 'GET',
  ///   bucket: 'example-bucket',
  ///   key: 'example.txt',
  ///   expires: 3600, // 1小时后过期
  /// );
  ///
  /// // 使用生成的URL访问OSS资源
  /// final response = await http.get(uri);
  /// ```
  static Uri signatureUri({
    required String accessKeyId,
    required String accessKeySecret,
    required String endpoint,
    required String method,
    required String bucket,
    required String key,
    int expires = 3600,
    Map<String, dynamic>? ossHeaders,
    String? contentMd5,
    String? contentType,
    String? securityToken,
    DateTime? dateTime,
  }) {
    // 1. 处理时间参数
    final DateTime now = dateTime ?? DateTime.now().toUtc();
    final int expiresTimestamp = (now.millisecondsSinceEpoch ~/ 1000) + expires;

    // 2. 构建基础URL
    final String host = '$bucket.$endpoint';
    final String path = '/$key';

    // 3. 构建规范资源路径
    // 根据阿里云官方示例，规范资源路径应该是 /{bucket}/{key}
    // 注意：这里不包含查询参数
    final String canonicalizedResource = '/$bucket/$key';

    // 4. 构建待签名字符串
    // 根据阿里云文档和成功的简化版实现，签名字符串的格式应该是：
    // VERB + "\n" + CONTENT-MD5 + "\n" + CONTENT-TYPE + "\n" + EXPIRES + "\n" + CanonicalizedResource
    final String stringToSign = [
      method.toUpperCase(),
      contentMd5 ?? '',
      contentType ?? '',
      expiresTimestamp.toString(),
      canonicalizedResource,
    ].join('\n');

    // 5. 计算签名
    final String signature = _calculateSignature(accessKeySecret, stringToSign);

    // 6. 构建查询参数
    final Map<String, String> queryParams = {
      'OSSAccessKeyId': accessKeyId,
      'Expires': expiresTimestamp.toString(),
      'Signature': signature,
    };

    // 7. 添加安全令牌（如果有）
    if (securityToken != null) {
      queryParams['security-token'] = securityToken;
    }

    // 8. 添加其他查询参数（如果有）
    if (ossHeaders != null && ossHeaders.isNotEmpty) {
      ossHeaders.forEach((key, value) {
        if (key.startsWith(_ossHeaderPrefix)) {
          // 将 x-oss- 前缀的头部添加为查询参数
          final paramKey = key.replaceAll('$_ossHeaderPrefix-', '');
          queryParams[paramKey] = value.toString();
        }
      });
    }

    // 9. 构建最终URL
    // 使用 Uri 构造函数直接构建 URL，与简化版实现一致
    final Uri uri = Uri(
      scheme: 'https',
      host: host,
      path: path,
      queryParameters: queryParams,
    );

    return uri;
  }
}
