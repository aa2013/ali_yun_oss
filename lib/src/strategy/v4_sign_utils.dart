import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

/// 阿里云OSS V4版本签名工具类
///
/// 用于生成阿里云OSS V4版本的签名和授权头信息，符合阿里云OSS API规范。
/// 该类实现了基于 HMAC-SHA256 算法的签名生成过程，提供比 V1 签名更安全的认证机制。
///
/// V4签名算法的主要步骤：
/// 1. 构建规范化的URI、查询参数和头部
/// 2. 组合各元素构建规范化请求
/// 3. 构建签名范围和待签名字符串
/// 4. 生成派生密钥并计算 HMAC-SHA256 签名
/// 5. 生成最终的授权头格式：`OSS4-HMAC-SHA256 Credential={AccessKeyId}/{Date}/{Region}/oss/aliyun_v4_request, Signature={Signature}`
///
/// 与 V1 签名相比，V4 签名的主要优势：
/// - 使用更安全的 HMAC-SHA256 算法
/// - 包含区域信息，增强了安全性
/// - 支持更多的头部参与签名
/// - 签名过程更复杂，更难被破解
///
/// 注意：该类提供的是静态工具方法，不应该被实例化。
/// 对于新应用，建议优先使用 V4 签名算法。
class AliOssV4SignUtils {
  // 私有构造函数，防止实例化
  AliOssV4SignUtils._();

  /// OSS头部前缀常量
  static const String _ossHeaderPrefix = 'x-oss-';

  /// 默认需要签名的头部
  static const _defaultSignHeaders = {
    'x-oss-date',
    'x-oss-content-sha256',
    'content-type',
  };

