# 阿里云OSS Dart SDK

这是一个用于阿里云对象存储服务(OSS)的Dart客户端SDK，提供了简单易用的API来访问阿里云OSS服务。

## 功能特点

- 支持文件的上传和下载
- 支持大文件的分片上传
- 支持上传和下载进度监控
- 支持分片上传的管理操作（列出、终止等）
- 支持V1和V4两种签名算法

## 安装

```yaml
dependencies:
  dart_aliyun_oss: ^1.0.1
```

然后运行:

```bash
dart pub get
```

## 使用示例

### 初始化

```dart
import 'package:dart_aliyun_oss/dart_aliyun_oss.dart';

// 初始化OSS客户端
final oss = OSSClient.init(
  OSSConfig(
    endpoint: 'your-endpoint.aliyuncs.com', // 例如: oss-cn-hangzhou.aliyuncs.com
    region: 'your-region', // 例如: cn-hangzhou
    accessKeyId: 'your-access-key-id',
    accessKeySecret: 'your-access-key-secret',
    bucketName: 'your-bucket-name',
  ),
);
```

### 简单上传

```dart
Future<void> uploadFile() async {
  final file = File('path/to/your/file.txt');
  await oss.putObject(
    file,
    'example/file.txt', // OSS对象键名
    params: OSSRequestParams(
      onSendProgress: (int count, int total) {
        print('上传进度: ${(count / total * 100).toStringAsFixed(2)}%');
      },
    ),
  );
}
```

### 下载文件

```dart
Future<void> downloadFile() async {
  final ossObjectKey = 'example/file.txt';
  final downloadPath = 'path/to/save/file.txt';

  final response = await oss.getObject(
    ossObjectKey,
    params: OSSRequestParams(
      onReceiveProgress: (int count, int total) {
        print('下载进度: ${(count / total * 100).toStringAsFixed(2)}%');
      },
    ),
  );

  final File downloadFile = File(downloadPath);
  await downloadFile.parent.create(recursive: true);
  await downloadFile.writeAsBytes(response.data);
}
```

### 分片上传

```dart
Future<void> multipartUpload() async {
  final file = File('path/to/large/file.mp4');
  final ossObjectKey = 'videos/large_file.mp4';

  final completeResponse = await oss.multipartUpload(
    file,
    ossObjectKey,
    params: OSSRequestParams(
      onSendProgress: (count, total) {
        print('整体上传进度: ${(count / total * 100).toStringAsFixed(2)}%');
      },
    ),
  );

  print('分片上传成功完成!');
}
```

### 生成签名URL

```dart
// 使用V1签名算法生成签名URL
final String signedUrlV1 = oss.signedUrl(
  'example/test.txt',
  method: 'GET',
  expires: 3600, // URL在1小时后过期
  isV1Signature: true,
);

// 使用V4签名算法生成签名URL
final String signedUrlV4 = oss.signedUrl(
  'example/test.txt',
  method: 'GET',
  expires: 3600,
  isV1Signature: false,
);
```

## 更多示例

更多示例请参考 `example/example.dart` 文件。

## 注意事项

- 请勿在生产代码中硬编码您的AccessKey信息，建议使用环境变量或其他安全的凭证管理方式。
- 在使用分片上传时，如果上传过程被中断，请确保调用 `abortMultipartUpload` 方法清理未完成的分片上传。

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。
