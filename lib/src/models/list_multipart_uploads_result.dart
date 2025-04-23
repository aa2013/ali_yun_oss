import 'upload_info.dart';

/// 阿里云OSS列出分片上传请求的结果模型
///
/// 该类表示调用 ListMultipartUploads 操作后阿里云OSS返回的结果。
/// 它包含了当前正在进行的分片上传任务的列表及其相关元数据。
///
/// 该类主要用于管理和监控分片上传任务，帮助开发者识别未完成的上传任务，
/// 以便继续或清理这些任务。它还支持分页查询大量的分片上传任务。
///
/// 主要应用场景：
/// - 查找长时间未完成的分片上传任务，以便清理占用的存储空间
/// - 恢复因网络中断或应用程序崩溃而未完成的上传任务
/// - 监控当前正在进行的分片上传任务的状态
/// - 实现分页浏览大量的分片上传任务
///
/// 使用示例：
/// ```dart
/// // 列出所有正在进行的分片上传任务
/// final result = await ossClient.listMultipartUploads();
///
/// // 检查是否有未完成的上传任务
/// if (result.uploads.isNotEmpty) {
///   print('发现 ${result.uploads.length} 个未完成的上传任务');
///
///   // 遍历所有任务
///   for (final upload in result.uploads) {
///     final Duration age = DateTime.now().difference(upload.initiated);
///
///     // 清理超过一天的上传任务
///     if (age.inDays > 1) {
///       print('清理过期任务: ${upload.key}, 初始化于: ${upload.initiated}');
///       await ossClient.abortMultipartUpload(upload.key, upload.uploadId);
///     }
///   }
/// }
///
/// // 如果结果被截断，继续获取下一页
/// if (result.isTruncated) {
///   final nextPageResult = await ossClient.listMultipartUploads(
///     keyMarker: result.nextKeyMarker,
///     uploadIdMarker: result.nextUploadIdMarker,
///   );
///   // 处理下一页结果...
/// }
/// ```
class ListMultipartUploadsResult {
  /// 存储空间名称
  ///
  /// 返回结果所属的阿里云OSS存储空间（Bucket）名称。
  final String bucket;

  /// 公共前缀列表
  ///
  /// 当请求中指定了 [delimiter] 参数时，返回结果会将具有相同前缀（如同一目录下）的对象分组。
  /// 这个列表包含了这些公共前缀（目录路径）。
  /// 如果请求中没有指定 [delimiter]，或者没有公共前缀，则这个列表为空。
  final List<String> commonPrefixes;

  /// 目录分隔符
  ///
  /// 用于分组对象的字符，通常使用斜杠字符 '/'。
  /// 当指定该参数时，OSS会将同一目录下的对象当作一个组，并在 [commonPrefixes] 中返回目录名称。
  /// 如果请求中没有指定该参数，则为 null。
  final String? delimiter;

  /// 编码类型
  ///
  /// 指定响应中返回的内容的编码方式。
  /// 当请求中指定了 encodingType 参数时（如 'url'），这里会返回相应的编码类型。
  /// 如果请求中未指定，则为 null。
  final String? encodingType;

  /// 列表是否被截断
  ///
  /// 指示返回的结果是否被截断（即还有更多的分片上传任务未返回）。
  /// - true: 还有更多的分片上传任务未返回，可以使用 [nextKeyMarker] 和 [nextUploadIdMarker] 继续查询
  /// - false: 所有的分片上传任务已经返回
  final bool isTruncated;

  /// 列表的起始对象位置
  ///
  /// 本次请求中指定的 keyMarker 参数值。
  /// 如果请求中没有指定该参数，则为 null。
  final String? keyMarker;

  /// 返回的最大分片上传任务数量
  ///
  /// 本次请求中指定的或默认的最大返回数量。
  /// 这个值决定了单次响应中最多返回多少个分片上传任务。
  final int maxUploads;