  /// 生成阿里云OSS V4签名所需的Authorization头
  ///
  /// 根据提供的参数生成符合阿里云OSS V4版本规范的授权头字符串。
  /// 该方法实现了完整的V4签名过程，包括构建规范化请求、签名范围和计算签名。
  ///
  /// 签名过程：
  /// 1. 处理时间参数并格式化为 ISO8601 格式
  /// 2. 设置必要的请求头，如 x-oss-content-sha256 和 x-oss-date
  /// 3. 处理安全令牌（如果提供）
  /// 4. 构建规范化的URI、查询参数和头部
  /// 5. 处理额外需要签名的头部
  /// 6. 构建规范化请求字符串
  /// 7. 构建签名范围和待签名字符串
  /// 8. 计算HMAC-SHA256签名
  /// 9. 生成最终的授权头格式
  ///
  /// 参数：
  /// - [accessKeyId] 阿里云访问密钥ID
  /// - [accessKeySecret] 阿里云访问密钥
  /// - [endpoint] 阿里云OSS端点（如：oss-cn-hangzhou.aliyuncs.com）
  /// - [region] 区域代码（如：cn-hangzhou）
  /// - [method] HTTP方法（大写，如：PUT/GET）
  /// - [bucket] OSS存储空间名称
  /// - [key] 对象键（文件路径）
  /// - [uri] 完整的请求URI（用于解析查询参数）
  /// - [headers] 请求头集合，将被用于签名计算
  /// - [additionalHeaders] 需要参与签名的额外头名称集合，默认为空集合
  /// - [securityToken] 安全令牌（STS临时凭证需要）
  /// - [dateTime] 指定请求时间（可选，默认为当前时间）
  ///
  /// 返回完整的授权头字符串，格式为 `OSS4-HMAC-SHA256 Credential={AccessKeyId}/{Date}/{Region}/oss/aliyun_v4_request, Signature={Signature}`
  ///
  /// 示例：
  /// ```dart
  /// final authHeader = AliOssV4SignUtils.signature(
  ///   accessKeyId: 'your-access-key-id',
  ///   accessKeySecret: 'your-access-key-secret',
  ///   endpoint: 'oss-cn-hangzhou.aliyuncs.com',
  ///   region: 'cn-hangzhou',
  ///   method: 'GET',
  ///   bucket: 'example-bucket',
  ///   key: 'example.txt',
  ///   uri: Uri.parse('https://example-bucket.oss-cn-hangzhou.aliyuncs.com/example.txt'),
  ///   headers: {'content-type': 'application/octet-stream'},
  /// );
  /// ```
  static String signature({
    required String accessKeyId,
    required String accessKeySecret,
    required String endpoint,
    required String region,
    required String method,
    required String bucket,
    required String key,
    required Uri uri,
    required Map<String, dynamic> headers,
    Set<String> additionalHeaders = const {},
    String? securityToken,
    DateTime? dateTime,
  }) {
    // 创建headers的副本，避免修改原始map
    final Map<String, dynamic> headersToSign = <String, dynamic>{...headers};

    // 1. 处理时间相关参数
    final DateTime now = dateTime ?? DateTime.now().toUtc();
    final String signDate = DateFormat('yyyyMMdd').format(now);
    final String signTime = '${DateFormat('yyyyMMddTHHmmss').format(now)}Z';

    // 2. 设置必要的请求头
    headersToSign['x-oss-content-sha256'] = 'UNSIGNED-PAYLOAD';
    headersToSign['x-oss-date'] = signTime;

    // 3. 添加安全令牌头（如果有）
    if (securityToken != null) {
      headersToSign['x-oss-security-token'] = securityToken;
    }

    // 4. 构建规范请求组件
    final String canonicalUri = _buildCanonicalUri(bucket, key);
    final String canonicalQuery = _buildCanonicalQuery(uri);
    final String canonicalHeaders = _buildCanonicalHeaders(
      headersToSign,
      additionalHeaders,
    );

    // 5. 处理额外头部
    final List<String> addHeaders =
        additionalHeaders.where((e) => !_isDefaultSignHeader(e)).toList()
          ..sort();
    final String additionalHeadersString = addHeaders.join(';');

    // 6. 构建规范请求
    final String canonicalRequestString = [
      method.toUpperCase(),
      canonicalUri,
      canonicalQuery,
      canonicalHeaders,
      additionalHeadersString,
      headersToSign['x-oss-content-sha256'] ?? 'UNSIGNED-PAYLOAD',
    ].join('\n');

    // 7. 构建签名范围和待签名字符串
    final String scope = '$signDate/$region/oss/aliyun_v4_request';
    final String stringToSign = _buildStringToSign(
      iso8601Time: signTime,
      scope: scope,
      canonicalRequest: canonicalRequestString.trim(),
    );

    // 8. 计算签名
    final String signature = _calculateV4Signature(
      accessKeySecret: accessKeySecret,
      date: signDate,
      region: region,
      stringToSign: stringToSign,
    );

    // 9. 构建并返回Authorization头
    return _buildAuthorizationHeader(
      accessKeyId: accessKeyId,
      scope: scope,
      additionalHeaders: additionalHeadersString,
      signature: signature,
    );
  }

