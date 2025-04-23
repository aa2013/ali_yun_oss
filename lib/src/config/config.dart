import 'package:dio/dio.dart';

/// 阿里云OSS配置类
///
/// 用于存储和管理阿里云OSS服务所需的配置信息，包括：
/// - 访问凭证（AccessKey ID和Secret）
/// - 存储空间信息（Bucket和Region）
/// - 网络请求配置（Dio实例和拦截器）
/// - 性能配置（并发数等）
class OSSConfig {
  /// OSS访问密钥ID
  ///
  /// 用于身份验证的AccessKey ID，可从阿里云控制台获取
  final String accessKeyId;

  /// OSS访问密钥密码
  ///
  /// 用于身份验证的AccessKey Secret，可从阿里云控制台获取
  /// 注意：请妥善保管，不要泄露给他人
  final String accessKeySecret;

  /// OSS存储空间名称
  ///
  /// Bucket是OSS上的命名空间，也是计费、权限控制、日志记录等高级功能的管理实体
  final String bucketName;

  /// 自定义的Dio实例，用于网络请求
  ///
  /// 如果不提供，将使用默认配置创建新的实例
  /// 如果提供自定义实例，请确保配置了合适的超时时间和重试策略
  final Dio? dio;

  /// 是否开启默认的日志拦截器
  ///
  /// 开启后将打印请求和响应的详细日志，便于调试
  /// 建议在生产环境中关闭以提高性能
  final bool enableLogInterceptor;

  /// OSS服务的访问域名
  ///
  /// 完整的Endpoint地址，例如：
  /// - 公网：'oss-cn-hangzhou.aliyuncs.com'
  /// - VPC网络：'oss-cn-hangzhou-internal.aliyuncs.com'
  final String endpoint;

  /// 自定义的请求拦截器列表
  ///
  /// 可以添加自定义的Dio拦截器来实现：
  /// - 请求/响应日志
  /// - 认证信息注入
  /// - 错误处理
  /// - 请求重试等功能
  final List<Interceptor>? interceptors;

  /// 分片上传时的最大并发数
  ///
  /// 控制分片上传时同时进行上传的最大分片数量：
  /// - 默认值：5
  /// - 最小值：1（串行上传）
  /// - 最大值：10
  ///
  /// 建议：
  /// - 移动设备：使用较小值（3-5）避免资源占用过多
  /// - 服务器：可适当提高（5-10）以提升上传速度
  /// - 弱网环境：建议降低并发数（1-3）减少上传失败概率
  final int maxConcurrency;

  /// OSS服务的地域
  ///
  /// 地域表示OSS的数据中心所在物理位置
  /// 例如：'cn-hangzhou'、'cn-beijing'等
  final String region;

  /// 构造函数
  ///
  /// 创建一个新的OSS配置实例。
  ///
  /// 参数说明：
  /// - [accessKeyId] OSS访问密钥ID
  /// - [accessKeySecret] OSS访问密钥密码
  /// - [bucketName] OSS存储空间名称
  /// - [endpoint] OSS服务的访问域名
  /// - [region] OSS服务的地域
  /// - [dio] 可选的自定义Dio实例
  /// - [enableLogInterceptor] 是否启用日志拦截器，默认为true
  /// - [interceptors] 可选的自定义拦截器列表
  /// - [maxConcurrency] 分片上传的最大并发数，默认为5
  /// 从 JSON 数据创建 OSSConfig 实例
  ///
  /// 这在从配置文件或远程服务加载配置时非常有用。
  ///
  /// 参数：
  /// - [json] 包含配置数据的 Map
  ///
  /// 返回一个新的 [OSSConfig] 实例
  factory OSSConfig.fromJson(Map<String, dynamic> json) {
    return OSSConfig(
      accessKeyId: json['accessKeyId'] as String,
      accessKeySecret: json['accessKeySecret'] as String,
      bucketName: json['bucketName'] as String,
      endpoint: json['endpoint'] as String,
      region: json['region'] as String,
      enableLogInterceptor: json['enableLogInterceptor'] as bool? ?? true,
      maxConcurrency: json['maxConcurrency'] as int? ?? 5,
    );
  }

  /// 将配置转换为 JSON 格式
  ///
  /// 这在需要将配置保存到文件或发送到远程服务时非常有用。
  ///
  /// 返回一个包含配置数据的 Map
  Map<String, dynamic> toJson() {
    return {
      'accessKeyId': accessKeyId,
      'accessKeySecret': accessKeySecret,
      'bucketName': bucketName,
      'endpoint': endpoint,
      'region': region,
      'enableLogInterceptor': enableLogInterceptor,
      'maxConcurrency': maxConcurrency,
    };
  }

