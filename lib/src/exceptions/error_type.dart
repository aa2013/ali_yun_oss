/// 定义 OSS 操作可能遇到的错误类型
///
/// 该枚举用于分类和标识阿里云OSS操作过程中可能出现的各种错误情况。
/// 它在 [OSSException] 中被用于指示错误的类型，便于客户端代码进行错误处理和恢复。
///
/// 使用示例：
/// ```dart
/// try {
///   await ossClient.putObject(file, 'example.txt');
/// } catch (e) {
///   if (e is OSSException) {
///     switch (e.type) {
///       case OSSErrorType.accessDenied:
///         print('访问被拒绝，请检查权限');
///         break;
///       case OSSErrorType.network:
///         print('网络错误，请检查连接');
///         break;
///       // 处理其他错误类型...
///     }
///   }
/// }
/// ```
enum OSSErrorType {
  /// 中止分片上传失败
  ///
  /// 当调用 [abortMultipartUpload] 方法尝试中止一个进行中的分片上传时出错。
  /// 可能的原因包括网络问题、服务器错误或指定的 uploadId 无效。
  abortMultipartFailed,

  /// 访问被拒绝
  ///
  /// 当请求被阿里云OSS服务器拒绝时抛出。通常对应HTTP 403状态码。
  /// 可能的原因包括：
  /// - 访问凭证（AccessKey）无效或过期
  /// - 访问凭证没有操作指定资源的权限
  /// - Bucket或对象的访问控制策略（ACL）限制了访问
  /// - 账户欠费或被禁用
  accessDenied,

  /// 完成分片上传失败
  ///
  /// 当调用 [completeMultipartUpload] 方法尝试完成分片上传时出错。
  /// 可能的原因包括：
  /// - 某些分片未上传成功
  /// - 分片列表不完整或顺序错误
  /// - 分片ETag不匹配
  /// - uploadId无效或过期
  completeMultipartFailed,

  /// 文件系统错误 (例如文件不存在)
  ///
  /// 当操作本地文件系统时出现错误。这通常是由 [FileSystemException] 引起的。
  /// 可能的原因包括：
  /// - 要上传的文件不存在
  /// - 没有读取文件的权限
  /// - 下载文件时无法写入目标路径
  /// - 磁盘空间不足
  fileSystem,

  /// 初始化分片上传失败
  ///
  /// 当调用 [initiateMultipartUpload] 方法初始化分片上传时出错。
  /// 可能的原因包括：
  /// - 网络连接问题
  /// - 服务器端错误
  /// - 请求参数无效
  /// - 没有足够的权限创建分片上传
  initiateMultipartFailed,

  /// 请求参数错误
  ///
  /// 当提供给OSS操作的参数无效或不符合要求时抛出。
  /// 可能的原因包括：
  /// - 文件键（fileKey）为空或格式错误（如以“/”开头）
  /// - 分片大小或数量超出限制
  /// - 必需参数缺失
  /// - 参数值超出允许的范围
  invalidArgument,

  /// 无效的响应
  ///
  /// 当从 OSS 服务器收到的响应无法正确解析或处理时抛出。
  /// 可能的原因包括：
  /// - XML 响应格式错误或不完整
  /// - 响应中缺少必要的字段
  /// - 响应与请求的操作不匹配
  /// - 服务器返回了意外的状态码或内容
  invalidResponse,

  /// 网络错误 (例如 DioException)
  ///
  /// 当网络通信过程中出现问题时抛出。这通常是由 [DioException] 引起的。
  /// 可能的原因包括：
  /// - 网络连接中断或不可用
  /// - DNS 解析失败
  /// - 请求超时
  /// - SSL/TLS 证书错误
  /// - 代理服务器配置问题
  network,

  /// 请求的资源不存在
  ///
  /// 当请求的OSS资源不存在时抛出。通常对应HTTP 404状态码。
  /// 对应的OSS错误码包括：
  /// - NoSuchKey：请求的对象（文件）不存在
  /// - NoSuchBucket：请求的存储空间（Bucket）不存在
  /// - NoSuchUpload：指定的分片上传ID不存在或已经完成/取消
  notFound,

  /// 请求被取消
  ///
  /// 当请求被客户端主动取消时抛出。这通常是由于调用了 [cancelRequest] 或 [cancelAll] 方法。
  /// 在以下情况下可能出现：
  /// - 用户主动取消了操作（如上传或下载）
  /// - 应用程序在操作完成前退出
  /// - 应用程序决定中止长时间运行的操作
  requestCancelled,

