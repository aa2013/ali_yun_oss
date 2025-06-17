// ignore_for_file: avoid_print
import 'dart:async'; // 导入 async 包
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_aliyun_oss/dart_aliyun_oss.dart';
import 'package:dio/dio.dart';

import 'config.dart'; // 导入配置文件

/// 将 OSSClient 初始化移到全局或 main 函数顶部,以便所有示例函数都能访问
late final OSSClient oss;

/// 全局签名版本设置，默认使用 V1 签名
bool isV1Signature = true;

/// 获取当前签名版本名称
String get signatureVersionName => isV1Signature ? 'V1' : 'V4';

/// 选择签名版本
void selectSignatureVersion() {
  print('\n当前签名版本: $signatureVersionName');
  stdout.write('请选择签名版本 (1: V1签名, 4: V4签名, 回车保持当前设置): ');
  final String? versionChoice = stdin.readLineSync();

  if (versionChoice == '4') {
    isV1Signature = false;
    print('已切换到 V4 签名版本');
  } else if (versionChoice == '1') {
    isV1Signature = true;
    print('已切换到 V1 签名版本');
  } else {
    print('保持当前签名版本: $signatureVersionName');
  }
}

/// 示例 1: 简单上传
Future<void> _runSimpleUploadExample() async {
  print('\n--- 运行示例 1: 简单上传 ---');
  try {
    final File file = File('example/assets/example.txt');
    if (!file.existsSync()) {
      print('错误: 文件 ${file.path} 不存在');
      return;
    }

    await oss.putObject(
      file,
      'example/test_oss_put.txt',
      params: OSSRequestParams(
        isV1Signature: isV1Signature, // 使用全局签名版本设置
        onSendProgress: (int count, int total) {
          // 处理上传进度,用百分比展示
          if (total > 0) {
            print('上传进度: ${(count / total * 100).toStringAsFixed(2)}%');
          } else {
            print('上传进度: $count bytes');
          }
        },
      ),
    );
    print('文件上传成功');
  } catch (e) {
    print('文件上传失败: $e');
  }
  print('--- 示例 1 结束 ---\n');
}

/// 示例 1.1: 上传字符串内容
Future<void> _runStringUploadExample() async {
  print('\n--- 运行示例 1.1: 上传字符串内容 ---');
  try {
    final String content = '''
这是一个通过字符串上传的示例文件。
支持多行文本内容。
时间戳: ${DateTime.now()}
''';

    await oss.putObjectFromString(
      content,
      'example/string_upload_test.txt',
      params: OSSRequestParams(
        isV1Signature: isV1Signature, // 使用全局签名版本设置
        onSendProgress: (int count, int total) {
          // 处理上传进度,用百分比展示
          if (total > 0) {
            print('字符串上传进度: ${(count / total * 100).toStringAsFixed(2)}%');
          } else {
            print('字符串上传进度: $count bytes');
          }
        },
      ),
    );
    print('字符串内容上传成功');
    print('内容长度: ${content.length} 字符');
  } catch (e) {
    print('字符串上传失败: $e');
  }
  print('--- 示例 1.1 结束 ---\n');
}

/// 示例 1.2: 上传字节数组
Future<void> _runBytesUploadExample() async {
  print('\n--- 运行示例 1.2: 上传字节数组 ---');
  try {
    // 创建一个示例字节数组 (模拟二进制数据)
    final Uint8List bytes = Uint8List.fromList(<int>[
      // 文件头标识 (模拟PNG文件头)
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      // 一些示例数据
      ...List<int>.generate(1024, (int index) => index % 256),
    ]);

    await oss.putObjectFromBytes(
      bytes,
      'example/bytes_upload_test.bin',
      params: OSSRequestParams(
        isV1Signature: isV1Signature, // 使用全局签名版本设置
        onSendProgress: (int count, int total) {
          // 处理上传进度,用百分比展示
          if (total > 0) {
            print('字节数组上传进度: ${(count / total * 100).toStringAsFixed(2)}%');
          } else {
            print('字节数组上传进度: $count bytes');
          }
        },
      ),
    );
    print('字节数组上传成功');
    print('数据大小: ${bytes.length} 字节');
  } catch (e) {
    print('字节数组上传失败: $e');
  }
  print('--- 示例 1.2 结束 ---\n');
}