  /// 下一个请求的对象标记值
  ///
  /// 如果返回的结果被截断（[isTruncated] 为 true），这个值表示下一次请求应该使用的 keyMarker 参数值。
  /// 如果结果未被截断，则为 null。
  final String? nextKeyMarker;

  /// 下一个请求的上传ID标记值
  ///
  /// 如果返回的结果被截断（[isTruncated] 为 true），这个值表示下一次请求应该使用的 uploadIdMarker 参数值。
  /// 如果结果未被截断，则为 null。
  final String? nextUploadIdMarker;

  /// 请求时指定的前缀
  ///
  /// 本次请求中指定的 prefix 参数值，用于限定返回的对象必须以该前缀开头。
  /// 如果请求中没有指定该参数，则为 null。
  final String? prefix;

  /// 列表的起始上传ID位置
  ///
  /// 本次请求中指定的 uploadIdMarker 参数值。
  /// 如果请求中没有指定该参数，则为 null。
  final String? uploadIdMarker;

  /// 分片上传事件列表
  ///
  /// 包含所有符合查询条件的分片上传任务的详细信息。
  /// 每个元素都是一个 [UploadInfo] 对象，包含了分片上传的目标文件、上传ID和初始化时间等信息。
  final List<UploadInfo> uploads;

  /// 构造函数
  ///
  /// 创建一个新的 [ListMultipartUploadsResult] 实例。
  ///
  /// 参数：
  /// - [bucket] 必需的存储空间名称
  /// - [commonPrefixes] 公共前缀列表，默认为空列表
  /// - [delimiter] 可选的目录分隔符
  /// - [encodingType] 可选的编码类型
  /// - [isTruncated] 必需的列表截断标志
  /// - [keyMarker] 可选的起始对象位置
  /// - [maxUploads] 必需的最大返回数量
  /// - [nextKeyMarker] 可选的下一个对象标记
  /// - [nextUploadIdMarker] 可选的下一个上传ID标记
  /// - [prefix] 可选的前缀筛选条件
  /// - [uploadIdMarker] 可选的起始上传ID位置
  /// - [uploads] 必需的分片上传事件列表
  const ListMultipartUploadsResult({
    required this.bucket,
    this.commonPrefixes = const [],
    this.delimiter,
    this.encodingType,
    required this.isTruncated,
    this.keyMarker,
    required this.maxUploads,
    this.nextKeyMarker,
    this.nextUploadIdMarker,
    this.prefix,
    this.uploadIdMarker,
    required this.uploads,
  });

