import 'dart:io';
import 'package:dart_aliyun_oss/src/client/client.dart';
import 'package:dart_aliyun_oss/src/exceptions/exceptions.dart';
import 'package:dio/dio.dart';
import 'package:dart_aliyun_oss/src/interfaces/service.dart';
import 'package:dart_aliyun_oss/src/models/models.dart';

mixin PutObjectImpl on IOSSService {
  /// 阿里云 OSS 对象上传实现
  ///
  /// 提供简单上传功能,适用于小文件（建议小于100MB）。采用流式上传以优化内存使用。
  ///
  /// 主要特性：
  /// - 流式上传：避免一次性加载整个文件到内存
  /// - 进度监控：支持上传进度回调
  /// - 访问控制：支持设置对象ACL
  /// - 存储类型：支持指定存储类型
  /// - 版本控制：支持禁止覆盖同名文件（需要Bucket开启版本控制）
  ///
  /// 使用场景：
  /// - 小文件上传（如文档、图片等）
  /// - 需要实时监控上传进度
  /// - 需要特定访问控制或存储类型的场景
  ///
  /// 注意事项：
  /// - 大文件（>100MB）建议使用分片上传
  /// - 上传失败会自动重试,可通过 params 配置重试策略
  /// - 文件路径中的特殊字符需要进行URL编码
  ///
  /// 示例：
  /// ```dart
  /// final response = await client.putObject(
  ///   File('example.txt'),
  ///   'folder/example.txt',
  ///   acl: 'private',
  ///   storageClass: 'Standard',
  ///   onSendProgress: (count, total) {
  ///     print('Progress: ${count/total * 100}%');
  ///   }
  /// );
  /// ```

  /// 上传对象到OSS (简单上传,适用于小文件)
  ///
  /// 使用流式上传,避免将整个文件加载到内存。
  ///
  /// [file] 要上传的本地文件 ([File])
  /// [fileKey] 上传到 OSS 的对象键 (路径)
  /// [params] 可选的请求参数 ([OSSRequestParams])
  /// [acl] 对象访问控制列表 (如 'private', 'public-read')
  /// [storageClass] 存储类型 (如 'Standard', 'IA')
  /// [forbidOverride] 是否禁止覆盖同名文件 (需要 Bucket 版本控制支持)
  /// 返回一个 [Response],成功时通常响应体为空。
  @override
  Future<Response<dynamic>> putObject(
    File file,
    String fileKey, {
    OSSRequestParams? params,
    String? acl,
    String? storageClass,
    bool? forbidOverride,
  }) async {
    // 添加参数验证
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

    return client.requestHandler.executeRequest(fileKey, params?.cancelToken, (
      CancelToken cancelToken,
    ) async {
      try {
        // 检查文件是否存在
        if (!await file.exists()) {
          throw OSSException(
            type: OSSErrorType.invalidArgument,
            message: '文件不存在: ${file.path}',
          );
        }

        // 检查文件大小
        final fileLength = await file.length();
        if (fileLength > 100 * 1024 * 1024) {
          // 100MB
          print('警告: 文件大小超过100MB,建议使用分片上传');
        }

        final Uri uri = client.buildOssUri(
          bucket: params?.bucketName,
          fileKey: fileKey,
        );

        final Stream<List<int>> stream = file.openRead();
        final dynamic data = stream;
        final int contentLength = fileLength;

        final Map<String, dynamic> ossHeaders = {
          if (forbidOverride != null)
            'x-oss-forbid-overwrite': forbidOverride.toString(),
          if (acl != null) 'x-oss-object-acl': acl,
          if (storageClass != null) 'x-oss-storage-class': storageClass,
        };

        final Map<String, dynamic> baseHeaders = {
          ...ossHeaders,
          ...(params?.options?.headers ?? {}),
        };

        final Map<String, dynamic> headers = client.createSignedHeaders(
          method: 'PUT',
          bucketName: params?.bucketName,
          fileKey: fileKey,
          contentLength: contentLength,
          baseHeaders: baseHeaders,
          dateTime: params?.dateTime,
          isV1Signature: params?.isV1Signature ?? false,
        );

        final Options requestOptions = (params?.options ?? Options()).copyWith(
          headers: headers,
        );

        return client.requestHandler.sendRequest(
          uri: uri,
          method: 'PUT',
          options: requestOptions,
          data: data,
          cancelToken: cancelToken,
          onReceiveProgress: params?.onReceiveProgress,
          onSendProgress: params?.onSendProgress,
        );
      } catch (e) {
        throw OSSException(
          type: OSSErrorType.unknown,
          message: '上传失败: $e',
          originalError: e,
        );
      }
    });
  }
}
