/// 阿里云OSS分片信息模型
///
/// 该类表示阿里云OSS分片上传中的单个分片的信息。
/// 它包含了分片的各种元数据，如ETag、大小、分片编号等。
///
/// 该类主要用于两个场景：
/// 1. 解析阿里云OSS返回的分片列表信息（如ListParts响应）
/// 2. 构造完成分片上传请求的分片列表（CompleteMultipartUpload请求）
///
/// 它提供了从 XML 片段解析和转换为 XML 片段的方法，便于与阿里云OSS API 交互。
class PartInfo {
  /// 分片的 ETag 值
  ///
  /// 分片的实体标签，由服务器生成并在上传分片成功后返回。
  /// 这个值通常是分片数据的 MD5 值，并且包含双引号，如 "d41d8cd98f00b204e9800998ecf8427e"。
  /// 在完成分片上传时，需要提供每个分片的 ETag 值。
  final String eTag;

  /// 分片的最后修改时间
  ///
  /// 分片上传完成的时间，采用 ISO8601 格式，如 "2023-01-15T12:30:45.000Z"。
  /// 这个字段主要用于信息展示和调试，在完成分片上传时不需要提供。
  final String lastModified;

  /// 分片编号
  ///
  /// 分片的序号，范围从 1 到 10000。
  /// 在完成分片上传时，需要按照分片编号升序排列分片列表。
  /// 分片编号不必连续，但必须升序排列。
  final int partNumber;

  /// 分片大小（字节）
  ///
  /// 分片的大小，单位为字节。
  /// 除最后一个分片外，其他分片的大小应大于或等于 100KB。
  /// 这个字段主要用于信息展示和调试，在完成分片上传时不需要提供。
  final int size;

  /// 构造函数
  ///
  /// 创建一个新的 [PartInfo] 实例。
  ///
  /// 参数：
  /// - [eTag] 必需的分片 ETag 值
  /// - [lastModified] 必需的分片最后修改时间
  /// - [partNumber] 必需的分片编号（1-10000）
  /// - [size] 必需的分片大小（字节）
  const PartInfo({
    required this.eTag,
    required this.lastModified,
    required this.partNumber,
    required this.size,
  });

  /// 从XML片段解析分片信息
  ///
  /// 将阿里云OSS返回的XML格式分片信息解析为 [PartInfo] 对象。
  /// 使用正则表达式提取各个元素的值。
  ///
  /// 参数：
  /// - [xmlFragment] 要解析的XML片段，通常是 `<Part>...</Part>` 元素的内容
  ///
  /// 返回一个新的 [PartInfo] 实例
  ///
  /// 异常：
  /// - 如果 XML 片段格式无效或缺少必需的元素，则抛出 [FormatException]
  factory PartInfo.fromXmlFragment(String xmlFragment) {
    // 按字母顺序查找 XML 元素
    final RegExpMatch? eTagMatch = RegExp(
      r'<ETag>(.*?)</ETag>',
    ).firstMatch(xmlFragment);
    final RegExpMatch? lastModifiedMatch = RegExp(
      r'<LastModified>(.*?)</LastModified>',
    ).firstMatch(xmlFragment);
    final RegExpMatch? partNumberMatch = RegExp(
      r'<PartNumber>(.*?)</PartNumber>',
    ).firstMatch(xmlFragment);
    final RegExpMatch? sizeMatch = RegExp(
      r'<Size>(.*?)</Size>',
    ).firstMatch(xmlFragment);

    // 按字母顺序检查匹配结果
    if (eTagMatch == null ||
        lastModifiedMatch == null ||
        partNumberMatch == null ||
        sizeMatch == null) {
      throw FormatException('Invalid Part XML fragment');
    }

    // 按字母顺序构造 PartInfo 对象
    return PartInfo(
      eTag: eTagMatch.group(1)!,
      lastModified: lastModifiedMatch.group(1)!,
      partNumber: int.parse(partNumberMatch.group(1)!),
      size: int.parse(sizeMatch.group(1)!),
    );
  }

  /// 将 PartInfo 转换为 XML 字符串片段
  ///
  /// 生成用于 CompleteMultipartUpload 请求的 XML 片段。
  ///
  /// 注意：ETag 值通常包含双引号，调用者传入时应确保包含。
  ///
  /// 返回格式化的 XML 字符串片段
  String toXmlFragment() {
    // 按字母顺序排列 XML 元素
    return '''
  <Part>
    <ETag>$eTag</ETag>
    <LastModified>$lastModified</LastModified>
    <PartNumber>$partNumber</PartNumber>
    <Size>$size</Size>
  </Part>'''.trim();
  }

  /// 返回实例的字符串表示
  ///
  /// 提供了一个可读性强的字符串表示，包含所有属性的值。
  /// 这在调试和日志记录时非常有用。
  @override
  String toString() {
    // 按字母顺序排列字段
    return 'Part(eTag: $eTag, lastModified: $lastModified, partNumber: $partNumber, size: $size)';
  }

  /// 创建一个用于完成分片上传的简化 PartInfo 实例
  ///
  /// 在完成分片上传时，只需要提供分片编号和 ETag，其他字段不是必需的。
  /// 这个工厂方法提供了一种便捷的方式来创建这样的简化实例。
  ///
  /// 参数：
  /// - [partNumber] 分片编号（1-10000）
  /// - [eTag] 分片的 ETag 值，应包含双引号
  ///
  /// 返回一个新的 [PartInfo] 实例，其中 lastModified 和 size 字段设置为默认值
  factory PartInfo.forComplete(int partNumber, String eTag) {
    return PartInfo(
      partNumber: partNumber,
      eTag: eTag,
      lastModified: '', // 完成上传时不需要
      size: 0, // 完成上传时不需要
    );
  }

  /// 创建一个包含可选修改的新实例
  ///
  /// 这个方法允许基于现有实例创建一个新的 [PartInfo] 实例，
  /// 只更新指定的属性，保持其他属性不变。
  ///
  /// 参数：
  /// - [eTag] 新的 ETag 值
  /// - [lastModified] 新的最后修改时间
  /// - [partNumber] 新的分片编号
  /// - [size] 新的分片大小
  ///
  /// 返回一个新的 [PartInfo] 实例
  PartInfo copyWith({
    String? eTag,
    String? lastModified,
    int? partNumber,
    int? size,
  }) {
    return PartInfo(
      eTag: eTag ?? this.eTag,
      lastModified: lastModified ?? this.lastModified,
      partNumber: partNumber ?? this.partNumber,
      size: size ?? this.size,
    );
  }
}