  /// 从XML字符串解析分片上传列表结果
  ///
  /// 将阿里云OSS返回的XML格式响应解析为 [ListMultipartUploadsResult] 对象。
  /// 使用正则表达式提取各个元素的值，无需依赖外部XML解析库。
  ///
  /// 解析过程：
  /// 1. 提取所有的基本元数据字段（Bucket、KeyMarker、MaxUploads等）
  /// 2. 验证必需字段是否存在，并进行类型转换（如将字符串转为整数和布尔值）
  /// 3. 提取所有的 `<Upload>` 元素并解析为 [UploadInfo] 对象
  /// 4. 提取所有的 `<CommonPrefixes>` 元素中的 `<Prefix>` 值
  /// 5. 构造并返回完整的 [ListMultipartUploadsResult] 对象
  ///
  /// 默认处理机制：
  /// - 如果解析单个 `<Upload>` 元素失败，会跳过该元素并继续处理其他元素
  /// - 对于空的标签或自闭合标签，会正确处理并返回 null
  /// - 对于可选字段，如果在XML中不存在，则在结果对象中为 null
  ///
  /// 参数：
  /// - [xmlString] 要解析的XML字符串，通常是 ListMultipartUploads 操作的响应体
  ///
  /// 返回一个新的 [ListMultipartUploadsResult] 实例
  ///
  /// 异常：
  /// - 如果 XML 格式无效或缺少必需的元素（Bucket、MaxUploads、IsTruncated），则抛出 [FormatException]
  /// - 如果 maxUploads 字段不是有效的整数，则抛出 [FormatException]
  ///
  /// 示例 XML 格式：
  /// ```xml
  /// <ListMultipartUploadsResult>
  ///   <Bucket>example-bucket</Bucket>
  ///   <KeyMarker></KeyMarker>
  ///   <UploadIdMarker></UploadIdMarker>
  ///   <NextKeyMarker>example.jpg</NextKeyMarker>
  ///   <NextUploadIdMarker>0004B9895DBBB6EC98E36</NextUploadIdMarker>
  ///   <Delimiter>/</Delimiter>
  ///   <Prefix>uploads/</Prefix>
  ///   <MaxUploads>1000</MaxUploads>
  ///   <IsTruncated>false</IsTruncated>
  ///   <Upload>
  ///     <Key>uploads/example.jpg</Key>
  ///     <UploadId>0004B9895DBBB6EC98E36</UploadId>
  ///     <Initiated>2023-01-15T12:30:45.000Z</Initiated>
  ///   </Upload>
  ///   <CommonPrefixes>
  ///     <Prefix>uploads/photos/</Prefix>
  ///   </CommonPrefixes>
  /// </ListMultipartUploadsResult>
  /// ```
  factory ListMultipartUploadsResult.fromXmlString(String xmlString) {
    // Helper function to extract single value
    String? extractValue(String tagName) {
      // Use non-greedy match and handle self-closing tags or empty content
      final RegExpMatch? match = RegExp(
        '<$tagName>(.*?)</$tagName>|<$tagName/>',
      ).firstMatch(xmlString);
      // If group 1 exists, return it, otherwise it's an empty/self-closing tag
      return match?.group(1);
    }

    // Helper function to extract multiple values under a parent tag
    List<String> extractMultipleValues(String parentTag, String childTag) {
      final List<String> values = [];
      // Find the parent block first (non-greedy match)
      final RegExpMatch? parentMatch = RegExp(
        '<$parentTag>(.*?)</$parentTag>',
        dotAll: true,
      ).firstMatch(xmlString);
      if (parentMatch != null) {
        final String parentContent = parentMatch.group(1)!;
        // Find all child tags within the parent block
        final Iterable<RegExpMatch> childMatches = RegExp(
          '<$childTag>(.*?)</$childTag>',
        ).allMatches(parentContent);
        for (final RegExpMatch match in childMatches) {
          if (match.group(1) != null) {
            values.add(match.group(1)!);
          }
        }
      }
      return values;
    }

    // --- Extraction order remains the same ---
    final String? bucket = extractValue('Bucket');
    final String? keyMarker = extractValue('KeyMarker');
    final String? uploadIdMarker = extractValue('UploadIdMarker');
    final String? nextKeyMarker = extractValue('NextKeyMarker');
    final String? nextUploadIdMarker = extractValue('NextUploadIdMarker');
    final String? delimiter = extractValue('Delimiter');
    final String? prefix = extractValue('Prefix');
    final String? maxUploadsStr = extractValue('MaxUploads');
    final String? isTruncatedStr = extractValue('IsTruncated');
    final String? encodingType = extractValue('EncodingType');

    if (bucket == null || maxUploadsStr == null || isTruncatedStr == null) {
      throw FormatException(
        'Invalid XML format: Missing required fields (Bucket, MaxUploads, IsTruncated)',
      );
    }

    final int? maxUploads = int.tryParse(maxUploadsStr);
    if (maxUploads == null) {
      throw FormatException('Invalid MaxUploads format: $maxUploadsStr');
    }

    // Handle boolean parsing carefully
    final bool isTruncated = isTruncatedStr.toLowerCase() == 'true';

    // Extract Upload blocks
    final List<UploadInfo> uploads = [];
    final Iterable<RegExpMatch> uploadMatches = RegExp(
      r'<Upload>(.*?)<\/Upload>',
      dotAll: true,
    ).allMatches(xmlString);
    for (final RegExpMatch match in uploadMatches) {
      final String uploadFragment = match.group(1)!;
      try {
        uploads.add(UploadInfo.fromXmlFragment(uploadFragment));
      } catch (e) {
        // Optionally log the error or rethrow with more context
        print('Error parsing Upload fragment: $e');
        // Decide whether to skip the problematic fragment or fail entirely
        // throw FormatException('Failed to parse one of the Upload entries: $e');
      }
    }

    // Extract CommonPrefixes blocks
    final List<String> commonPrefixes = extractMultipleValues(
      'CommonPrefixes',
      'Prefix',
    );

    // --- Return statement arguments reordered to match constructor ---
    return ListMultipartUploadsResult(
      bucket: bucket,
      commonPrefixes: commonPrefixes, // Reordered
      delimiter: delimiter,
      encodingType: encodingType, // Reordered
      isTruncated: isTruncated, // Reordered
      keyMarker: keyMarker,
      maxUploads: maxUploads, // Reordered
      nextKeyMarker: nextKeyMarker,
      nextUploadIdMarker: nextUploadIdMarker,
      prefix: prefix, // Reordered
      uploadIdMarker: uploadIdMarker, // Reordered
      uploads: uploads, // Reordered
    );
  }