  /// 生成包含签名的完整HTTP请求头
  ///
  /// 根据提供的参数生成包含阿里云OSS V4签名的完整HTTP请求头。
  /// 该方法不仅生成授权头，还会处理其他必要的头部，如日期、主机和内容哈希等。
  ///
  /// 处理流程：
  /// 1. 创建原始头部的副本，避免修改原始数据
  /// 2. 处理时间参数并格式化为 ISO8601 格式
  /// 3. 更新标准请求头，如 x-oss-date、Host、x-oss-content-sha256 和 Date
  /// 4. 处理安全令牌（如果提供）
  /// 5. 调用 [signature] 方法生成授权头
  /// 6. 将授权头添加到结果头部中并返回
  ///
  /// 参数：
  /// - [accessKeyId] 阿里云访问密钥ID
  /// - [accessKeySecret] 阿里云访问密钥
  /// - [endpoint] 阿里云OSS端点（如：oss-cn-hangzhou.aliyuncs.com）
  /// - [region] 区域代码（如：cn-hangzhou）
  /// - [method] HTTP方法（大写，如：PUT/GET）
  /// - [bucket] OSS存储空间名称
  /// - [key] 对象键（文件路径）
  /// - [uri] 完整的请求URI
  /// - [headers] 原始请求头集合，将被扩展并签名
  /// - [additionalHeaders] 需要参与签名的额外头名称集合，默认为空集合
  /// - [securityToken] 安全令牌（STS临时凭证需要）
  /// - [dateTime] 指定请求时间（可选，默认为当前时间）
  ///
  /// 返回包含完整签名头部的Map，可直接用于 HTTP 请求
  ///
  /// 示例：
  /// ```dart
  /// final headers = AliOssV4SignUtils.signedHeaders(
  ///   accessKeyId: 'your-access-key-id',
  ///   accessKeySecret: 'your-access-key-secret',
  ///   endpoint: 'oss-cn-hangzhou.aliyuncs.com',
  ///   region: 'cn-hangzhou',
  ///   method: 'PUT',
  ///   bucket: 'example-bucket',
  ///   key: 'example.txt',
  ///   uri: Uri.parse('https://example-bucket.oss-cn-hangzhou.aliyuncs.com/example.txt'),
  ///   headers: {'content-type': 'text/plain'},
  /// );
  /// // 结果包含如下头部：
  /// // {
  /// //   'content-type': 'text/plain',
  /// //   'x-oss-date': '20230615T123045Z',
  /// //   'Host': 'example-bucket.oss-cn-hangzhou.aliyuncs.com',
  /// //   'x-oss-content-sha256': 'UNSIGNED-PAYLOAD',
  /// //   'Date': 'Wed, 15 Jun 2023 12:30:45 GMT',
  /// //   'Authorization': 'OSS4-HMAC-SHA256 Credential=...,Signature=...'
  /// // }
  /// ```
  static Map<String, dynamic> signedHeaders({
    required String accessKeyId,
    required String accessKeySecret,
    required String endpoint,
    required String region,
    required String method,
    required String bucket,
    required String key,
    required Uri uri,
    required Map<String, dynamic> headers,
    Set<String> additionalHeaders = const {},
    String? securityToken,
    DateTime? dateTime,
  }) {
    // 创建headers的副本，避免修改原始map
    final Map<String, dynamic> result = <String, dynamic>{...headers};

    // 1. 处理时间相关参数
    final DateTime now = dateTime ?? DateTime.now().toUtc();
    final String signTime = '${DateFormat('yyyyMMddTHHmmss').format(now)}Z';

    // 2. 更新标准请求头
    result['x-oss-date'] = signTime;
    result['Host'] = '$bucket.$endpoint';
    result['x-oss-content-sha256'] = 'UNSIGNED-PAYLOAD';
    result['Date'] = HttpDate.format(now);

    // 3. 添加安全令牌头（如果有）
    if (securityToken != null) {
      result['x-oss-security-token'] = securityToken;
    }

    // 4. 构建签名
    final String auth = signature(
      accessKeyId: accessKeyId,
      accessKeySecret: accessKeySecret,
      endpoint: endpoint,
      region: region,
      method: method,
      bucket: bucket,
      key: key,
      uri: uri,
      headers: result,
      additionalHeaders: additionalHeaders,
      securityToken: securityToken,
      dateTime: now,
    );

    // 5. 设置Authorization头并返回完整头部
    result['Authorization'] = auth;
    return result;
  }

  /// 构建Authorization头
  static String _buildAuthorizationHeader({
    required String accessKeyId,
    required String scope,
    required String additionalHeaders,
    required String signature,
  }) {
    final List<String> components = [
      'OSS4-HMAC-SHA256 Credential=$accessKeyId/$scope',
    ];

    if (additionalHeaders.isNotEmpty) {
      components.add('AdditionalHeaders=$additionalHeaders');
    }

    components.add('Signature=$signature');
    return components.join(',');
  }

  /// 判断是否默认签名头
  static bool _isDefaultSignHeader(String header) {
    return header.startsWith(_ossHeaderPrefix) ||
        header == 'content-type' ||
        header == 'content-md5';
  }

