import 'dart:io';

import 'package:ali_yun_oss/ali_yun_oss.dart';

/// 将 OSSClient 初始化移到全局或 main 函数顶部，以便所有示例函数都能访问
late final OSSClient oss;

/// 示例 1: 简单上传
Future<void> _runSimpleUploadExample() async {
  print("\n--- 运行示例 1: 简单上传 ---");
  try {
    final file = File('example/assets/example.txt');
    if (!await file.exists()) {
      print('错误: 文件 ${file.path} 不存在');
      return;
    }

    await oss.putObject(
      file,
      'example/test_oss_put.txt',
      onSendProgress: (int count, int total) {
        // 处理上传进度，用百分比展示
        if (total > 0) {
          print('上传进度: ${(count / total * 100).toStringAsFixed(2)}%');
        } else {
          print('上传进度: $count bytes');
        }
      },
    );
    print('文件上传成功');
  } catch (e) {
    print('文件上传失败: $e');
  }
  print("--- 示例 1 结束 ---\n");
}

/// 示例 2: 下载文件
Future<void> _runDownloadExample() async {
  print("\n--- 运行示例 2: 下载文件 ---");
  try {
    final ossObjectKey = 'example/example.txt'; // 要下载的文件
    final downloadPath = 'example/downloaded/example.txt'; // 保存路径

    final response = await oss.getObject(
      ossObjectKey,
      params: OSSRequestParams(
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

    print('文件下载成功，保存路径: $downloadPath');
  } catch (e) {
    print('文件下载失败: $e');
  }
  print("--- 示例 2 结束 ---\n");
}

/// 示例 3: 分片上传文件 (使用封装后的方法)
Future<void> _runMultipartUploadExample() async {
  print("\n--- 运行示例 3: 分片上传 (使用封装方法) ---");
  final String localFilePath = 'example/assets/large_file.bin'; // 本地文件路径
  final String ossObjectKey =
      'example/multipart_upload_example.bin'; // 上传到 OSS 的路径

  // 记录开始时间
  final startTime = DateTime.now();
  print('开始时间: $startTime');

  try {
    final file = File(localFilePath);
    if (!await file.exists()) {
      print('错误: 文件 $localFilePath 不存在');
      return;
    }

    print('开始分片上传 (封装方法): $localFilePath -> $ossObjectKey');

    // --- 调用封装后的 multipartUpload 方法 ---
    final completeResponse = await oss.multipartUpload(
      file,
      ossObjectKey,
      // numberOfParts: 5, // 可选：传入期望的分片数
      onProgress: (count, total) {
        if (total > 0) {
          print(
            '  整体上传进度: ${(count / total * 100).toStringAsFixed(2)}% ($count/$total bytes)',
          );
        } else {
          print('  整体上传进度: $count bytes');
        }
      },
      onPartProgress: (partNumber, count, total) {
        if (total > 0) {
          // 可以选择性地打印分片进度，避免过多日志
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
    final actualPartsCount =
        completeResponse.data?.eTag
            .split('-')
            .lastOrNull; // eTag 格式通常为 "xxx-N"，其中 N 为分片数量
    if (actualPartsCount != null) {
      print('  实际分片数量: $actualPartsCount');
    }
  } catch (e) {
    // multipartUpload 方法内部已处理 abort，这里只需捕获最终错误
    print('分片上传失败: $e');
    if (e is OSSException) {
      print('  错误类型: ${e.type}');
      print('  原始响应: ${e.response}');
    }
  } finally {
    // 记录结束时间并计算耗时
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print('结束时间: $endTime');
    print('总耗时: ${duration.inSeconds} 秒 (${duration.inMilliseconds} 毫秒)');
  }
  print("--- 示例 3 结束 ---\n");
}

/// 示例 4: 列出已上传的分片 (手动输入 Object Key 和 Upload ID)
Future<void> _runListPartsExample() async {
  print("\n--- 运行示例 4: 列出已上传的分片 ---");

  // --- 从终端获取输入 ---
  String? ossObjectKey;
  while (ossObjectKey == null || ossObjectKey.isEmpty) {
    stdout.write(
      "请输入要查询的 Object Key (例如: example/multipart_upload_example.bin): ",
    );
    ossObjectKey = stdin.readLineSync();
    if (ossObjectKey == null || ossObjectKey.isEmpty) {
      print("错误: Object Key 不能为空。");
    }
  }

  String? uploadId;
  while (uploadId == null || uploadId.isEmpty) {
    stdout.write("请输入要查询的 Upload ID: ");
    uploadId = stdin.readLineSync();
    if (uploadId == null || uploadId.isEmpty) {
      print("错误: Upload ID 不能为空。");
    }
  }
  // --- 输入获取结束 ---

  print("\n尝试列出对象 '$ossObjectKey' (Upload ID: $uploadId) 的已上传分片...");

  try {
    // 可以添加分页参数 maxParts, partNumberMarker
    final response = await oss.listParts(
      ossObjectKey, // 使用用户输入的 Key
      uploadId, // 使用用户输入的 Upload ID
      // maxParts: 10, // 可选：限制返回的分片数量
      // partNumberMarker: 5, // 可选：从指定分片号之后开始列出
    );

    final result = response.data;
    if (result != null) {
      print("列出分片成功:");
      print("  Bucket: ${result.bucket}");
      print("  Key: ${result.key}");
      print("  Upload ID: ${result.uploadId}");
      print("  Next Part Number Marker: ${result.nextPartNumberMarker}");
      print("  Max Parts: ${result.maxParts}");
      print("  Is Truncated: ${result.isTruncated}");
      print("  Encoding Type: ${result.encodingType}");
      print("  Parts (${result.parts.length} 个):");
      for (var part in result.parts) {
        print(
          "    - PartNumber: ${part.partNumber}, ETag: ${part.eTag}, Size: ${part.size}, LastModified: ${part.lastModified}",
        );
      }
    } else {
      print("列出分片失败，未收到有效数据。状态码: ${response.statusCode}");
    }
  } catch (e) {
    print('列出分片时出错: $e');
  }
  print("--- 示例 4 结束 ---\n");
}

/// 示例 5: 列出所有进行中的分片上传事件
Future<void> _runListMultipartUploadsExample() async {
  print("\n--- 运行示例 5: 列出所有进行中的分片上传事件 ---");
  try {
    print("尝试列出存储桶中所有进行中的分片上传...");
    // 可以添加过滤和分页参数: prefix, delimiter, keyMarker, uploadIdMarker, maxUploads
    final response = await oss.listMultipartUploads(
      // prefix: 'example/', // 可选：只列出指定前缀的
      // maxUploads: 5, // 可选：限制返回数量
    );

    final result = response.data;
    if (result != null) {
      print("列出进行中的分片上传成功:");
      print("  Bucket: ${result.bucket}");
      print("  Prefix: ${result.prefix}");
      print("  Delimiter: ${result.delimiter}");
      print("  Key Marker: ${result.keyMarker}");
      print("  Upload ID Marker: ${result.uploadIdMarker}");
      print("  Next Key Marker: ${result.nextKeyMarker}");
      print("  Next Upload ID Marker: ${result.nextUploadIdMarker}");
      print("  Max Uploads: ${result.maxUploads}");
      print("  Is Truncated: ${result.isTruncated}");
      print("  Encoding Type: ${result.encodingType}");
      print("  Uploads (${result.uploads.length} 个):");
      for (var upload in result.uploads) {
        print(
          "    - Key: ${upload.key}, Upload ID: ${upload.uploadId}, Initiated: ${upload.initiated}",
        );
      }
      print("  Common Prefixes (${result.commonPrefixes.length} 个):");
      for (var prefix in result.commonPrefixes) {
        print("    - $prefix");
      }
    } else {
      print("列出进行中的分片上传失败，未收到有效数据。状态码: ${response.statusCode}");
    }
  } catch (e) {
    print('列出进行中的分片上传时出错: $e');
  }
  print("--- 示例 5 结束 ---\n");
}

/// 示例 6: 终止分片上传 (手动输入 Object Key 和 Upload ID)
Future<void> _runAbortMultipartUploadExample() async {
  print("\n--- 运行示例 6: 终止分片上传 ---");

  // --- 从终端获取输入 ---
  String? ossObjectKey;
  while (ossObjectKey == null || ossObjectKey.isEmpty) {
    stdout.write("请输入要终止上传的 Object Key: ");
    ossObjectKey = stdin.readLineSync();
    if (ossObjectKey == null || ossObjectKey.isEmpty) {
      print("错误: Object Key 不能为空。");
    }
  }

  String? uploadId;
  while (uploadId == null || uploadId.isEmpty) {
    stdout.write("请输入要终止上传的 Upload ID: ");
    uploadId = stdin.readLineSync();
    if (uploadId == null || uploadId.isEmpty) {
      print("错误: Upload ID 不能为空。");
    }
  }
  // --- 输入获取结束 ---

  try {
    // 直接尝试终止用户指定的分片上传
    print("\n尝试终止对象 '$ossObjectKey' 的分片上传 (Upload ID: $uploadId)...");
    await oss.abortMultipartUpload(ossObjectKey, uploadId);
    print('分片上传 (Upload ID: $uploadId) 已成功终止。');
  } catch (e) {
    print('终止分片上传过程中出错: $e');
  }
  print("--- 示例 6 结束 ---\n");
}

// 修改 main 函数以提供交互式菜单
void main() async {
  // 初始化OSS服务
  // !!! 安全警告: 请勿在生产环境中硬编码 AccessKey !!!
  // 推荐使用环境变量、配置文件或更安全的凭证管理方式。
  oss = OSSClient.init(
    OSSConfig(
      endpoint:
          'your-endpoint.aliyuncs.com', // 例如: oss-cn-hangzhou.aliyuncs.com
      region: 'your-region', // 例如: cn-hangzhou
      accessKeyId: 'your-access-key-id', // 请替换为你的 AccessKey ID
      accessKeySecret: 'your-access-key-secret', // 请替换为你的 AccessKey Secret
      bucketName: 'your-bucket-name', // 请替换为你的 Bucket 名称
    ),
  );

  // 循环显示菜单直到用户选择退出
  while (true) {
    print("请选择要运行的示例:");
    print("1: 简单上传 (example/test_oss_put.txt)");
    print("2: 下载文件 (example/example.txt)");
    print("3: 分片上传 (example/multipart_upload_example.bin)");
    print("4: 列出已上传分片 (手动输入 Key 和 Upload ID)"); // <--- 更新描述
    print("5: 列出所有进行中的分片上传");
    print("6: 终止分片上传 (手动输入 Key 和 Upload ID)"); // <--- 更新描述
    print("0: 退出");
    stdout.write("请输入选项 (0-6): ");

    final choice = stdin.readLineSync(); // 读取用户输入

    switch (choice) {
      case '1':
        await _runSimpleUploadExample();
        break;
      case '2':
        await _runDownloadExample();
        break;
      case '3':
        await _runMultipartUploadExample();
        break;
      case '4': // 新增
        await _runListPartsExample();
        break;
      case '5': // 新增
        await _runListMultipartUploadsExample();
        break;
      case '6': // 新增
        await _runAbortMultipartUploadExample();
        break;
      case '0':
        print("退出程序。");
        return; // 退出 main 函数
      default:
        print("无效的选项，请重新输入。");
    }
    print("\n按 Enter 键继续..."); // 提示用户继续
    stdin.readLineSync(); // 等待用户按 Enter
    print("\n" * 2); // 打印空行分隔
  }
}