/// 示例 2: 下载文件
Future<void> _runDownloadExample() async {
  print('\n--- 运行示例 2: 下载文件 ---');
  try {
    const String ossObjectKey = 'example/test_oss_put.txt'; // 要下载的文件
    const String downloadPath = 'example/downloaded/example.txt'; // 保存路径

    final Response<dynamic> response = await oss.getObject(
      ossObjectKey,
      params: OSSRequestParams(
        isV1Signature: isV1Signature, // 使用全局签名版本设置
        onReceiveProgress: (int count, int total) {
          // 避免除以零
          if (total > 0) {
            print('下载进度: ${(count / total * 100).toStringAsFixed(2)}%');
          } else {
            print('下载进度: $count bytes (总大小未知)');
          }
        },
      ),
    );

    final File downloadFile = File(downloadPath);
    // 确保目录存在
    await downloadFile.parent.create(recursive: true);
    await downloadFile.writeAsBytes(response.data);

    print('文件下载成功,保存路径: $downloadPath');
  } catch (e) {
    print('文件下载失败: $e');
  }
  print('--- 示例 2 结束 ---\n');
}

/// 示例 3: 分片上传文件 (使用封装后的方法)
Future<void> _runMultipartUploadExample() async {
  print('\n--- 运行示例 3: 分片上传 (使用封装方法) ---');
  const String localFilePath = 'example/assets/large_file.bin'; // 本地文件路径
  const String ossObjectKey =
      'example/multipart_upload_example.bin'; // 上传到 OSS 的路径

  // 记录开始时间
  final DateTime startTime = DateTime.now();
  print('开始时间: $startTime');

  try {
    final File file = File(localFilePath);
    if (!file.existsSync()) {
      print('错误: 文件 $localFilePath 不存在');
      return;
    }

    print('开始分片上传 (封装方法): $localFilePath -> $ossObjectKey');

    // --- 调用封装后的 multipartUpload 方法 ---
    final Response<CompleteMultipartUploadResult> completeResponse =
        await oss.multipartUpload(
      file,
      ossObjectKey,
      // numberOfParts: 5, // 可选：传入期望的分片数
      params: OSSRequestParams(
        isV1Signature: isV1Signature, // 使用全局签名版本设置
        onSendProgress: (int count, int total) {
          if (total > 0) {
            print('  整体上传进度: ${(count / total * 100).toStringAsFixed(2)}%');
          } else {
            print('  整体上传进度: $count bytes');
          }
        },
      ),
      onPartProgress: (int partNumber, int count, int total) {
        if (total > 0) {
          // 可以选择性地打印分片进度,避免过多日志
          // print('    分片 $partNumber 上传进度: ${(count / total * 100).toStringAsFixed(2)}%');
        }
      },
      // cancelToken: myCancelToken, // 可选：传入 CancelToken
    );

    print('分片上传成功完成!');
    print('  OSS Location: ${completeResponse.data?.location}');
    print('  OSS Bucket: ${completeResponse.data?.bucket}');
    print('  OSS Key: ${completeResponse.data?.key}');
    print('  OSS ETag: ${completeResponse.data?.eTag}');

    // 获取并打印实际使用的分片数量
    final String? actualPartsCount = completeResponse.data?.eTag
        .split('-')
        .lastOrNull; // eTag 格式通常为 "xxx-N",其中 N 为分片数量
    if (actualPartsCount != null) {
      print('  实际分片数量: $actualPartsCount');
    }
  } catch (e) {
    // multipartUpload 方法内部已处理 abort,这里只需捕获最终错误
    print('分片上传失败: $e');
    if (e is OSSException) {
      print('  错误类型: ${e.type}');
      print('  原始响应: ${e.response}');
    }
  } finally {
    // 记录结束时间并计算耗时
    final DateTime endTime = DateTime.now();
    final Duration duration = endTime.difference(startTime);
    print('结束时间: $endTime');
    print('总耗时: ${duration.inSeconds} 秒 (${duration.inMilliseconds} 毫秒)');
  }
  print('--- 示例 3 结束 ---\n');
}

