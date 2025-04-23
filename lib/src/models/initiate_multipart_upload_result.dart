/// 初始化分片上传结果模型
///
/// 该类表示调用 InitiateMultipartUpload 操作成功后阿里云OSS返回的结果。
/// 它包含了初始化分片上传所需的关键信息，如存储空间、文件路径和上传ID等。
///
/// 这些信息在后续的分片上传操作中必不可少，特别是 uploadId，
/// 它是标识分片上传任务的唯一标识符，在上传分片、完成或取消分片上传时都需要提供。
class InitiateMultipartUploadResult {
  /// 存储空间名称
  ///
  /// 分片上传所在的阿里云OSS存储空间（Bucket）名称。
  /// 这个字段在后续的分片上传操作中需要使用。
  final String bucket;

  /// 文件键（路径）
  ///
  /// 要上传的文件在OSS中的完整路径和名称（Object Key）。
  /// 这个字段在后续的分片上传操作中需要使用。
  final String key;

  /// 分片上传ID
  ///
  /// 由阿里云OSS生成的全局唯一标识符，用于标识这个分片上传任务。
  /// 这个 ID 在后续的上传分片、完成或取消分片上传操作中必须提供。
  final String uploadId;

  /// 构造函数
  ///
  /// 创建一个新的 [InitiateMultipartUploadResult] 实例。
  ///
  /// 参数：
  /// - [bucket] 必需的存储空间名称
  /// - [key] 必需的文件键（路径）
  /// - [uploadId] 必需的分片上传ID
  const InitiateMultipartUploadResult({
    required this.bucket,
    required this.key,
    required this.uploadId,
  });

  /// 从XML字符串解析初始化分片上传结果
  ///
  /// 将阿里云OSS返回的XML格式响应解析为 [InitiateMultipartUploadResult] 对象。
  /// 使用正则表达式提取各个元素的值。
  ///
  /// 参数：
  /// - [xmlString] 要解析的XML字符串，通常是 InitiateMultipartUpload 操作的响应体
  ///
  /// 返回一个新的 [InitiateMultipartUploadResult] 实例
  ///
  /// 异常：
  /// - 如果 XML 格式无效或缺少必需的元素，则抛出 [FormatException]
  factory InitiateMultipartUploadResult.fromXmlString(String xmlString) {
    final RegExpMatch? bucketMatch = RegExp(
      r'<Bucket>(.*?)<\/Bucket>',
    ).firstMatch(xmlString);
    final RegExpMatch? keyMatch = RegExp(
      r'<Key>(.*?)<\/Key>',
    ).firstMatch(xmlString);
    final RegExpMatch? uploadIdMatch = RegExp(
      r'<UploadId>(.*?)<\/UploadId>',
    ).firstMatch(xmlString);

    if (bucketMatch == null || keyMatch == null || uploadIdMatch == null) {
      throw FormatException(
        'Invalid XML format for InitiateMultipartUploadResult',
      );
    }

    return InitiateMultipartUploadResult(
      bucket: bucketMatch.group(1)!,
      key: keyMatch.group(1)!,
      uploadId: uploadIdMatch.group(1)!,
    );
  }

  /// 返回实例的字符串表示
  ///
  /// 提供了一个可读性强的字符串表示，包含所有属性的值。
  /// 这在调试和日志记录时非常有用。
  @override
  String toString() {
    return 'InitiateMultipartUploadResult(bucket: $bucket, key: $key, uploadId: $uploadId)';
  }

  /// 创建一个包含可选修改的新实例
  ///
  /// 这个方法允许基于现有实例创建一个新的 [InitiateMultipartUploadResult] 实例，
  /// 只更新指定的属性，保持其他属性不变。
  ///
  /// 参数：
  /// - [bucket] 新的存储空间名称
  /// - [key] 新的文件键（路径）
  /// - [uploadId] 新的分片上传ID
  ///
  /// 返回一个新的 [InitiateMultipartUploadResult] 实例
  InitiateMultipartUploadResult copyWith({
    String? bucket,
    String? key,
    String? uploadId,
  }) {
    return InitiateMultipartUploadResult(
      bucket: bucket ?? this.bucket,
      key: key ?? this.key,
      uploadId: uploadId ?? this.uploadId,
    );
  }
}
