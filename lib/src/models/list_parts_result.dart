import 'part_info.dart';

/// 阿里云OSS列出分片请求的结果模型
///
/// 该类表示调用 ListParts 操作后阿里云OSS返回的结果。
/// 它包含了特定分片上传任务的所有已上传分片的列表及其相关元数据。
///
/// 该类主要用于查询和管理已上传的分片，帮助开发者继续未完成的分片上传任务。
/// 它还支持分页查询大量的分片。
///
/// 主要应用场景：
/// - 恢复因网络中断或应用程序崩溃而未完成的分片上传任务
/// - 检查已上传分片的状态和进度
/// - 在完成分片上传前收集所有已上传分片的信息
/// - 实现分页浏览大量的分片
///
/// 使用示例：
/// ```dart
/// // 列出特定分片上传任务的所有已上传分片
/// final result = await ossClient.listParts('example.mp4', uploadId);
///
/// // 检查已上传的分片
/// if (result.parts.isNotEmpty) {
///   print('已上传 ${result.parts.length} 个分片');
///
///   // 收集所有分片信息，用于完成分片上传
///   final partETags = result.parts.map((part) => {
///     'partNumber': part.partNumber,
///     'eTag': part.eTag,
///   }).toList();
///
///   // 完成分片上传
///   await ossClient.completeMultipartUpload('example.mp4', uploadId, partETags);
/// }
///
/// // 如果结果被截断，继续获取下一页
/// if (result.isTruncated) {
///   final nextPageResult = await ossClient.listParts(
///     'example.mp4',
///     uploadId,
///     partNumberMarker: result.nextPartNumberMarker,
///   );
///   // 处理下一页结果...
/// }
/// ```
class ListPartsResult {
  /// 存储空间名称
  ///
  /// 分片上传所在的阿里云OSS存储空间（Bucket）名称。
  final String bucket;

  /// 文件键（路径）
  ///
  /// 要上传的文件在OSS中的完整路径和名称（Object Key）。
  final String key;

  /// 分片上传ID
  ///
  /// 由阿里云OSS生成的全局唯一标识符，用于标识这个分片上传任务。
  /// 这个 ID 在上传分片、完成或取消分片上传操作中必须提供。
  final String uploadId;

  /// 分片编号起始位置
  ///
  /// 本次请求中指定的 partNumberMarker 参数值。
  /// 列表从该值之后的分片开始返回。
  /// 如果请求中没有指定该参数，则为 null。
  final int? partNumberMarker;

  /// 下一个分片编号起始位置
  ///
  /// 如果返回的结果被截断（[isTruncated] 为 true），这个值表示下一次请求应该使用的 partNumberMarker 参数值。
  /// 如果结果未被截断，则为 null。
  final int? nextPartNumberMarker;

  /// 返回的最大分片数
  ///
  /// 本次请求中指定的或默认的最大返回数量。
  /// 这个值决定了单次响应中最多返回多少个分片。
  final int maxParts;

  /// 列表是否被截断
  ///
  /// 指示返回的结果是否被截断（即还有更多的分片未返回）。
  /// - true: 还有更多的分片未返回，可以使用 [nextPartNumberMarker] 继续查询
  /// - false: 所有的分片已经返回
  final bool isTruncated;

  /// 编码类型
  ///
  /// 指定响应中返回的内容的编码方式。
  /// 当请求中指定了 encodingType 参数时（如 'url'），这里会返回相应的编码类型。
  /// 如果请求中未指定，则为 null。
  final String? encodingType;

  /// 分片列表
  ///
  /// 包含所有符合查询条件的已上传分片的详细信息。
  /// 每个元素都是一个 [PartInfo] 对象，包含了分片编号、ETag、大小和上传时间等信息。
  /// 这些信息可用于完成分片上传操作。
  final List<PartInfo> parts;

  /// 构造函数
  ///
  /// 创建一个新的 [ListPartsResult] 实例。
  ///
  /// 参数：
  /// - [bucket] 必需的存储空间名称
  /// - [key] 必需的文件键（路径）
  /// - [uploadId] 必需的分片上传ID
  /// - [partNumberMarker] 可选的分片编号起始位置
  /// - [nextPartNumberMarker] 可选的下一个分片编号起始位置
  /// - [maxParts] 必需的最大分片数
  /// - [isTruncated] 必需的列表截断标志
  /// - [encodingType] 可选的编码类型
  /// - [parts] 必需的分片列表
  const ListPartsResult({
    required this.bucket,
    required this.key,
    required this.uploadId,
    this.partNumberMarker,
    this.nextPartNumberMarker,
    required this.maxParts,
    required this.isTruncated,
    this.encodingType,
    required this.parts,
  });