/// 示例 4: 列出已上传的分片 (手动输入 Object Key 和 Upload ID)
Future<void> _runListPartsExample() async {
  print('\n--- 运行示例 4: 列出已上传的分片 ---');

  // --- 从终端获取输入 ---
  String? ossObjectKey;
  while (ossObjectKey == null || ossObjectKey.isEmpty) {
    stdout.write(
      '请输入要查询的 Object Key (例如: example/multipart_upload_example.bin): ',
    );
    ossObjectKey = stdin.readLineSync();
    if (ossObjectKey == null || ossObjectKey.isEmpty) {
      print('错误: Object Key 不能为空。');
    }
  }

  String? uploadId;
  while (uploadId == null || uploadId.isEmpty) {
    stdout.write('请输入要查询的 Upload ID: ');
    uploadId = stdin.readLineSync();
    if (uploadId == null || uploadId.isEmpty) {
      print('错误: Upload ID 不能为空。');
    }
  }
  // --- 输入获取结束 ---

  print('\n尝试列出对象 \'$ossObjectKey\' (Upload ID: $uploadId) 的已上传分片...');

  try {
    // 可以添加分页参数 maxParts, partNumberMarker
    final Response<ListPartsResult> response = await oss.listParts(
      ossObjectKey, // 使用用户输入的 Key
      uploadId, // 使用用户输入的 Upload ID
      // maxParts: 10, // 可选：限制返回的分片数量
      // partNumberMarker: 5, // 可选：从指定分片号之后开始列出
      params: OSSRequestParams(
        isV1Signature: isV1Signature, // 使用全局签名版本设置
      ),
    );

    final ListPartsResult? result = response.data;
    if (result != null) {
      print('列出分片成功:');
      print('  Bucket: ${result.bucket}');
      print('  Key: ${result.key}');
      print('  Upload ID: ${result.uploadId}');
      print('  Next Part Number Marker: ${result.nextPartNumberMarker}');
      print('  Max Parts: ${result.maxParts}');
      print('  Is Truncated: ${result.isTruncated}');
      print('  Encoding Type: ${result.encodingType}');
      print('  Parts (${result.parts.length} 个):');
      for (final PartInfo part in result.parts) {
        print(
          '    - PartNumber: ${part.partNumber}, ETag: ${part.eTag}, Size: ${part.size}, LastModified: ${part.lastModified}',
        );
      }
    } else {
      print('列出分片失败,未收到有效数据。状态码: ${response.statusCode}');
    }
  } catch (e) {
    print('列出分片时出错: $e');
  }
  print('--- 示例 4 结束 ---\n');
}

/// 示例 5: 列出所有进行中的分片上传事件
Future<void> _runListMultipartUploadsExample() async {
  print('\n--- 运行示例 5: 列出所有进行中的分片上传事件 ---');
  try {
    print('尝试列出存储桶中所有进行中的分片上传...');
    // 可以添加过滤和分页参数: prefix, delimiter, keyMarker, uploadIdMarker, maxUploads
    final Response<ListMultipartUploadsResult> response =
        await oss.listMultipartUploads(
      // prefix: 'example/', // 可选：只列出指定前缀的
      // maxUploads: 5, // 可选：限制返回数量
      params: OSSRequestParams(
        isV1Signature: isV1Signature, // 使用全局签名版本设置
      ),
    );

    final ListMultipartUploadsResult? result = response.data;
    if (result != null) {
      print('列出进行中的分片上传成功:');
      print('  Bucket: ${result.bucket}');
      print('  Prefix: ${result.prefix}');
      print('  Delimiter: ${result.delimiter}');
      print('  Key Marker: ${result.keyMarker}');
      print('  Upload ID Marker: ${result.uploadIdMarker}');
      print('  Next Key Marker: ${result.nextKeyMarker}');
      print('  Next Upload ID Marker: ${result.nextUploadIdMarker}');
      print('  Max Uploads: ${result.maxUploads}');
      print('  Is Truncated: ${result.isTruncated}');
      print('  Encoding Type: ${result.encodingType}');
      print('  Uploads (${result.uploads.length} 个):');
      for (final UploadInfo upload in result.uploads) {
        print(
          '    - Key: ${upload.key}, Upload ID: ${upload.uploadId}, Initiated: ${upload.initiated}',
        );
      }
      print('  Common Prefixes (${result.commonPrefixes.length} 个):');
      for (final String prefix in result.commonPrefixes) {
        print('    - $prefix');
      }
    } else {
      print('列出进行中的分片上传失败,未收到有效数据。状态码: ${response.statusCode}');
    }
  } catch (e) {
    print('列出进行中的分片上传时出错: $e');
  }
  print('--- 示例 5 结束 ---\n');
}