  const OSSConfig({
    required this.accessKeyId,
    required this.accessKeySecret,
    required this.bucketName,
    required this.endpoint,
    required this.region,
    this.dio,
    this.enableLogInterceptor = true,
    this.interceptors,
    this.maxConcurrency = 5,
  });

  /// 创建一个用于测试的默认配置
  ///
  /// 这在开发和测试时非常有用，可以快速创建一个带有默认值的配置对象。
  /// 注意：这个方法仅用于测试目的，不应在生产环境中使用。
  ///
  /// 参数：
  /// - [accessKeyId] 可选的 AccessKey ID，默认为 'test_key_id'
  /// - [accessKeySecret] 可选的 AccessKey Secret，默认为 'test_key_secret'
  /// - [bucketName] 可选的存储空间名称，默认为 'test-bucket'
  /// - [endpoint] 可选的端点，默认为 'oss-cn-hangzhou.aliyuncs.com'
  /// - [region] 可选的区域，默认为 'cn-hangzhou'
  ///
  /// 返回一个新的 [OSSConfig] 实例，包含默认值或提供的值
  static OSSConfig forTest({
    String accessKeyId = 'test_key_id',
    String accessKeySecret = 'test_key_secret',
    String bucketName = 'test-bucket',
    String endpoint = 'oss-cn-hangzhou.aliyuncs.com',
    String region = 'cn-hangzhou',
  }) {
    return OSSConfig(
      accessKeyId: accessKeyId,
      accessKeySecret: accessKeySecret,
      bucketName: bucketName,
      endpoint: endpoint,
      region: region,
      enableLogInterceptor: true,
      maxConcurrency: 3,
    );
  }

  /// 创建当前配置的副本，并可选择性地覆盖某些属性
  ///
  /// 这在需要修改配置的某些部分而保持其他部分不变时非常有用。
  ///
  /// 参数：
  /// - [accessKeyId] 新的 AccessKey ID
  /// - [accessKeySecret] 新的 AccessKey Secret
  /// - [bucketName] 新的存储空间名称
  /// - [endpoint] 新的端点
  /// - [region] 新的区域
  /// - [dio] 新的 Dio 实例
  /// - [enableLogInterceptor] 是否启用日志拦截器
  /// - [interceptors] 新的拦截器列表
  /// - [maxConcurrency] 新的最大并发数
  ///
  /// 返回一个新的 [OSSConfig] 实例，包含更新后的属性
  OSSConfig copyWith({
    String? accessKeyId,
    String? accessKeySecret,
    String? bucketName,
    String? endpoint,
    String? region,
    Dio? dio,
    bool? enableLogInterceptor,
    List<Interceptor>? interceptors,
    int? maxConcurrency,
  }) {
    return OSSConfig(
      accessKeyId: accessKeyId ?? this.accessKeyId,
      accessKeySecret: accessKeySecret ?? this.accessKeySecret,
      bucketName: bucketName ?? this.bucketName,
      endpoint: endpoint ?? this.endpoint,
      region: region ?? this.region,
      dio: dio ?? this.dio,
      enableLogInterceptor: enableLogInterceptor ?? this.enableLogInterceptor,
      interceptors: interceptors ?? this.interceptors,
      maxConcurrency: maxConcurrency ?? this.maxConcurrency,
    );
  }

  @override
  String toString() {
    return 'OSSConfig(accessKeyId: ${accessKeyId.substring(0, 3)}***, '
        'accessKeySecret: ${accessKeySecret.substring(0, 3)}***, '
        'bucketName: $bucketName, '
        'endpoint: $endpoint, '
        'region: $region, '
        'enableLogInterceptor: $enableLogInterceptor, '
        'maxConcurrency: $maxConcurrency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OSSConfig &&
        other.accessKeyId == accessKeyId &&
        other.accessKeySecret == accessKeySecret &&
        other.bucketName == bucketName &&
        other.endpoint == endpoint &&
        other.region == region &&
        other.enableLogInterceptor == enableLogInterceptor &&
        other.maxConcurrency == maxConcurrency;
    // 注意：我们不比较 dio 和 interceptors，因为它们可能包含不可比较的对象
  }

  @override
  int get hashCode {
    return Object.hash(
      accessKeyId,
      accessKeySecret,
      bucketName,
      endpoint,
      region,
      enableLogInterceptor,
      maxConcurrency,
    );
  }
}