  /// 构建规范URI
  ///
  /// 格式为: /bucket/object，确保正确编码
  static String _buildCanonicalUri(String bucket, String key) {
    final StringBuffer path = StringBuffer('/');

    if (bucket.isNotEmpty) {
      path.write('$bucket/');
    }

    if (key.isNotEmpty) {
      // 编码key但保留路径分隔符
      path.write(Uri.encodeComponent(key).replaceAll('%2F', '/'));
    }

    // 确保没有重复的斜杠
    return path.toString().replaceAll('//', '/');
  }

  /// 构建规范查询字符串
  ///
  /// 按照字典序排序参数，并正确编码
  static String _buildCanonicalQuery(Uri uri) {
    final List<String> params = <String>[];
    final Map<String, List<String>> queryParams = uri.queryParametersAll;

    if (queryParams.isEmpty) {
      return '';
    }

    // 按字典序排序参数名
    final List<String> sortedKeys = queryParams.keys.toList()..sort();

    for (final String key in sortedKeys) {
      final String encodedKey = Uri.encodeQueryComponent(key);
      // 创建一个可变副本再排序
      final List<String> values = List<String>.from(queryParams[key] ?? []);
      values.sort(); // 对可变副本进行排序

      for (final String value in values) {
        final String encodedValue =
            value.isEmpty ? '' : Uri.encodeQueryComponent(value);
        params.add(
          encodedValue.isEmpty ? encodedKey : '$encodedKey=$encodedValue',
        );
      }
    }

    return params.join('&');
  }

  /// 构建规范头列表
  ///
  /// 按照字典序排序头部，并格式化为key:value形式
  static String _buildCanonicalHeaders(
    Map<String, dynamic> headers,
    Set<String> additionalHeaders,
  ) {
    final List<String> headerList = <String>[];
    final Map<String, dynamic> lowerHeaders = headers.map(
      (k, v) => MapEntry(k.toLowerCase(), v),
    );

    // 合并默认头和额外头
    final Set<String> allSignHeaders = {
      ...additionalHeaders,
      ..._defaultSignHeaders,
    };

    for (final String header in allSignHeaders) {
      final String value = lowerHeaders[header]?.toString().trim() ?? '';
      headerList.add('$header:$value');
    }

    headerList.sort();
    return '${headerList.join('\n')}\n'; // 必须保留最后的换行符
  }

  /// 构建待签名字符串
  ///
  /// 包含算法标识、时间戳、作用域和请求哈希
  static String _buildStringToSign({
    required String iso8601Time,
    required String scope,
    required String canonicalRequest,
  }) {
    // 计算规范请求的SHA256哈希
    final String hashedRequest = hex.encode(
      sha256.convert(utf8.encode(canonicalRequest)).bytes,
    );

    // 构建并返回待签名字符串
    return ['OSS4-HMAC-SHA256', iso8601Time, scope, hashedRequest].join('\n');
  }

  /// 计算V4签名
  ///
  /// 使用派生密钥进行HMAC-SHA256签名
  static String _calculateV4Signature({
    required String accessKeySecret,
    required String date,
    required String region,
    required String stringToSign,
  }) {
    // 1. 生成初始密钥
    final List<int> v4Key = utf8.encode('aliyun_v4$accessKeySecret');

    // 2. 派生日期密钥
    final List<int> signingDate =
        Hmac(sha256, v4Key).convert(utf8.encode(date)).bytes;

    // 3. 派生区域密钥
    final List<int> signingRegion =
        Hmac(sha256, signingDate).convert(utf8.encode(region)).bytes;

    // 4. 派生服务密钥
    final List<int> signingOss =
        Hmac(sha256, signingRegion).convert(utf8.encode('oss')).bytes;

    // 5. 派生签名密钥
    final List<int> signingKey =
        Hmac(
          sha256,
          signingOss,
        ).convert(utf8.encode('aliyun_v4_request')).bytes;

    // 6. 计算最终签名
    final Digest signature = Hmac(
      sha256,
      signingKey,
    ).convert(utf8.encode(stringToSign));

    // 7. 返回十六进制编码的签名
    return hex.encode(signature.bytes);
  }
}
