import 'package:dart_aliyun_oss/src/client/client.dart';
import 'package:dart_aliyun_oss/src/exceptions/exceptions.dart';
import 'package:dio/dio.dart';
import 'package:dart_aliyun_oss/src/interfaces/service.dart';
import 'package:dart_aliyun_oss/src/models/models.dart';

/// GetObjectImpl 是阿里云 OSS 获取对象操作的实现
///
/// 该 mixin 提供了从 OSS 下载对象的核心功能,主要特点：
/// - 支持流式下载,避免一次性加载大文件到内存
/// - 支持进度回调,可监控下载进度
/// - 支持自定义请求参数和请求头
/// - 支持取消下载操作
/// - 兼容 V1 和 V4 签名算法
///
/// 使用注意：
/// 1. 该 mixin 需要与 IOSSService 一起使用
/// 2. 实现类需要提供 requestHandler 和 config 成员
/// 3. 默认使用 application/octet-stream 作为 Accept 头
/// 4. 返回的响应数据类型为字节数组 (ResponseType.bytes)
///
/// 示例:
/// ```dart
/// final response = await client.getObject(
///   'example.zip',
///   params: OSSRequestParams(
///     onReceiveProgress: (count, total) {
///       print('Progress: ${count/total * 100}%');
///     },
///   ),
/// );
/// await File('local/path/example.zip').writeAsBytes(response.data);
/// ```
mixin GetObjectImpl on IOSSService {
  @override
  Future<Response<dynamic>> getObject(
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

    final client = this as OSSClient;

    return client.requestHandler.executeRequest(fileKey, params?.cancelToken, (
      CancelToken cancelToken,
    ) async {
      final Uri uri = client.buildOssUri(
        bucket: params?.bucketName,
        fileKey: fileKey,
      );

      final Map<String, dynamic> baseHeaders = {
        'Accept': 'application/octet-stream',
        'Cache-Control': 'no-cache', // 添加缓存控制
        ...?params?.options?.headers, // 使用空安全展开运算符
      };

      // Access private method via the casted client instance
      final Map<String, dynamic> headers = client.createSignedHeaders(
        method: 'GET',
        bucketName: params?.bucketName,
        fileKey: fileKey,
        baseHeaders: baseHeaders,
        dateTime: params?.dateTime,
        isV1Signature: params?.isV1Signature ?? false,
      );

      final Options requestOptions = (params?.options ?? Options()).copyWith(
        headers: headers,
        responseType: ResponseType.bytes,
      );

      return client.requestHandler.sendRequest(
        uri: uri,
        method: 'GET',
        options: requestOptions,
        cancelToken: cancelToken,
        onReceiveProgress: params?.onReceiveProgress,
        onSendProgress: params?.onSendProgress,
      );
    });
  }

  /// 流式下载对象,适用于大文件
  ///
  /// [fileKey] OSS对象的键值
  /// [params] 可选的请求参数,包含下载进度回调等配置
  /// 返回一个 [Response] 对象,其中包含文件内容的字节流
  Future<Response<Stream<List<int>>>> getObjectStream(
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

    final client = this as OSSClient;

    return client.requestHandler.executeRequest<Response<Stream<List<int>>>>(
      fileKey,
      params?.cancelToken,
      (CancelToken cancelToken) async {
        final Uri uri = client.buildOssUri(
          bucket: params?.bucketName,
          fileKey: fileKey,
        );

        final Map<String, dynamic> baseHeaders = {
          'Accept': 'application/octet-stream',
          'Cache-Control': 'no-cache',
          ...?params?.options?.headers,
        };

        final Map<String, dynamic> headers = client.createSignedHeaders(
          method: 'GET',
          bucketName: params?.bucketName,
          fileKey: fileKey,
          baseHeaders: baseHeaders,
          dateTime: params?.dateTime,
          isV1Signature: params?.isV1Signature ?? false,
        );

        final Options requestOptions = (params?.options ?? Options()).copyWith(
          headers: headers,
          responseType: ResponseType.stream,
        );

        final response = await client.requestHandler.sendRequest(
          uri: uri,
          method: 'GET',
          options: requestOptions,
          cancelToken: cancelToken,
          onReceiveProgress: params?.onReceiveProgress,
          onSendProgress: params?.onSendProgress,
        );

        return response as Response<Stream<List<int>>>;
      },
    );
  }
}