  /// 从XML字符串解析分片列表结果
  ///
  /// 将阿里云OSS返回的XML格式响应解析为 [ListPartsResult] 对象。
  /// 使用正则表达式提取各个元素的值，无需依赖外部XML解析库。
  ///
  /// 解析过程：
  /// 1. 提取所有的基本元数据字段（Bucket、Key、UploadId等）
  /// 2. 验证必需字段是否存在，并进行类型转换（如将字符串转为整数和布尔值）
  /// 3. 提取所有的 `<Part>` 元素并解析为 [PartInfo] 对象
  /// 4. 构造并返回完整的 [ListPartsResult] 对象
  ///
  /// 默认处理机制：
  /// - 如果解析单个 `<Part>` 元素失败，会跳过该元素并继续处理其他元素
  /// - 对于空的标签或自闭合标签，会正确处理并返回 null
  /// - 对于可选字段，如果在XML中不存在，则在结果对象中为 null
  ///
  /// 参数：
  /// - [xmlString] 要解析的XML字符串，通常是 ListParts 操作的响应体
  ///
  /// 返回一个新的 [ListPartsResult] 实例
  ///
  /// 异常：
  /// - 如果 XML 格式无效或缺少必需的元素，则抛出 [FormatException]
  /// - 如果 maxParts 字段不是有效的整数，则抛出 [FormatException]
  factory ListPartsResult.fromXmlString(String xmlString) {
    String? extractValue(String tagName) {
      final RegExpMatch? match = RegExp(
        '<$tagName>(.*?)</$tagName>|<$tagName/>',
      ).firstMatch(xmlString);
      return match?.group(1);
    }

    final String? bucket = extractValue('Bucket');
    final String? key = extractValue('Key');
    final String? uploadId = extractValue('UploadId');
    final String? partNumberMarkerStr = extractValue('PartNumberMarker');
    final String? nextPartNumberMarkerStr = extractValue(
      'NextPartNumberMarker',
    );
    final String? maxPartsStr = extractValue('MaxParts');
    final String? isTruncatedStr = extractValue('IsTruncated');
    final String? encodingType = extractValue('EncodingType');

    if (bucket == null ||
        key == null ||
        uploadId == null ||
        maxPartsStr == null ||
        isTruncatedStr == null) {
      throw FormatException('Invalid XML format: Missing required fields');
    }

    final int? maxParts = int.tryParse(maxPartsStr);
    if (maxParts == null) {
      throw FormatException('Invalid MaxParts format: $maxPartsStr');
    }

    final bool isTruncated = isTruncatedStr.toLowerCase() == 'true';
    final int? partNumberMarker =
        partNumberMarkerStr != null ? int.tryParse(partNumberMarkerStr) : null;
    final int? nextPartNumberMarker =
        nextPartNumberMarkerStr != null
            ? int.tryParse(nextPartNumberMarkerStr)
            : null;

    // 解析Part列表
    final List<PartInfo> parts = [];
    final Iterable<RegExpMatch> partMatches = RegExp(
      r'<Part>(.*?)</Part>',
      dotAll: true,
    ).allMatches(xmlString);
    for (final RegExpMatch match in partMatches) {
      try {
        parts.add(PartInfo.fromXmlFragment(match.group(1)!));
      } catch (e) {
        print('Error parsing Part fragment: $e');
      }
    }

    return ListPartsResult(
      bucket: bucket,
      key: key,
      uploadId: uploadId,
      partNumberMarker: partNumberMarker,
      nextPartNumberMarker: nextPartNumberMarker,
      maxParts: maxParts,
      isTruncated: isTruncated,
      encodingType: encodingType,
      parts: parts,
    );
  }

  /// 返回实例的字符串表示
  ///
  /// 提供了一个可读性强的字符串表示，包含所有属性的值。
  /// 对于分片列表，只显示其长度而不显示具体内容，以避免输出过长。
  ///
  /// 这在调试和日志记录时非常有用。
  @override
  String toString() {
    return 'ListPartsResult(bucket: $bucket, key: $key, uploadId: $uploadId, partNumberMarker: $partNumberMarker, nextPartNumberMarker: $nextPartNumberMarker, maxParts: $maxParts, isTruncated: $isTruncated, encodingType: $encodingType, parts: ${parts.length} items)';
  }