  /// 服务端错误
  ///
  /// 当阿里云OSS服务器端发生错误时抛出。通常对应HTTP 5xx状态码。
  /// 可能的原因包括：
  /// - 服务器内部错误（InternalError）
  /// - 服务不可用（ServiceUnavailable）
  /// - 服务器资源不足
  /// - 服务器过载
  ///
  /// 这类错误通常是临时的，可以通过重试来解决。
  serverError,

  /// 签名错误
  ///
  /// 当请求的签名验证失败时抛出。通常对应HTTP 403状态码。
  /// 对应的OSS错误码包括：
  /// - SignatureDoesNotMatch：计算的签名与提供的签名不匹配
  /// - InvalidAccessKeyId：提供的 AccessKey ID 不存在或已失效
  ///
  /// 可能的原因包括：
  /// - AccessKey Secret 错误
  /// - 签名计算方法不正确
  /// - 请求头或参数格式错误
  /// - 客户端与服务器的时间不同步
  signatureMismatch,

  /// 未知错误
  ///
  /// 当错误无法分类为其他已知类型时使用。这是一个通用的错误类型，用于捕获未预期的错误情况。
  ///
  /// 当遇到此类错误时，应检查：
  /// - [OSSException.originalError] 以获取原始异常信息
  /// - [OSSException.message] 中的详细错误描述
  /// - 日志输出以获取更多上下文
  unknown,

  /// 上传分片失败
  ///
  /// 当调用 [uploadPart] 方法上传单个分片或在分片上传过程中出错时抛出。
  /// 可能的原因包括：
  /// - 网络连接问题
  /// - 服务器端错误
  /// - 分片数据损坏
  /// - uploadId 无效或过期
  /// - 分片编号无效
  ///
  /// 当使用 [multipartUpload] 方法时，如果任何分片上传失败，整个上传过程将被中止并抛出此错误。
  uploadPartFailed,

  // 可以根据需要添加更多具体的错误类型
}

/// 错误类型扩展方法
///
/// 提供了一些实用的工具方法，用于处理和展示 [OSSErrorType] 枚举值。
extension OSSErrorTypeExtension on OSSErrorType {
  /// 获取错误类型的用户友好描述
  ///
  /// 返回一个简洁的中文描述，适合在用户界面中显示。
  String get userFriendlyMessage {
    switch (this) {
      case OSSErrorType.abortMultipartFailed:
        return '取消分片上传失败';
      case OSSErrorType.accessDenied:
        return '访问被拒绝，请检查权限设置';
      case OSSErrorType.completeMultipartFailed:
        return '完成分片上传失败';
      case OSSErrorType.fileSystem:
        return '文件系统错误，请检查文件路径和权限';
      case OSSErrorType.initiateMultipartFailed:
        return '初始化分片上传失败';
      case OSSErrorType.invalidArgument:
        return '请求参数错误，请检查输入';
      case OSSErrorType.invalidResponse:
        return '服务器响应无效，请稍后重试';
      case OSSErrorType.network:
        return '网络错误，请检查网络连接';
      case OSSErrorType.notFound:
        return '请求的资源不存在';
      case OSSErrorType.requestCancelled:
        return '请求已取消';
      case OSSErrorType.serverError:
        return '服务器错误，请稍后重试';
      case OSSErrorType.signatureMismatch:
        return '签名验证失败，请检查访问凭证';
      case OSSErrorType.unknown:
        return '未知错误，请查看日志获取详情';
      case OSSErrorType.uploadPartFailed:
        return '上传分片失败，请重试';
    }
  }

  /// 判断错误是否可重试
  ///
  /// 返回一个布尔值，表示该错误类型是否适合自动重试。
  bool get isRetryable {
    switch (this) {
      // 这些错误类型通常是临时的，可以重试
      case OSSErrorType.network:
      case OSSErrorType.serverError:
      case OSSErrorType.uploadPartFailed:
      case OSSErrorType.completeMultipartFailed:
      case OSSErrorType.initiateMultipartFailed:
      case OSSErrorType.invalidResponse:
        return true;

      // 这些错误类型通常是由于客户端问题或配置错误导致的，重试不太可能解决
      case OSSErrorType.accessDenied:
      case OSSErrorType.fileSystem:
      case OSSErrorType.invalidArgument:
      case OSSErrorType.notFound:
      case OSSErrorType.requestCancelled:
      case OSSErrorType.signatureMismatch:
      case OSSErrorType.abortMultipartFailed:
      case OSSErrorType.unknown:
        return false;
    }
  }
}
