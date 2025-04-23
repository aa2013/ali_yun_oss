import 'package:dart_aliyun_oss/src/client/client.dart';
import 'package:dart_aliyun_oss/src/exceptions/exceptions.dart';
import 'package:dio/dio.dart';
import 'package:dart_aliyun_oss/src/interfaces/service.dart';
import 'package:dart_aliyun_oss/src/models/models.dart';

mixin InitiateMultipartUploadImpl on IOSSService {
  /// 初始化分片上传
  ///
  /// 开始一个分片上传过程，获取 Upload ID。该接口用于通知 OSS 初始化一个分片上传事件。
  /// 
  /// 主要功能：
  /// - 创建分片上传事件并返回全局唯一的 Upload ID
  /// - 支持自定义请求参数和请求头
  /// - 支持请求取消功能
  /// 
  /// 注意事项：
  /// - 初始化请求不会影响已存在的同名对象
  /// - 返回的 Upload ID 用于后续的分片上传、完成或取消操作
  /// - 如果指定了加密请求头，后续的分片上传也会使用相同的加密方式
  /// - 每个 Upload ID 都有生命周期，建议及时完成或取消上传
  /// 
  /// 使用示例：
  /// ```dart
  /// final response = await client.initiateMultipartUpload(
  ///   'example.zip',
  ///   params: OSSRequestParams(
  ///     bucketName: 'custom-bucket',
  ///     options: Options(headers: {'x-oss-server-side-encryption': 'AES256'})
  ///   )
  /// );
  /// final uploadId = response.data?.uploadId;
  /// ```
  ///
  /// [fileKey] 要上传的 OSS 对象键
  /// [params] 可选的请求参数 ([OSSRequestParams])，可用于指定：
  ///   - bucketName: 自定义的 Bucket 名称
  ///   - options: 包含自定义请求头的选项
  ///   - cancelToken: 用于取消请求
  ///   - dateTime: 自定义签名时间
  ///   - isV1Signature: 是否使用 V1 签名
  /// 返回一个包含 [InitiateMultipartUploadResult] 的 [Response]，其中包含：
  ///   - Bucket: 存储空间名称
  ///   - Key: 对象名称
  ///   - UploadId: 分片上传事件的唯一标识
  @override
  Future<Response<InitiateMultipartUploadResult>> initiateMultipartUpload(
    String fileKey, {
    OSSRequestParams? params,
  }) async {
    // 参数验证
    if (fileKey.isEmpty) {
      throw OSSException(
        type: OSSErrorType.invalidArgument,
        message: 'File key 不能为空',
      );
    }
    if (fileKey.startsWith('/')) {
      throw OSSException(
        type: OSSErrorType.invalidArgument,
        message: 'File key 不能以 "/" 开头',
      );
    }

    final client = this as OSSClient;
    final String requestKey = 'init_${fileKey}_${DateTime.now().millisecondsSinceEpoch}';
    
    return client.requestHandler.executeRequest(
      requestKey,
      params?.cancelToken,
      (CancelToken cancelToken) async {
        final String bucket = params?.bucketName ?? client.config.bucketName;
        
        // 使用 Uri.https 构建 URI
        final Uri uri = Uri.https(
          '$bucket.${client.config.endpoint}',
          fileKey,
          {'uploads': ''}, // 查询参数更清晰的表示
        );

        final Map<String, dynamic> headers = client.createSignedHeaders(
          method: 'POST',
          bucketName: params?.bucketName,
          fileKey: fileKey,
          uri: uri,
          contentLength: 0,
          baseHeaders: params?.options?.headers ?? {},
          dateTime: params?.dateTime,
          isV1Signature: params?.isV1Signature ?? false,
        );

        final Options requestOptions = (params?.options ?? Options()).copyWith(
          headers: headers,
          responseType: ResponseType.plain,
        );

        try {
          final Response<dynamic> response = await client.requestHandler
              .sendRequest(
                uri: uri,
                method: 'POST',
                options: requestOptions,
                data: null,
                cancelToken: cancelToken,
              );

          final InitiateMultipartUploadResult result =
              InitiateMultipartUploadResult.fromXmlString(
                response.data as String,
              );

          return Response<InitiateMultipartUploadResult>(
            data: result,
            headers: response.headers,
            requestOptions: response.requestOptions,
            statusCode: response.statusCode,
            statusMessage: response.statusMessage,
            isRedirect: response.isRedirect,
            redirects: response.redirects,
            extra: response.extra,
          );
        } catch (e) {
          throw OSSException(
            type: OSSErrorType.initiateMultipartFailed,
            message: '初始化分片上传失败: ${e.toString()}',
            originalError: e,
            requestOptions: (e as DioException?)?.requestOptions,
          );
        }
      },
    );
  }
}
