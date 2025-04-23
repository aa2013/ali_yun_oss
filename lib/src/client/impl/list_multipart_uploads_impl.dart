import 'package:ali_yun_oss/src/client/client.dart';
import 'package:ali_yun_oss/src/exceptions/exceptions.dart';
import 'package:dio/dio.dart';
import 'package:ali_yun_oss/src/interfaces/service.dart';
import 'package:ali_yun_oss/src/models/models.dart';

mixin ListMultipartUploadsImpl on IOSSService {
  /// 列出所有进行中的分片上传事件
  ///
  /// 获取指定 Bucket 下所有未完成的分片上传任务。
  /// 该接口支持分页查询和条件过滤，可用于监控和管理分片上传任务。
  ///
  /// 主要功能：
  /// - 列出所有未完成的分片上传任务
  /// - 支持按前缀过滤（prefix）
  /// - 支持分组查询（delimiter）
  /// - 支持分页获取（maxUploads）
  /// - 支持断点续传场景
  ///
  /// 注意事项：
  /// - 返回的结果按照 Key 和 UploadId 排序
  /// - 如果有大量上传任务，建议使用分页参数
  /// - 如果指定了 delimiter，将返回 CommonPrefixes
  /// - 默认最多返回 1000 个上传任务
  ///
  /// [delimiter] 用于分组的定界符
  /// [encodingType] 响应体编码方式，支持 url 编码
  /// [keyMarker] 列出对象的起始位置
  /// [maxUploads] 返回的最大上传事件数量，默认 1000
  /// [prefix] 过滤对象键的前缀
  /// [uploadIdMarker] 列出上传事件的起始 Upload ID
  /// [params] 可选的请求参数 ([OSSRequestParams])
  /// 返回一个包含 [ListMultipartUploadsResult] 的 [Response]。
  @override
  Future<Response<ListMultipartUploadsResult>> listMultipartUploads({
    String? delimiter,
    String? encodingType,
    String? keyMarker,
    int? maxUploads,
    String? prefix,
    String? uploadIdMarker,
    OSSRequestParams? params,
  }) async {
    final client = this as OSSClient;
    final String bucketName = params?.bucketName ?? client.config.bucketName;
    final String requestKey = [
      'listMultipartUploads',
      bucketName,
      prefix,
      keyMarker,
      uploadIdMarker,
    ].where((e) => e != null && e.isNotEmpty).join('-');
    return client.requestHandler.executeRequest(
      requestKey,
      params?.cancelToken,
      (CancelToken cancelToken) async {
        if (maxUploads != null && (maxUploads < 1 || maxUploads > 1000)) {
          throw OSSException(
            type: OSSErrorType.invalidArgument,
            message: 'maxUploads 必须在 1-1000 之间',
          );
        }

        // 定义操作特定查询参数
        final Map<String, String> operationQuery = {
          'uploads': '', // 必须参数
          if (delimiter?.isNotEmpty ?? false) 'delimiter': delimiter!,
          if (encodingType?.isNotEmpty ?? false) 'encoding-type': encodingType!,
          if (keyMarker?.isNotEmpty ?? false) 'key-marker': keyMarker!,
          if (maxUploads != null) 'max-uploads': maxUploads.toString(),
          if (prefix?.isNotEmpty ?? false) 'prefix': prefix!,
          if (uploadIdMarker?.isNotEmpty ?? false)
            'upload-id-marker': uploadIdMarker!,
        };

        // 构建包含操作特定查询参数的 URI (操作针对 Bucket 根)
        final Uri uri = Uri.parse(
          'https://$bucketName.${client.config.endpoint}/', // 路径是根 '/'
        ).replace(queryParameters: operationQuery);

        // 准备基础 Headers
        final Map<String, dynamic> baseHeaders = {
          ...(params?.options?.headers ?? {}),
        };

        // 创建签名 Headers
        final Map<String, dynamic> headers = client.createSignedHeaders(
          method: 'GET',
          bucketName: params?.bucketName,
          fileKey: '', // 操作针对 Bucket，fileKey 为空
          uri: uri,
          contentLength: null, // GET 请求无 Content-Length
          baseHeaders: baseHeaders,
          dateTime: params?.dateTime,
          isV1Signature: params?.isV1Signature ?? false,
        );

        // 准备请求选项
        final Options requestOptions = (params?.options ?? Options()).copyWith(
          headers: headers,
          responseType: ResponseType.plain, // 期望接收 XML 字符串
        );

        // 发送 GET 请求
        final Response<dynamic> response = await client.requestHandler
            .sendRequest(
              uri: uri,
              method: 'GET',
              options: requestOptions,
              data: null,
              cancelToken: cancelToken,
            );

        // 解析 XML 响应体
        final ListMultipartUploadsResult result =
            ListMultipartUploadsResult.fromXmlString(response.data as String);

        // 返回包含解析结果的新 Response 对象
        return Response<ListMultipartUploadsResult>(
          data: result,
          headers: response.headers,
          requestOptions: response.requestOptions,
          statusCode: response.statusCode,
          statusMessage: response.statusMessage,
          isRedirect: response.isRedirect,
          redirects: response.redirects,
          extra: response.extra,
        );
      },
    );
  }
}
