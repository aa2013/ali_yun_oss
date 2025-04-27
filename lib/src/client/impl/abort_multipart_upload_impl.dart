import 'package:dart_aliyun_oss/src/client/client.dart';
import 'package:dart_aliyun_oss/src/exceptions/exceptions.dart';
import 'package:dio/dio.dart';
import 'package:dart_aliyun_oss/src/interfaces/service.dart';
import 'package:dart_aliyun_oss/src/models/models.dart';

mixin AbortMultipartUploadImpl on IOSSService {
  /// 终止分片上传
  ///
  /// 取消一个进行中的分片上传,并删除已上传的分片。
  /// 该操作会尝试删除与指定 uploadId 关联的所有已上传分片。
  ///
  /// 注意事项：
  /// 1. 调用此接口会导致已上传的分片被删除,无法恢复
  /// 2. 如果部分分片正在上传中,可能无法被立即删除
  /// 3. 如果 uploadId 已完成或不存在,将返回 NoSuchUpload 错误
  /// 4. 建议在上传失败或需要取消时及时调用此接口以释放存储空间
  ///
  /// [fileKey] OSS 对象键,指定要终止上传的文件
  /// [uploadId] Upload ID,标识特定的分片上传事件
  /// [params] 可选的请求参数 ([OSSRequestParams]),可用于指定自定义请求头部等
  /// 返回一个 [Response]。成功时状态码为 204 No Content,响应体为空。
  ///
  /// 示例:
  /// ```dart
  /// try {
  ///   await client.abortMultipartUpload('example.zip', 'upload-id-xxx');
  ///   print('成功终止分片上传');
  /// } catch (e) {
  ///   print('终止分片上传失败: $e');
  /// }
  /// ```
  @override
  Future<Response<dynamic>> abortMultipartUpload(
    String fileKey,
    String uploadId, {
    OSSRequestParams? params,
  }) async {
    // 参数验证
    if (uploadId.isEmpty) {
      throw OSSException(
        type: OSSErrorType.invalidArgument,
        message: 'Upload ID 不能为空',
      );
    }
    if (fileKey.isEmpty) {
      throw OSSException(
        type: OSSErrorType.invalidArgument,
        message: 'File key 不能为空',
      );
    }

    final client = this as OSSClient;
    final String requestKey = '$fileKey-$uploadId-abort';

    return client.requestHandler.executeRequest(
      requestKey,
      params?.cancelToken,
      (CancelToken cancelToken) async {
        final String bucket = params?.bucketName ?? client.config.bucketName;
        final Map<String, String> queryParameters = {'uploadId': uploadId};

        // 使用 Uri.https 构建更高效
        final Uri uri = Uri.https(
          '$bucket.${client.config.endpoint}',
          fileKey,
          queryParameters,
        );

        // 复用基础请求头
        final Map<String, dynamic> baseHeaders = {
          ...(params?.options?.headers ?? {}),
        };

        final Map<String, dynamic> headers = client.createSignedHeaders(
          method: 'DELETE',
          bucketName: params?.bucketName,
          fileKey: fileKey,
          queryParameters: queryParameters,
          contentLength: 0,
          baseHeaders: baseHeaders,
          dateTime: params?.dateTime,
          isV1Signature: params?.isV1Signature ?? false,
        );

        final Options requestOptions = (params?.options ?? Options()).copyWith(
          headers: headers,
          // 添加超时设置
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        );

        final Response<dynamic> response =
            await client.requestHandler.sendRequest(
          uri: uri,
          method: 'DELETE',
          options: requestOptions,
          data: null,
          cancelToken: cancelToken,
        );

        return response;
      },
    );
  }
}