  /// 返回实例的字符串表示
  ///
  /// 提供了一个可读性强的字符串表示，包含所有属性的值。
  /// 对于列表类型的属性（commonPrefixes 和 uploads），只显示其长度而不显示具体内容，
  /// 以避免输出过长。
  ///
  /// 这在调试和日志记录时非常有用。
  @override
  String toString() {
    return 'ListMultipartUploadsResult(bucket: $bucket, commonPrefixes: ${commonPrefixes.length} items, delimiter: $delimiter, encodingType: $encodingType, isTruncated: $isTruncated, keyMarker: $keyMarker, maxUploads: $maxUploads, nextKeyMarker: $nextKeyMarker, nextUploadIdMarker: $nextUploadIdMarker, prefix: $prefix, uploadIdMarker: $uploadIdMarker, uploads: ${uploads.length} items)';
  }

  /// 创建一个包含可选修改的新实例
  ///
  /// 这个方法允许基于现有实例创建一个新的 [ListMultipartUploadsResult] 实例，
  /// 只更新指定的属性，保持其他属性不变。
  ///
  /// 参数：
  /// - [bucket] 新的存储空间名称
  /// - [commonPrefixes] 新的公共前缀列表
  /// - [delimiter] 新的目录分隔符
  /// - [encodingType] 新的编码类型
  /// - [isTruncated] 新的列表截断标志
  /// - [keyMarker] 新的起始对象位置
  /// - [maxUploads] 新的最大返回数量
  /// - [nextKeyMarker] 新的下一个对象标记
  /// - [nextUploadIdMarker] 新的下一个上传ID标记
  /// - [prefix] 新的前缀筛选条件
  /// - [uploadIdMarker] 新的起始上传ID位置
  /// - [uploads] 新的分片上传事件列表
  ///
  /// 创建一个包含可选修改的新实例
  ///
  /// 这个方法允许基于现有实例创建一个新的 [ListMultipartUploadsResult] 实例，
  /// 只更新指定的属性，保持其他属性不变。
  ///
  /// 参数：
  /// - [bucket] 新的存储空间名称
  /// - [commonPrefixes] 新的公共前缀列表
  /// - [delimiter] 新的目录分隔符
  /// - [encodingType] 新的编码类型
  /// - [isTruncated] 新的列表截断标志
  /// - [keyMarker] 新的起始对象位置
  /// - [maxUploads] 新的最大返回数量
  /// - [nextKeyMarker] 新的下一个对象标记
  /// - [nextUploadIdMarker] 新的下一个上传ID标记
  /// - [prefix] 新的前缀筛选条件
  /// - [uploadIdMarker] 新的起始上传ID位置
  /// - [uploads] 新的分片上传事件列表
  ///
  /// 返回一个新的 [ListMultipartUploadsResult] 实例
  ListMultipartUploadsResult copyWith({
    String? bucket,
    List<String>? commonPrefixes,
    String? delimiter,
    String? encodingType,
    bool? isTruncated,
    String? keyMarker,
    int? maxUploads,
    String? nextKeyMarker,
    String? nextUploadIdMarker,
    String? prefix,
    String? uploadIdMarker,
    List<UploadInfo>? uploads,
  }) {
    return ListMultipartUploadsResult(
      bucket: bucket ?? this.bucket,
      commonPrefixes: commonPrefixes ?? this.commonPrefixes,
      delimiter: delimiter ?? this.delimiter,
      encodingType: encodingType ?? this.encodingType,
      isTruncated: isTruncated ?? this.isTruncated,
      keyMarker: keyMarker ?? this.keyMarker,
      maxUploads: maxUploads ?? this.maxUploads,
      nextKeyMarker: nextKeyMarker ?? this.nextKeyMarker,
      nextUploadIdMarker: nextUploadIdMarker ?? this.nextUploadIdMarker,
      prefix: prefix ?? this.prefix,
      uploadIdMarker: uploadIdMarker ?? this.uploadIdMarker,
      uploads: uploads ?? this.uploads,
    );
  }