/// 示例 6: 终止分片上传 (手动输入 Object Key 和 Upload ID)
Future<void> _runAbortMultipartUploadExample() async {
  print('\n--- 运行示例 6: 终止分片上传 ---');

  // --- 从终端获取输入 ---
  String? ossObjectKey;
  while (ossObjectKey == null || ossObjectKey.isEmpty) {
    stdout.write('请输入要终止上传的 Object Key: ');
    ossObjectKey = stdin.readLineSync();
    if (ossObjectKey == null || ossObjectKey.isEmpty) {
      print('错误: Object Key 不能为空。');
    }
  }

  String? uploadId;
  while (uploadId == null || uploadId.isEmpty) {
    stdout.write('请输入要终止上传的 Upload ID: ');
    uploadId = stdin.readLineSync();
    if (uploadId == null || uploadId.isEmpty) {
      print('错误: Upload ID 不能为空。');
    }
  }
  // --- 输入获取结束 ---

  try {
    // 直接尝试终止用户指定的分片上传
    print('\n尝试终止对象 \'$ossObjectKey\' 的分片上传 (Upload ID: $uploadId)...');
    await oss.abortMultipartUpload(
      ossObjectKey,
      uploadId,
      params: OSSRequestParams(
        isV1Signature: isV1Signature, // 使用全局签名版本设置
      ),
    );
    print('分片上传 (Upload ID: $uploadId) 已成功终止。');
  } catch (e) {
    print('终止分片上传过程中出错: $e');
  }
  print('--- 示例 6 结束 ---\n');
}

/// 示例 7: 生成签名 URL
///
/// 使用 OSSClient.signedUrl 方法生成签名 URL，根据全局设置使用 V1 或 V4 签名算法。
Future<void> _runGenerateSignedUrlExample() async {
  print('\n--- 运行示例 7: 生成$signatureVersionName签名 URL ---');

  // 设置签名参数
  const String ossObjectKey = 'example/test_oss_put.txt'; // 要访问的对象

  // 让用户选择过期时间
  stdout.write('请输入 URL 有效期（秒，默认 3600）: ');
  final String? expiresInput = stdin.readLineSync();
  final int expires = int.tryParse(expiresInput ?? '') ?? 3600;

  // 让用户选择 HTTP 方法
  stdout.write('请选择 HTTP 方法 (1: GET, 2: PUT, 3: POST, 4: DELETE, 默认: GET): ');
  final String? methodChoice = stdin.readLineSync();

  String method;
  switch (methodChoice) {
    case '2':
      method = 'PUT';
      break;
    case '3':
      method = 'POST';
      break;
    case '4':
      method = 'DELETE';
      break;
    default:
      method = 'GET';
  }

  print('\n正在生成 $signatureVersionName 签名 URL...');
  print('  对象: $ossObjectKey');
  print('  HTTP 方法: $method');
  print('  有效期: $expires 秒');

  try {
    // 使用 OSSClient.signedUrl 方法生成签名 URL，使用全局签名版本设置
    final String signedUrl = oss.signedUrl(
      ossObjectKey,
      method: method,
      expires: expires,
      isV1Signature: isV1Signature, // 使用全局签名版本设置
      // headers: {'x-oss-meta-custom': 'value'}, // 可选：添加需要签名的头部
      // additionalHeaders: {'x-oss-meta-author'}, // 可选：指定需要参与签名的额外头部名称（仅 V4 签名）
    );

    print('\n生成的 $signatureVersionName 签名 URL (有效期 $expires 秒):');
    print(signedUrl);
    print('\n请尝试在浏览器中打开此 URL (如果对象存在且权限正确)');
  } catch (e) {
    print('生成 $signatureVersionName 签名 URL 失败: $e');
  }
  print('--- 示例 7 结束 ---\n');
}

