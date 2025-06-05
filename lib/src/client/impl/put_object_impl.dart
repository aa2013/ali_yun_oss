import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_aliyun_oss/src/client/client.dart';
import 'package:dart_aliyun_oss/src/exceptions/exceptions.dart';
import 'package:dart_aliyun_oss/src/interfaces/service.dart';
import 'package:dart_aliyun_oss/src/models/models.dart';
import 'package:dio/dio.dart';

mixin PutObjectImpl on IOSSService {
  /// 阿里云 OSS 对象上传实现
  ///
  /// 提供简单上传功能,适用于小文件（建议小于100MB）。支持多种数据类型上传。
  ///
  /// 支持的数据类型：
  /// - [File] 本地文件对象 - 采用流式上传以优化内存使用
  /// - [String] 文本字符串数据 - 自动使用 UTF-8 编码
  /// - [Uint8List] 字节数组数据 - 直接作为请求体发送
  ///
  /// 主要特性：
  /// - 多类型支持：支持文件、字符串和字节数组上传
  /// - 流式上传：对于文件类型，避免一次性加载整个文件到内存
  /// - 进度监控：支持上传进度回调
  /// - 类型安全：严格的类型检查和错误处理
  ///
  /// 使用场景：
  /// - 小文件上传（如文档、图片等）
  /// - 文本内容上传（如配置文件、日志等）
  /// - 二进制数据上传（如图片字节、加密数据等）
  /// - 需要实时监控上传进度
  ///
  /// 注意事项：
  /// - 大文件（>100MB）建议使用分片上传
  /// - 上传失败会自动重试,可通过 params 配置重试策略
  /// - 文件路径中的特殊字符需要进行URL编码
  /// - 对于 [Uint8List] 类型，请注意内存使用，避免过大的数据导致内存溢出
  ///
  /// 示例：
  /// ```dart
  /// // 上传文件
  /// await client.putObject(File('example.txt'), 'folder/example.txt');
  ///
  /// // 上传字符串
  /// await client.putObject('Hello World', 'folder/greeting.txt');
  ///
  /// // 上传字节数组
  /// final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
  /// await client.putObject(bytes, 'folder/data.bin');
  /// ```

  /// 上传文件到OSS (简单上传,适用于小文件)
  ///
  /// 使用流式上传,避免将整个文件加载到内存。
  ///
  /// ### 参数
  /// - [file] 要上传的本地文件 ([File])
  /// - [fileKey] 上传到 OSS 的对象键 (路径)
  /// - [params] 可选的请求参数 ([OSSRequestParams])
  ///
  /// ### 返回值
  /// 返回一个 [Response],成功时通常响应体为空。
  ///
  /// ### 异常
  /// - [OSSException] 当参数无效或上传失败时抛出
  @override
  Future<Response<dynamic>> putObject(
    File file,
    String fileKey, {
    OSSRequestParams? params,
  }) async {
    // 添加参数验证
    if (fileKey.isEmpty) {
      throw const OSSException(
        type: OSSErrorType.invalidArgument,
        message: 'File key 不能为空',
      );
    }

    if (fileKey.startsWith('/')) {
      throw const OSSException(
        type: OSSErrorType.invalidArgument,
        message: 'File key 不能以 "/" 开头',
      );
    }

    final OSSClient client = this as OSSClient;

    return client.requestHandler.executeRequest(fileKey, params?.cancelToken, (
      CancelToken cancelToken,
    ) async {
      try {
        // 检查文件是否存在
        if (!file.existsSync()) {
          throw OSSException(
            type: OSSErrorType.invalidArgument,
            message: '文件不存在: ${file.path}',
          );
        }

        // 检查文件大小
        final int fileLength = file.lengthSync();
        if (fileLength > 100 * 1024 * 1024) {
          // 100MB
          log('警告: 文件大小超过100MB,建议使用分片上传', level: 800);
        }

        // 更新请求参数
        final OSSRequestParams updatedParams =
            params ?? const OSSRequestParams();

        final Uri uri = client.buildOssUri(
          bucket: updatedParams.bucketName,
          fileKey: fileKey,
          queryParameters: updatedParams.queryParameters,
        );

        final Stream<List<int>> stream = file.openRead();
        final dynamic data = stream;
        final int contentLength = fileLength;

        final Map<String, dynamic> baseHeaders = <String, dynamic>{
          ...(updatedParams.options?.headers ?? <String, dynamic>{}),
        };

        final Map<String, dynamic> headers = client.createSignedHeaders(
          method: 'PUT',
          fileKey: fileKey,
          contentLength: contentLength,
          baseHeaders: baseHeaders,
          params: updatedParams,
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

  /// 上传字符串内容到OSS (简单上传,适用于小文件)
  ///
  /// 将字符串内容使用 UTF-8 编码后上传到 OSS。
  ///
  /// ### 参数
  /// - [content] 要上传的字符串内容
  /// - [fileKey] 上传到 OSS 的对象键 (路径)
  /// - [params] 可选的请求参数 ([OSSRequestParams])
  ///
  /// ### 返回值
  /// 返回一个 [Response],成功时通常响应体为空。
  ///
  /// ### 异常
  /// - [OSSException] 当参数无效或上传失败时抛出
  Future<Response<dynamic>> putObjectFromString(
    String content,
    String fileKey, {
    OSSRequestParams? params,
  }) async {
    // 将字符串转换为 UTF-8 字节数组
    final Uint8List bytes = Uint8List.fromList(utf8.encode(content));

    // 调用字节数组上传方法
    return putObjectFromBytes(bytes, fileKey, params: params);
  }

  /// 上传字节数组到OSS (简单上传,适用于小文件)
  ///
  /// 将字节数组数据直接上传到 OSS。
  ///
  /// ### 参数
  /// - [bytes] 要上传的字节数组数据
  /// - [fileKey] 上传到 OSS 的对象键 (路径)
  /// - [params] 可选的请求参数 ([OSSRequestParams])
  ///
  /// ### 返回值
  /// 返回一个 [Response],成功时通常响应体为空。
  ///
  /// ### 异常
  /// - [OSSException] 当参数无效或上传失败时抛出
  Future<Response<dynamic>> putObjectFromBytes(
    Uint8List bytes,
    String fileKey, {
    OSSRequestParams? params,
  }) async {
    // 添加参数验证
    if (fileKey.isEmpty) {
      throw const OSSException(
        type: OSSErrorType.invalidArgument,
        message: 'File key 不能为空',
      );
    }

    if (fileKey.startsWith('/')) {
      throw const OSSException(
        type: OSSErrorType.invalidArgument,
        message: 'File key 不能以 "/" 开头',
      );
    }

    final OSSClient client = this as OSSClient;

    return client.requestHandler.executeRequest(fileKey, params?.cancelToken, (
      CancelToken cancelToken,
    ) async {
      try {
        // 检查数据大小
        final int contentLength = bytes.length;
        if (contentLength > 100 * 1024 * 1024) {
          // 100MB
          log('警告: 数据大小超过100MB,建议使用分片上传', level: 800);
        }

        // 更新请求参数
        final OSSRequestParams updatedParams =
            params ?? const OSSRequestParams();

        final Uri uri = client.buildOssUri(
          bucket: updatedParams.bucketName,
          fileKey: fileKey,
          queryParameters: updatedParams.queryParameters,
        );

        final Map<String, dynamic> baseHeaders = <String, dynamic>{
          ...(updatedParams.options?.headers ?? <String, dynamic>{}),
        };

        final Map<String, dynamic> headers = client.createSignedHeaders(
          method: 'PUT',
          fileKey: fileKey,
          contentLength: contentLength,
          baseHeaders: baseHeaders,
          params: updatedParams,
        );

        final Options requestOptions = (params?.options ?? Options()).copyWith(
          headers: headers,
        );

        return client.requestHandler.sendRequest(
          uri: uri,
          method: 'PUT',
          options: requestOptions,
          data: bytes,
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