  /// 获取过期的分片上传任务
  ///
  /// 根据指定的过期时间阈值，过滤出初始化时间超过该阈值的分片上传任务。
  /// 这在清理长时间未完成的上传任务时非常有用。
  ///
  /// 参数：
  /// - [threshold] 过期时间阈值，默认为 24 小时
  ///
  /// 返回过期的分片上传任务列表
  ///
  /// 示例：
  /// ```dart
  /// // 获取超过 3 天的过期任务
  /// final expiredUploads = result.getExpiredUploads(threshold: Duration(days: 3));
  /// for (final upload in expiredUploads) {
  ///   print('清理过期任务: ${upload.key}, 初始化于: ${upload.initiated}');
  ///   await ossClient.abortMultipartUpload(upload.key, upload.uploadId);
  /// }
  /// ```
  List<UploadInfo> getExpiredUploads({
    Duration threshold = const Duration(hours: 24),
  }) {
    final DateTime now = DateTime.now();
    return uploads.where((upload) {
      final Duration age = now.difference(upload.initiated);
      return age >= threshold;
    }).toList();
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
  /// final result = await ossClient.listMultipartUploads();
  ///
  /// // 如果有更多结果，获取下一页
  /// if (result.isTruncated) {
  ///   final nextPageParams = result.getNextPageParams();
  ///   final nextPageResult = await ossClient.listMultipartUploads(
  ///     keyMarker: nextPageParams['keyMarker'],
  ///     uploadIdMarker: nextPageParams['uploadIdMarker'],
  ///   );
  ///   // 处理下一页结果...
  /// }
  /// ```
  Map<String, String?> getNextPageParams() {
    if (!isTruncated) {
      return {};
    }

    return {'keyMarker': nextKeyMarker, 'uploadIdMarker': nextUploadIdMarker};
  }

  /// 按照前缀过滤分片上传任务
  ///
  /// 返回文件键（key）以指定前缀开头的分片上传任务列表。
  /// 这在需要处理特定目录或文件类型的上传任务时非常有用。
  ///
  /// 参数：
  /// - [prefix] 要过滤的前缀
  ///
  /// 返回符合前缀条件的分片上传任务列表
  ///
  /// 示例：
  /// ```dart
  /// // 获取所有图片目录下的上传任务
  /// final imageUploads = result.filterByPrefix('images/');
  /// print('图片上传任务数量: ${imageUploads.length}');
  /// ```
  List<UploadInfo> filterByPrefix(String prefix) {
    return uploads.where((upload) => upload.key.startsWith(prefix)).toList();
  }
}