/// 示例 8: 生成带自定义查询参数的签名 URL
///
/// 演示如何在签名URL中添加自定义查询参数，特别是图片处理参数
Future<void> _runCustomQueryParamsExample() async {
  print('\n--- 运行示例 8: 生成带自定义查询参数的$signatureVersionName签名 URL ---');

  // 让用户选择示例类型
  print('\n请选择自定义查询参数示例类型:');
  print('  1: 图片处理 - 缩放');
  print('  2: 图片处理 - 复杂处理');
  print('  3: 文档下载 - 自定义响应头');
  print('  4: 视频截帧');
  print('  5: 自定义参数');
  stdout.write('请选择 (默认: 1): ');

  final String? typeChoice = stdin.readLineSync();

  String objectKey;
  Map<String, String> queryParams;
  String description;

  switch (typeChoice) {
    case '2':
      objectKey = 'images/photo.jpg';
      queryParams = <String, String>{
        'x-oss-process': 'image/resize,w_200,h_200/quality,q_80/format,webp',
      };
      description = '复杂图片处理 (缩放+质量+格式转换)';
      break;
    case '3':
      objectKey = 'documents/report.pdf';
      queryParams = <String, String>{
        'response-content-type': 'application/pdf',
        'response-content-disposition': 'attachment; filename="report.pdf"',
        'response-cache-control': 'no-cache',
      };
      description = '文档下载 (自定义响应头)';
      break;
    case '4':
      objectKey = 'videos/movie.mp4';
      queryParams = <String, String>{
        'x-oss-process': 'video/snapshot,t_10000,f_jpg,w_800,h_600',
      };
      description = '视频截帧 (10秒处截取800x600的JPG图片)';
      break;
    case '5':
      stdout.write('请输入对象键 (例如: test.jpg): ');
      objectKey = stdin.readLineSync() ?? 'test.jpg';
      stdout.write('请输入参数名: ');
      final String paramName = stdin.readLineSync() ?? 'custom-param';
      stdout.write('请输入参数值: ');
      final String paramValue = stdin.readLineSync() ?? 'custom-value';
      queryParams = <String, String>{paramName: paramValue};
      description = '自定义参数';
      break;
    default:
      objectKey = 'images/photo.jpg';
      queryParams = <String, String>{
        'x-oss-process': 'image/resize,l_100',
      };
      description = '图片缩放 (限制长边为100像素)';
  }

  print('\n正在生成带自定义查询参数的 $signatureVersionName 签名 URL...');
  print('  对象: $objectKey');
  print('  描述: $description');
  print('  查询参数: $queryParams');

  try {
    final String signedUrl = oss.signedUrl(
      objectKey,
      queryParameters: queryParams,
      isV1Signature: isV1Signature,
    );

    print('\n生成的 $signatureVersionName 签名 URL (包含自定义查询参数):');
    print(signedUrl);

    // 解析URL以显示查询参数
    final Uri uri = Uri.parse(signedUrl);
    print('\n查询参数详情:');
    uri.queryParameters.forEach((String key, String value) {
      if (queryParams.containsKey(key)) {
        print('  ✅ 自定义参数: $key = $value');
      } else {
        print(
          '  🔐 签名参数: $key = ${value.length > 20 ? '${value.substring(0, 20)}...' : value}',
        );
      }
    });

    print('\n💡 提示: 此URL可以直接在浏览器中访问，OSS会根据查询参数处理文件');
  } catch (e) {
    print('生成带自定义查询参数的 $signatureVersionName 签名 URL 失败: $e');
  }
  print('--- 示例 8 结束 ---\n');
}

/// STS令牌管理器示例
///
/// 演示如何实现动态STS令牌刷新功能
class StsTokenManager {
  String? _accessKeyId;
  String? _accessKeySecret;
  String? _securityToken;
  DateTime? _expireTime;

  /// 获取当前有效的访问密钥ID
  String get accessKeyId {
    _refreshIfNeeded();
    return _accessKeyId!;
  }

  /// 获取当前有效的访问密钥Secret
  String get accessKeySecret {
    _refreshIfNeeded();
    return _accessKeySecret!;
  }

  /// 获取当前有效的安全令牌
  String? get securityToken {
    _refreshIfNeeded();
    return _securityToken;
  }

  /// 检查是否需要刷新令牌，如果需要则自动刷新
  void _refreshIfNeeded() {
    if (_expireTime == null ||
        DateTime.now()
            .isAfter(_expireTime!.subtract(const Duration(minutes: 5)))) {
      _refreshStsToken();
    }
  }

  /// 刷新STS令牌
  ///
  /// 在实际应用中，这里应该调用您的STS服务来获取新的临时凭证
  void _refreshStsToken() {
    print('🔄 刷新STS令牌...');

    // 模拟调用STS服务获取新令牌
    // 在实际应用中，您需要替换为真实的STS API调用
    _accessKeyId =
        'STS.mock_access_key_id_${DateTime.now().millisecondsSinceEpoch}';
    _accessKeySecret =
        'mock_access_key_secret_${DateTime.now().millisecondsSinceEpoch}';
    _securityToken =
        'mock_security_token_${DateTime.now().millisecondsSinceEpoch}';
    _expireTime = DateTime.now().add(const Duration(hours: 1)); // 假设令牌1小时后过期

    print('✅ STS令牌刷新完成，过期时间: $_expireTime');
  }
}

