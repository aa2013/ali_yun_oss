import 'dart:convert';

/// Object 的元数据信息
class ObjectMeta {
  /// 构造函数
  ObjectMeta({
    required this.contentLength,
    required this.eTag,
    this.transitionTime,
    this.lastAccessTime,
    required this.lastModified,
    this.versionId,
  });

  /// 从 JSON 数据创建 ObjectMeta
  factory ObjectMeta.fromJson(Map<String, dynamic> json) {
    return ObjectMeta(
      contentLength: json['Content-Length'] as int,
      eTag: json['ETag'] as String,
      transitionTime: json['x-oss-transition-time'] as String?,
      lastAccessTime: json['x-oss-last-access-time'] as String?,
      lastModified: json['Last-Modified'] as String,
      versionId: json['x-oss-version-id'] as String?,
    );
  }

  /// Object 的文件大小，单位为字节。
  final int contentLength;

  /// Object 的 ETag 标识。
  ///
  /// Object 生成时会创建 ETag（entity tag），ETag 用于标识一个 Object 的内容。
  ///
  /// 对于通过 PutObject 请求创建的 Object，ETag 值是其内容的 MD5 值；
  /// 对于其他方式创建的 Object，ETag 值是基于一定计算规则生成的唯一值，但不是其内容的 MD5 值。
  /// ETag 值可以用于检查 Object 内容是否发生变化。
  /// 不建议用户使用 ETag 作为 Object 内容的 MD5 校验来验证数据完整性。
  final String eTag;

  /// Object 通过生命周期规则转储为冷归档或者深度冷归档存储类型的时间。
  ///
  /// 说明：
  /// - 如果获取的转储时间距离当前时间超过 180 天，则提前删除冷归档或者深度冷归档 Object 不会产生存储不足规定时长费用。
  /// - 如果转储时间距离当前时间不超过 180 天，则提前删除冷归档或者深度冷归档 Object 会产生存储不足规定时长费用。
  ///
  /// 不支持通过该字段统计 Object 通过生命周期规则转储为低频或者归档存储类型的时间。
  /// 判断低频或者归档存储类型是否满足最低存储时长的要求取决于 Last-Modified 时间。
  final String? transitionTime;

  /// Object 的最后一次访问时间。时间格式为 HTTP 1.1 协议中规定的 GMT 时间。
  ///
  /// 开启访问跟踪后，该字段的值会随着文件被访问的时间持续更新。
  /// 如果关闭了访问跟踪，则不再返回该字段。
  ///
  /// 重要：
  /// - Object 的最后一次访问时间是异步更新的，OSS 会保证在 24 小时内完成 Object 最后一次访问时间的更新。
  /// - 对于 24 小时内多次访问同一个 Object，OSS 仅更新该 Object 的最早一次访问时间。
  final String? lastAccessTime;

  /// Object 最后一次修改时间。时间格式为 HTTP 1.1 协议中规定的 GMT 时间。
  ///
  /// 说明：
  /// - 低频访问类型最低存储时间（30 天）以 Object 存储在 OSS 的 Last Modified 时间开始计算。
  ///   如果获取到 Object 的 Last-Modified 时间距离当前时间超过 30 天，
  ///   则提前删除 Object 不会产生低频存储不足规定时长费用。
  /// - 归档类型最低存储时间（60 天）以 Object 存储在 OSS 的 Last Modified 时间开始计算。
  ///   如果获取到 Object 的 Last-Modified 时间距离当前时间超过 60 天，
  ///   则提前删除 Object 不会产生归档存储不足规定时长费用。
  final String lastModified;

  /// Object 的版本 ID。
  ///
  /// 只有查看 Object 指定版本的元数据信息时才显示该字段。
  final String? versionId;

  /// 如果 contentLength > 0 表示为文件
  bool get isFile => contentLength > 0;

  /// 将 ObjectMeta 转换为 JSON 数据
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Content-Length': contentLength,
      'ETag': eTag,
      'x-oss-transition-time': transitionTime,
      'x-oss-last-access-time': lastAccessTime,
      'Last-Modified': lastModified,
      'x-oss-version-id': versionId,
    };
  }

  @override
  String toString() {
    return jsonEncode(this);
  }
}
