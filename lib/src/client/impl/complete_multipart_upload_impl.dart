import 'dart:convert';

import 'package:ali_yun_oss/src/client/client.dart';
import 'package:ali_yun_oss/src/exceptions/exceptions.dart';
import 'package:dio/dio.dart';
import 'package:ali_yun_oss/src/interfaces/service.dart';
import 'package:ali_yun_oss/src/models/models.dart';

/// 完成分片上传的实现类
///
/// 该类实现了分片上传完成的相关功能，用于将已上传的所有分片组合成最终的完整对象。
/// 主要功能包括：
/// - 验证并组合已上传的分片
/// - 生成完整的XML请求体
/// - 发送完成分片上传的请求
/// - 处理服务器响应
///
/// 注意事项：
/// 1. 所有分片必须已成功上传
/// 2. 分片号必须按升序排列
/// 3. 除最后一个分片外，其他分片大小必须大于等于100KB
/// 4. 一旦完成分片上传，该Upload ID将失效
///
/// 使用示例:
/// ```dart
/// final result = await client.completeMultipartUpload(
///   'example.zip',
///   'upload-id-xxx',
///   [part1, part2, part3],
/// );
/// ```
mixin CompleteMultipartUploadImpl on IOSSService {
  @override
  Future<Response<CompleteMultipartUploadResult>> completeMultipartUpload(
    String fileKey,
    String uploadId,
    List<PartInfo> parts, {
    String? encodingType,
    OSSRequestParams? params,
  }) async {
    // 添加参数验证
    if (fileKey.isEmpty) {
      throw OSSException(
        type: OSSErrorType.invalidArgument,
        message: 'File key 不能为空',
      );
    }
    if (uploadId.isEmpty) {
      throw OSSException(
        type: OSSErrorType.invalidArgument,
        message: 'Upload ID 不能为空',
      );
    }
    if (parts.isEmpty) {
      throw OSSException(
        type: OSSErrorType.invalidArgument,
        message: '分片列表不能为空',
      );
    }

    // 验证分片顺序
    for (int i = 0; i < parts.length - 1; i++) {
      if (parts[i].partNumber >= parts[i + 1].partNumber) {
        throw OSSException(
          type: OSSErrorType.invalidArgument,
          message: '分片必须按照分片号升序排列',
        );
      }
    }

    final client = this as OSSClient;
    final String requestKey = '$fileKey-$uploadId-complete';
    return client.requestHandler.executeRequest(
      requestKey,
      params?.cancelToken,
      (CancelToken cancelToken) async {
        final String bucket = params?.bucketName ?? client.config.bucketName;
        final Map<String, String> queryParameters = {
          'uploadId': uploadId,
          if (encodingType != null) 'encoding-type': encodingType,
        };
        final Uri uri = Uri.parse(
          'https://$bucket.${client.config.endpoint}/$fileKey',
        ).replace(queryParameters: queryParameters);

        // XML 相关常量
        // <?xml version="1.0" encoding="UTF-8"?> 等
        // <CompleteMultipartUpload> 开闭标签
        // 每个分片信息的估算长度

        // 创建 StringBuffer
        final StringBuffer xmlBuffer = StringBuffer();
        xmlBuffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
        xmlBuffer.writeln('<CompleteMultipartUpload>');
        for (final PartInfo part in parts) {
          xmlBuffer.writeln(part.toXmlFragment());
        }
        xmlBuffer.writeln('</CompleteMultipartUpload>');
        final String xmlBody = xmlBuffer.toString();
        final List<int> xmlBodyBytes = utf8.encode(xmlBody);

        final Map<String, dynamic> baseHeaders = {
          'Content-Type': 'application/xml',
          ...(params?.options?.headers ?? {}),
        };

        final Map<String, dynamic> headers = client.createSignedHeaders(
          method: 'POST',
          bucketName: params?.bucketName,
          fileKey: fileKey,
          uri: uri,
          contentLength: xmlBodyBytes.length,
          baseHeaders: baseHeaders,
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
                data: xmlBodyBytes,
                cancelToken: cancelToken,
              );

          final CompleteMultipartUploadResult result =
              CompleteMultipartUploadResult.fromXmlString(
                response.data as String,
              );

          // 验证响应结果
          if (result.location.isEmpty ||
              result.bucket.isEmpty ||
              result.key.isEmpty) {
            throw OSSException(
              type: OSSErrorType.serverError,
              message: '服务器返回的结果不完整',
            );
          }

          return Response<CompleteMultipartUploadResult>(
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
          if (e is DioException) {
            throw OSSException(
              type: OSSErrorType.network,
              message: '完成分片上传请求失败: ${e.message}',
              originalError: e,
            );
          }
          rethrow;
        }
      },
    );
  }
}