/// 主函数,提供交互式菜单运行示例
Future<void> main() async {
  // --- 初始化 OSSClient ---

  // 方式1：使用静态配置（传统方式）
  print('📋 初始化OSS客户端...');
  oss = OSSClient.init(
    OSSConfig.static(
      accessKeyId: OssConfig.accessKeyId,
      accessKeySecret: OssConfig.accessKeySecret,
      bucketName: OssConfig.bucket,
      endpoint: OssConfig.endpoint,
      region: OssConfig.region, // V4 签名需要 region,
    ),
    // connectTimeout: Duration(seconds: 30), // 可选：连接超时时间
    // receiveTimeout: Duration(minutes: 5), // 可选：接收超时时间
  );

  // 方式2：使用动态STS令牌（推荐用于STS场景）
  // 取消注释以下代码来使用STS动态刷新功能：
  /*
  final stsManager = StsTokenManager();
  oss = OSSClient.init(
    OSSConfig(
      accessKeyIdProvider: () => stsManager.accessKeyId,
      accessKeySecretProvider: () => stsManager.accessKeySecret,
      securityTokenProvider: () => stsManager.securityToken,
      bucketName: OssConfig.bucket,
      endpoint: OssConfig.endpoint,
      region: OssConfig.region,
    ),
  );
  */

  print('OSS Client 初始化成功:');
  print('  Endpoint: ${oss.config.endpoint}');
  print('  Bucket: ${oss.config.bucketName}');
  print('  Region: ${oss.config.region}');
  print('------------------------------------\n');

  // 确保示例资源目录存在
  Directory('example/assets').createSync(recursive: true);
  // 创建一个用于上传的示例文件 (如果不存在)
  final File exampleFile = File('example/assets/example.txt');
  if (!exampleFile.existsSync()) {
    await exampleFile.writeAsString('这是一个用于测试 OSS 上传的示例文本文件。');
    print('创建了示例文件: ${exampleFile.path}');
  }
  // 创建一个用于分片上传的大文件 (如果不存在)
  final File largeFile = File('example/assets/large_file.bin');
  if (!largeFile.existsSync()) {
    print('正在创建用于分片上传的大文件 (约 10MB)...');
    final List<int> randomContent = List<int>.generate(
      10 * 1024 * 1024,
      (int index) => index % 256,
    );
    await largeFile.writeAsBytes(randomContent);
    print('创建了大文件: ${largeFile.path}');
  }

  // 交互式菜单
  while (true) {
    print('\n请选择要运行的示例:');
    print('  0: 切换签名版本 (当前: $signatureVersionName)');
    print('  1: 文件上传 (File)');
    print('  1.1: 字符串上传 (String)');
    print('  1.2: 字节数组上传 (Uint8List)');
    print('  2: 下载文件');
    print('  3: 分片上传 (使用封装方法)');
    print('  4: 列出已上传的分片 (需手动输入)');
    print('  5: 列出所有进行中的分片上传');
    print('  6: 中止分片上传 (需手动输入)');
    print('  7: 生成签名 URL');
    print('  8: 生成带自定义查询参数的签名 URL');
    print('  q: 退出');
    stdout.write('请输入选项: ');

    final String? choice = stdin.readLineSync();

    switch (choice) {
      case '0':
        selectSignatureVersion();
        break;
      case '1':
        await _runSimpleUploadExample();
        break;
      case '1.1':
        await _runStringUploadExample();
        break;
      case '1.2':
        await _runBytesUploadExample();
        break;
      case '2':
        await _runDownloadExample();
        break;
      case '3':
        await _runMultipartUploadExample();
        break;
      case '4':
        await _runListPartsExample();
        break;
      case '5':
        await _runListMultipartUploadsExample();
        break;
      case '6':
        await _runAbortMultipartUploadExample();
        break;
      case '7':
        await _runGenerateSignedUrlExample();
        break;
      case '8':
        await _runCustomQueryParamsExample();
        break;
      case 'q':
      case 'Q':
        print('退出程序。');
        return; // 退出 main 函数
      default:
        print('无效的选项,请重新输入。');
    }

    // 添加短暂延迟,避免连续输出导致混乱
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}
