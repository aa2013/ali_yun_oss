/// 完成分片上传操作的响应结果模型
///
/// 该类表示调用 CompleteMultipartUpload 操作成功后阿里云OSS返回的结果。
/// 它包含了已完成上传的文件的各种元数据信息,如存储空间、文件路径、访问 URL 等。
///
/// 该类主要用于解析阿里云OSS返回的XML格式响应,并提供了便捷的访问方式。
/// 它包含了从 XML 字符串创建实例的工厂方法,以及用于调试的字符串表示。
class CompleteMultipartUploadResult {
  /// 编码类型
  ///
  /// 指定响应中返回的内容的编码方式。
  /// 当请求中指定了 encodingType 参数时,这里会返回相应的编码类型（如 'url'）。
  /// 如果请求中未指定,则为 null。
  final String? encodingType;

  /// 文件的访问 URL
  ///
  /// 完成上传后文件的完整访问 URL。
  /// 这个 URL 可以用于直接访问文件（如果文件有公共访问权限）。
  /// 格式通常为：https://{bucket}.{endpoint}/{key}
  final String location;

  /// 存储空间名称
  ///
  /// 文件所在的阿里云OSS存储空间（Bucket）名称。
  final String bucket;

  /// 文件键值（路径）
  ///
  /// 文件在OSS中的完整路径和名称（Object Key）。
  final String key;

  /// 文件的 ETag 值
  ///
  /// 完成分片上传后生成的文件的 ETag（实体标签）。
  /// 对于分片上传的文件,ETag 不是文件内容的 MD5 值,
  /// 而是一个包含连字符的唯一标识,如 "3858F62AEEC9284B8A9B2C7D4B2CDAAA-1"。
  final String eTag;

  /// 构造函数
  ///
  /// 创建一个新的 [CompleteMultipartUploadResult] 实例。
  ///
  /// 参数：
  /// - [encodingType] 可选的编码类型
  /// - [location] 必需的文件访问 URL
  /// - [bucket] 必需的存储空间名称
  /// - [key] 必需的文件键值（路径）
  /// - [eTag] 必需的文件 ETag 值
  const CompleteMultipartUploadResult({
    this.encodingType,
    required this.location,
    required this.bucket,
    required this.key,
    required this.eTag,
  });

  /// 从 XML 字符串解析结果
  ///
  /// 将阿里云OSS返回的XML格式响应解析为 [CompleteMultipartUploadResult] 对象。
  /// 使用正则表达式提取各个元素的值。
  ///
  /// 参数：
  /// - [xmlString] 要解析的XML字符串
  ///
  /// 返回一个新的 [CompleteMultipartUploadResult] 实例
  ///
  /// 异常：
  /// - 如果缺少必需的元素,则抛出 [FormatException]
  factory CompleteMultipartUploadResult.fromXmlString(String xmlString) {
    // 辅助函数,使用 RegExp 安全地提取标签内容
    String? findElementText(String tagName, String xml) {
      final RegExpMatch? match = RegExp(
        '<$tagName>(.*?)</$tagName>',
      ).firstMatch(xml);
      return match?.group(1);
    }

    // 强制提取,如果找不到则抛出异常
    String findElementTextRequired(String tagName, String xml) {
      final String? text = findElementText(tagName, xml);
      if (text == null) {
        throw FormatException(
          "Missing required element '$tagName' in CompleteMultipartUploadResult XML",
        );
      }
      return text;
    }

    return CompleteMultipartUploadResult(
      // EncodingType 是可选的
      encodingType: findElementText('EncodingType', xmlString),
      location: findElementTextRequired('Location', xmlString),
      bucket: findElementTextRequired('Bucket', xmlString),
      key: findElementTextRequired('Key', xmlString),
      eTag: findElementTextRequired('ETag', xmlString),
    );
  }

  /// 返回实例的字符串表示
  ///
  /// 提供了一个可读性强的字符串表示,包含所有属性的值。
  /// 这在调试和日志记录时非常有用。
  @override
  String toString() {
    return 'CompleteMultipartUploadResult(encodingType: $encodingType, location: $location, bucket: $bucket, key: $key, eTag: $eTag)';
  }

  /// 获取文件的公共URL
  ///
  /// 返回文件的公共访问 URL。这个 URL 只有在文件设置了公共访问权限时才能访问。
  /// 如果文件是私有的,需要生成签名 URL 才能访问。
  ///
  /// 返回文件的公共访问 URL
  String get publicUrl => location;
}
