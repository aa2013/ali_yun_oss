/// 阿里云OSS分片上传事件信息
///
/// 该类表示阿里云OSS中正在进行的分片上传事件的信息。
/// 它包含了分片上传的目标文件、上传ID和初始化时间等关键信息。
///
/// 该类主要用于解析 ListMultipartUploads 操作返回的结果,
/// 帮助开发者管理和监控正在进行的分片上传任务。
class UploadInfo {

  /// 构造函数
  ///
  /// 创建一个新的 [UploadInfo] 实例。
  ///
  /// 参数：
  /// - [key] 必需的目标文件对象名称
  /// - [uploadId] 必需的分片上传事件ID
  /// - [initiated] 必需的分片上传初始化时间
  const UploadInfo({
    required this.key,
    required this.uploadId,
    required this.initiated,
  });

  /// 从XML片段字符串解析分片上传信息
  ///
  /// 将阿里云OSS返回的XML格式分片上传信息解析为 [UploadInfo] 对象。
  /// 使用正则表达式提取各个元素的值。
  ///
  /// 参数：
  /// - [xmlFragment] 要解析的XML片段,形如 `<Key>...</Key><UploadId>...</UploadId><Initiated>...</Initiated>`
  ///
  /// 返回一个新的 [UploadInfo] 实例
  ///
  /// 异常：
  /// - 如果 XML 片段格式无效或缺少必需的元素,则抛出 [FormatException]
  /// - 如果初始化时间格式无效,则抛出 [FormatException]
  factory UploadInfo.fromXmlFragment(String xmlFragment) {
    final String? key = RegExp(
      r'<Key>(.*?)<\/Key>',
    ).firstMatch(xmlFragment)?.group(1);
    final String? uploadId = RegExp(
      r'<UploadId>(.*?)<\/UploadId>',
    ).firstMatch(xmlFragment)?.group(1);
    final String? initiatedStr = RegExp(
      r'<Initiated>(.*?)<\/Initiated>',
    ).firstMatch(xmlFragment)?.group(1);

    if (key == null || uploadId == null || initiatedStr == null) {
      throw FormatException(
        'Invalid XML fragment for UploadInfo: $xmlFragment',
      );
    }

    final DateTime? initiated = DateTime.tryParse(initiatedStr);
    if (initiated == null) {
      throw FormatException(
        'Invalid DateTime format for Initiated in UploadInfo: $initiatedStr',
      );
    }

    return UploadInfo(key: key, uploadId: uploadId, initiated: initiated);
  }
  /// 目标文件的对象名称
  ///
  /// 分片上传的目标文件在OSS中的完整路径和名称（Object Key）。
  /// 这个字段可以用于识别和管理特定文件的分片上传任务。
  final String key;

  /// 分片上传事件的ID
  ///
  /// 由阿里云OSS生成的全局唯一标识符,用于标识特定的分片上传任务。
  /// 这个 ID 在上传分片、完成或取消分片上传时需要提供。
  final String uploadId;

  /// 分片上传事件初始化的时间
  ///
  /// 分片上传任务创建的时间,采用 ISO8601 格式。
  /// 这个字段可以用于识别长时间未完成的上传任务,以便清理资源。
  final DateTime initiated;

  /// 返回实例的字符串表示
  ///
  /// 提供了一个可读性强的字符串表示,包含所有属性的值。
  /// 这在调试和日志记录时非常有用。
  @override
  String toString() {
    return 'UploadInfo(key: $key, uploadId: $uploadId, initiated: $initiated)';
  }

  /// 创建一个包含可选修改的新实例
  ///
  /// 这个方法允许基于现有实例创建一个新的 [UploadInfo] 实例,
  /// 只更新指定的属性,保持其他属性不变。
  ///
  /// 参数：
  /// - [key] 新的目标文件对象名称
  /// - [uploadId] 新的分片上传事件ID
  /// - [initiated] 新的分片上传初始化时间
  ///
  /// 返回一个新的 [UploadInfo] 实例
  UploadInfo copyWith({String? key, String? uploadId, DateTime? initiated}) {
    return UploadInfo(
      key: key ?? this.key,
      uploadId: uploadId ?? this.uploadId,
      initiated: initiated ?? this.initiated,
    );
  }
}
