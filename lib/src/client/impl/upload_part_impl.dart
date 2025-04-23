import 'package:ali_yun_oss/src/client/client.dart';
import 'package:ali_yun_oss/src/exceptions/exceptions.dart';
import 'package:dio/dio.dart';
import 'package:ali_yun_oss/src/interfaces/service.dart';
import 'package:ali_yun_oss/src/models/models.dart';

/// 分片上传实现类
///
/// 提供分片上传的核心功能，支持两种上传方式：
/// 1. 内存数据上传：适用于小文件或已加载到内存的数据
/// 2. 流式上传：适用于大文件，避免内存占用过高
///
/// 主要特性：
/// - 支持分片上传进度回调
/// - 自动处理签名和请求头生成
/// - 支持请求取消
/// - 兼容V1和V4签名算法
///
/// 使用注意事项：
/// 1. 分片编号(partNumber)必须从1开始且连续
/// 2. 每个分片大小(除最后一个)必须≥100KB
/// 3. 上传前必须已调用initiateMultipartUpload获取uploadId
/// 4. 成功上传后需记录返回的ETag用于完成分片上传
///
/// 参考文档：
/// [阿里云OSS分片上传文档](https://help.aliyun.com/document_detail/31996.html)
mixin UploadPartImpl on IOSSService {
  /// 上传分片
  ///
  /// 上传文件的一个分片。
  ///
  /// [fileKey] OSS 对象键
  /// [partData] 分片数据 ([List<int>])
  /// [partNumber] 分片编号 (从 1 开始)
  /// [uploadId] [initiateMultipartUpload] 返回的 Upload ID
  /// [params] 可选的请求参数 ([OSSRequestParams])
  /// [onSendProgress] 分片上传进度回调
  /// 返回一个 [Response]。成功时响应体为空，但 Headers 包含 ETag。
  @override
  Future<Response<dynamic>> uploadPart(
    String fileKey,
    List<int> partData,
    int partNumber,
    String uploadId, {
    OSSRequestParams? params,
    ProgressCallback? onSendProgress,
  }) async {
    // 添加参数验证
    if (fileKey.isEmpty) {
      throw OSSException(
        type: OSSErrorType.invalidArgument,
        message: 'fileKey不能为空',
      );
    }
    if (partNumber < 1 || partNumber > 10000) {
      throw OSSException(
        type: OSSErrorType.invalidArgument,
        message: 'partNumber必须在1-10000之间',
      );
    }
    if (uploadId.isEmpty) {
      throw OSSException(
        type: OSSErrorType.invalidArgument,
        message: 'uploadId不能为空',
      );
    }
    if (partData.isEmpty) {
      throw OSSException(
        type: OSSErrorType.invalidArgument,
        message: 'partData不能为空',
      );
    }
    final client = this as OSSClient;
    final String requestKey = '$fileKey-$uploadId-$partNumber';
    return client.requestHandler.executeRequest(
      requestKey,
      params?.cancelToken,
      (CancelToken cancelToken) async {
        final String bucket = params?.bucketName ?? client.config.bucketName;
        final Map<String, String> queryParameters = {
          'partNumber': partNumber.toString(),
          'uploadId': uploadId,
        };
        final Uri uri = Uri.parse(
          'https://$bucket.${client.config.endpoint}/$fileKey',
        ).replace(queryParameters: queryParameters);

        final Map<String, dynamic> baseHeaders = {
          ...(params?.options?.headers ?? {}),
        };

        final Map<String, dynamic> headers = client.createSignedHeaders(
          method: 'PUT',
          bucketName: params?.bucketName,
          fileKey: fileKey,
          uri: uri,
          contentLength: partData.length,
          baseHeaders: baseHeaders,
          dateTime: params?.dateTime,
          isV1Signature: params?.isV1Signature ?? false,
        );

        final Options requestOptions = (params?.options ?? Options()).copyWith(
          headers: headers,
        );

        final Response<dynamic> response = await client.requestHandler
            .sendRequest(
              uri: uri,
              method: 'PUT',
              options: requestOptions,
              data: partData,
              cancelToken: cancelToken,
              onSendProgress: onSendProgress,
            );

        return response;
      },
    );
  }

  /// 使用流式数据上传分片
  Future<Response<dynamic>> uploadPartStream(
    String fileKey,
    Stream<List<int>> dataStream,
    int contentLength,
    int partNumber,
    String uploadId, {
    OSSRequestParams? params,
    ProgressCallback? onSendProgress,
  }) async {
    // 添加参数验证
    if (contentLength <= 0) {
      throw OSSException(
        type: OSSErrorType.invalidArgument,
        message: 'contentLength必须大于0',
      );
    }

    final client = this as OSSClient;
    // 优化requestKey生成方式，避免时间戳冲突
    final String requestKey =
        'uploadPartStream_${fileKey}_${uploadId}_$partNumber';

    return client.requestHandler.executeRequest(
      requestKey,
      params?.cancelToken,
      (CancelToken effectiveToken) async {
        final String bucket = params?.bucketName ?? client.config.bucketName;
        final Map<String, String> queryParameters = {
          'partNumber': partNumber.toString(),
          'uploadId': uploadId,
        };
        final Uri uri = Uri.parse(
          'https://$bucket.${client.config.endpoint}/$fileKey',
        ).replace(queryParameters: queryParameters);

        final Map<String, dynamic> baseHeaders = {
          ...(params?.options?.headers ?? {}),
        };

        final Map<String, dynamic> headers = client.createSignedHeaders(
          method: 'PUT',
          bucketName: params?.bucketName, // Pass bucketName
          fileKey: fileKey,
          uri: uri,
          contentLength: contentLength,
          baseHeaders: baseHeaders,
          dateTime: params?.dateTime, // Pass dateTime
          isV1Signature: params?.isV1Signature ?? false, // Pass isV1Signature
        );

        final Options requestOptions = (params?.options ?? Options()).copyWith(
          headers: headers,
        );

        final Response<dynamic> response = await client.requestHandler
            .sendRequest(
              uri: uri,
              method: 'PUT',
              data: dataStream,
              options: requestOptions,
              cancelToken: effectiveToken,
              onSendProgress: onSendProgress,
            );

        return response;
      },
    );
  }
}
