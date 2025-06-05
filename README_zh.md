# 阿里云OSS Dart SDK

[English](README.md) | [中文](README_zh.md)

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
  dart_aliyun_oss: ^1.1.0
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

SDK支持上传不同类型的数据：

#### 上传文件

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

#### 上传字符串内容

```dart
Future<void> uploadString() async {
  const String content = '''
这是一个通过字符串内容上传的文本文件。
支持多行文本内容。
时间戳: 2024-01-01 12:00:00
''';

  await oss.putObjectFromString(
    content,
    'example/text_content.txt',
    params: OSSRequestParams(
      onSendProgress: (int count, int total) {
        print('字符串上传进度: ${(count / total * 100).toStringAsFixed(2)}%');
      },
    ),
  );
}
```

#### 上传字节数组

```dart
import 'dart:typed_data';

Future<void> uploadBytes() async {
  // 创建示例字节数组（例如，二进制数据）
  final Uint8List bytes = Uint8List.fromList([
    // 文件头（模拟PNG文件头）
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    // 一些示例数据
    ...List<int>.generate(1024, (index) => index % 256),
  ]);

  await oss.putObjectFromBytes(
    bytes,
    'example/binary_data.bin',
    params: OSSRequestParams(
      onSendProgress: (int count, int total) {
        print('字节数组上传进度: ${(count / total * 100).toStringAsFixed(2)}%');
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

### 使用查询参数

```dart
// 使用查询参数列出分片上传的分片
final response = await oss.listParts(
  'example/large_file.mp4',
  'your-upload-id',
  params: OSSRequestParams(
    queryParameters: {
      'max-parts': 100,
      'part-number-marker': 5,
    },
  ),
);

// 使用查询参数获取特定版本的对象
final response = await oss.getObject(
  'example/file.txt',
  params: OSSRequestParams(
    queryParameters: {
      'versionId': 'your-version-id',
    },
  ),
);
```

### 使用STS临时令牌

STS（安全令牌服务）提供临时凭证，用于安全访问OSS资源。本SDK支持静态STS令牌和动态令牌刷新两种方式。

#### 方式1：静态STS令牌

```dart
// 使用静态STS临时令牌初始化客户端
final OSSConfig configWithSTS = OSSConfig.static(
  accessKeyId: 'STS.your-sts-access-key-id',
  accessKeySecret: 'your-sts-access-key-secret',
  securityToken: 'your-sts-security-token', // STS临时安全令牌
  bucketName: 'your-bucket-name',
  endpoint: 'oss-cn-hangzhou.aliyuncs.com',
  region: 'cn-hangzhou',
);

final OSSClient ossWithSTS = OSSClient.init(configWithSTS);

// 使用STS临时令牌上传文件
await ossWithSTS.putObject(
  File('path/to/file.txt'),
  'example/file.txt',
);
```

#### 方式2：动态STS令牌刷新（推荐）

```dart
// STS令牌管理器，用于自动刷新令牌
class StsTokenManager {
  String? _accessKeyId;
  String? _accessKeySecret;
  String? _securityToken;
  DateTime? _expireTime;

  String get accessKeyId {
    _refreshIfNeeded();
    return _accessKeyId!;
  }

  String get accessKeySecret {
    _refreshIfNeeded();
    return _accessKeySecret!;
  }

  String? get securityToken {
    _refreshIfNeeded();
    return _securityToken;
  }

  void _refreshIfNeeded() {
    if (_expireTime == null ||
        DateTime.now().isAfter(_expireTime!.subtract(Duration(minutes: 5)))) {
      _refreshStsToken();
    }
  }

  void _refreshStsToken() {
    // 调用您的STS服务获取新的临时凭证
    // 请替换为实际的STS API调用
    _accessKeyId = 'STS.new_access_key_id';
    _accessKeySecret = 'new_access_key_secret';
    _securityToken = 'new_security_token';
    _expireTime = DateTime.now().add(Duration(hours: 1));
  }
}

// 使用动态STS令牌刷新初始化客户端
final stsManager = StsTokenManager();
final OSSClient ossWithDynamicSTS = OSSClient.init(
  OSSConfig(
    accessKeyIdProvider: () => stsManager.accessKeyId,
    accessKeySecretProvider: () => stsManager.accessKeySecret,
    securityTokenProvider: () => stsManager.securityToken,
    bucketName: 'your-bucket-name',
    endpoint: 'oss-cn-hangzhou.aliyuncs.com',
    region: 'cn-hangzhou',
  ),
);

// 客户端将自动使用刷新后的令牌进行所有操作
await ossWithDynamicSTS.putObject(
  File('path/to/file.txt'),
  'example/file.txt',
);
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