  /// 创建一个包含可选修改的新实例
  ///
  /// 这个方法允许基于现有实例创建一个新的 [ListPartsResult] 实例，
  /// 只更新指定的属性，保持其他属性不变。
  ///
  /// 参数：
  /// - [bucket] 新的存储空间名称
  /// - [key] 新的文件键（路径）
  /// - [uploadId] 新的分片上传ID
  /// - [partNumberMarker] 新的分片编号起始位置
  /// - [nextPartNumberMarker] 新的下一个分片编号起始位置
  /// - [maxParts] 新的最大分片数
  /// - [isTruncated] 新的列表截断标志
  /// - [encodingType] 新的编码类型
  /// - [parts] 新的分片列表
  ///
  /// 返回一个新的 [ListPartsResult] 实例
  ListPartsResult copyWith({
    String? bucket,
    String? key,
    String? uploadId,
    int? partNumberMarker,
    int? nextPartNumberMarker,
    int? maxParts,
    bool? isTruncated,
    String? encodingType,
    List<PartInfo>? parts,
  }) {
    return ListPartsResult(
      bucket: bucket ?? this.bucket,
      key: key ?? this.key,
      uploadId: uploadId ?? this.uploadId,
      partNumberMarker: partNumberMarker ?? this.partNumberMarker,
      nextPartNumberMarker: nextPartNumberMarker ?? this.nextPartNumberMarker,
      maxParts: maxParts ?? this.maxParts,
      isTruncated: isTruncated ?? this.isTruncated,
      encodingType: encodingType ?? this.encodingType,
      parts: parts ?? this.parts,
    );
  }

  /// 获取下一页查询的参数映射
  ///
  /// 当结果被截断时（[isTruncated] 为 true），这个方法返回一个包含下一页查询所需参数的映射。
  /// 这个映射可以直接用于构造下一页查询的参数。
  ///
  /// 如果结果未被截断（[isTruncated] 为 false），则返回空映射。
  ///
  /// 返回下一页查询的参数映射
  ///
  /// 示例：
  /// ```dart
  /// // 获取第一页结果
  /// final result = await ossClient.listParts('example.mp4', uploadId);
  ///
  /// // 如果有更多结果，获取下一页
  /// if (result.isTruncated) {
  ///   final nextPageParams = result.getNextPageParams();
  ///   final nextPageResult = await ossClient.listParts(
  ///     'example.mp4',
  ///     uploadId,
  ///     partNumberMarker: nextPageParams['partNumberMarker'],
  ///   );
  ///   // 处理下一页结果...
  /// }
  /// ```
  Map<String, int?> getNextPageParams() {
    if (!isTruncated) {
      return {};
    }

    return {'partNumberMarker': nextPartNumberMarker};
  }

  /// 获取分片上传的完成参数
  ///
  /// 生成用于完成分片上传的参数列表，包含每个分片的编号和 ETag。
  /// 这个列表可以直接用于调用 completeMultipartUpload 方法。
  ///
  /// 返回用于完成分片上传的参数列表
  ///
  /// 示例：
  /// ```dart
  /// final result = await ossClient.listParts('example.mp4', uploadId);
  ///
  /// // 获取完成参数并完成分片上传
  /// final completeParams = result.getCompleteParams();
  /// await ossClient.completeMultipartUpload('example.mp4', uploadId, completeParams);
  /// ```
  List<Map<String, dynamic>> getCompleteParams() {
    return parts
        .map((part) => {'partNumber': part.partNumber, 'eTag': part.eTag})
        .toList();
  }

  /// 获取已上传分片的总大小
  ///
  /// 计算所有已上传分片的总大小（字节）。
  /// 这在需要知道已上传数据量或计算上传进度时非常有用。
  ///
  /// 返回已上传分片的总大小（字节）
  ///
  /// 示例：
  /// ```dart
  /// final result = await ossClient.listParts('example.mp4', uploadId);
  /// final totalBytes = result.getTotalSize();
  /// print('已上传: ${totalBytes / 1024 / 1024} MB');
  /// ```
  int getTotalSize() {
    return parts.fold<int>(0, (sum, part) => sum + part.size);
  }
}
