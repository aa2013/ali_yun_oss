import 'package:dart_aliyun_oss/src/client/client.dart';
import 'package:dart_aliyun_oss/src/exceptions/exceptions.dart';
import 'package:dio/dio.dart';
import 'package:dart_aliyun_oss/src/interfaces/service.dart';
import 'package:dart_aliyun_oss/src/models/models.dart';

mixin ListPartsImpl on IOSSService {
  /// 列出已上传的分片
  ///
  /// 获取指定 Upload ID 下已成功上传的分片列表。该接口用于查询特定分片上传事件下的已上传分片。
  /// 
  /// 主要功能：
  /// - 列出指定 Upload ID 下的所有已上传分片
  /// - 支持分页查询（通过 maxParts 和 partNumberMarker）
  /// - 支持自定义响应编码（通过 encodingType）
  /// - 返回分片的详细信息（分片号、大小、ETag等）
  /// 
  /// 注意事项：
  /// - 返回的分片列表按分片号升序排列
  /// - 如果有大量分片，建议使用分页参数
  /// - 默认最多返回 1000 个分片
  /// - 建议使用本地记录的分片信息，而不是依赖此接口的返回结果
  /// 
  /// 使用场景：
  /// - 断点续传时查询已上传的分片
  /// - 验证分片上传是否完整
  /// - 清理未完成的分片上传
  ///
  /// [fileKey] OSS 对象键
  /// [uploadId] Upload ID
  /// [encodingType] 响应体编码方式
  /// [maxParts] 返回的最大分片数量
  /// [partNumberMarker] 分片列表的起始位置标记
  /// [params] 可选的请求参数 ([OSSRequestParams])
  /// 返回一个包含 [ListPartsResult] 的 [Response]。
  @override
  Future<Response<ListPartsResult>> listParts(
    String fileKey,
    String uploadId, {
    String? encodingType,
    int? maxParts,
    int? partNumberMarker,
    OSSRequestParams? params,
  }) async {
    // 参数验证
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
    if (maxParts != null && (maxParts < 1 || maxParts > 1000)) {
      throw OSSException(
        type: OSSErrorType.invalidArgument,
        message: 'maxParts 必须在 1-1000 之间',
      );
    }
    if (partNumberMarker != null && partNumberMarker < 0) {
      throw OSSException(
        type: OSSErrorType.invalidArgument,
        message: 'partNumberMarker 不能小于 0',
      );
    }

    final client = this as OSSClient;
    // 使用更简洁的 requestKey
    final String requestKey = 'list_parts_${DateTime.now().millisecondsSinceEpoch}';
    
    return client.requestHandler.executeRequest(
      requestKey,
      params?.cancelToken,
      (CancelToken cancelToken) async {
        try {
          final String bucket = params?.bucketName ?? client.config.bucketName;
          // 预分配 Map 大小
          final Map<String, String> operationQuery = Map<String, String>.fromEntries([
            MapEntry('uploadId', uploadId),
            if (encodingType != null) MapEntry('encoding-type', encodingType),
            if (maxParts != null) MapEntry('max-parts', maxParts.toString()),
            if (partNumberMarker != null)
              MapEntry('part-number-marker', partNumberMarker.toString()),
          ]);
        final Uri uri = Uri.parse(
          'https://$bucket.${client.config.endpoint}/$fileKey',
        ).replace(queryParameters: operationQuery);

        final Map<String, dynamic> baseHeaders = {
          ...(params?.options?.headers ?? {}),
        };

        final Map<String, dynamic> headers = client.createSignedHeaders(
          method: 'GET',
          bucketName: params?.bucketName,
          fileKey: fileKey,
          uri: uri,
          contentLength: null,
          baseHeaders: baseHeaders,
          dateTime: params?.dateTime,
          isV1Signature: params?.isV1Signature ?? false,
        );

        final Options requestOptions = (params?.options ?? Options()).copyWith(
          headers: headers,
          responseType: ResponseType.plain,
        );

        final Response<dynamic> response = await client.requestHandler
            .sendRequest(
              uri: uri,
              method: 'GET',
              options: requestOptions,
              data: null,
              cancelToken: cancelToken,
            );

          try {
            final ListPartsResult result = ListPartsResult.fromXmlString(
              response.data as String,
            );
            return Response<ListPartsResult>(
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
              type: OSSErrorType.invalidResponse,
              message: 'XML 解析失败: ${e.toString()}',
              originalError: e,
            );
          }
        } catch (e) {
          if (e is OSSException) {
            rethrow;
          }
          throw OSSException(
            type: OSSErrorType.unknown,
            message: '列出分片失败: ${e.toString()}',
            originalError: e,
          );
        }
      },
    );
  }
}
