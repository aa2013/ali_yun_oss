// ignore_for_file: avoid_print

import 'package:dart_aliyun_oss/dart_aliyun_oss.dart';
import 'package:test/test.dart';

/// 自定义域名（CNAME）功能测试套件
///
/// 测试内容包括：
/// - OSSConfig中cname参数的配置
/// - buildOssUri方法对自定义域名的支持
/// - V1和V4签名算法对自定义域名的支持
/// - 签名URL生成对自定义域名的支持
void main() {
  group('自定义域名（CNAME）功能测试', () {
    group('OSSConfig配置测试', () {
      test('应该支持cname参数配置', () {
        // 测试静态配置
        final OSSConfig config = OSSConfig.static(
          accessKeyId: 'test-key-id',
          accessKeySecret: 'test-key-secret',
          bucketName: 'test-bucket',
          endpoint: 'img.example.com',
          region: 'cn-hangzhou',
          cname: true,
        );

        expect(config.cname, isTrue);
        expect(config.endpoint, 'img.example.com');
      });

      test('cname参数默认值应该为false', () {
        final OSSConfig config = OSSConfig.static(
          accessKeyId: 'test-key-id',
          accessKeySecret: 'test-key-secret',
          bucketName: 'test-bucket',
          endpoint: 'oss-cn-hangzhou.aliyuncs.com',
          region: 'cn-hangzhou',
        );

        expect(config.cname, isFalse);
      });

      test('应该支持fromJson和toJson包含cname参数', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'accessKeyId': 'test-key-id',
          'accessKeySecret': 'test-key-secret',
          'bucketName': 'test-bucket',
          'endpoint': 'img.example.com',
          'region': 'cn-hangzhou',
          'cname': true,
          'enableLogInterceptor': true,
          'maxConcurrency': 5,
        };

        final OSSConfig config = OSSConfig.fromJson(json);
        expect(config.cname, isTrue);

        final Map<String, dynamic> configJson = config.toJson();
        expect(configJson['cname'], isTrue);
      });

      test('应该支持copyWith包含cname参数', () {
        final OSSConfig originalConfig = OSSConfig.static(
          accessKeyId: 'test-key-id',
          accessKeySecret: 'test-key-secret',
          bucketName: 'test-bucket',
          endpoint: 'oss-cn-hangzhou.aliyuncs.com',
          region: 'cn-hangzhou',
          cname: false,
        );

        final OSSConfig newConfig = originalConfig.copyWith(
          endpoint: 'img.example.com',
          cname: true,
        );

        expect(newConfig.cname, isTrue);
        expect(newConfig.endpoint, 'img.example.com');
        expect(originalConfig.cname, isFalse); // 原配置不变
      });
    });

    group('buildOssUri方法测试', () {
      test('启用cname时应该使用自定义域名', () {
        final OSSConfig config = OSSConfig.static(
          accessKeyId: 'test-key-id',
          accessKeySecret: 'test-key-secret',
          bucketName: 'test-bucket',
          endpoint: 'img.example.com',
          region: 'cn-hangzhou',
          cname: true,
        );

        final OSSClient client = OSSClient.init(config);
        final Uri uri = client.buildOssUri(fileKey: 'test/file.jpg');

        expect(uri.host, 'img.example.com');
        expect(uri.path, '/test/file.jpg');
        expect(uri.scheme, 'https');
      });

      // 注意：由于OSSClient是单例，我们不能在同一个测试进程中多次初始化
      // 这个测试通过直接验证配置来测试逻辑
      test('禁用cname时配置应该正确', () {
        final OSSConfig config = OSSConfig.static(
          accessKeyId: 'test-key-id',
          accessKeySecret: 'test-key-secret',
          bucketName: 'test-bucket',
          endpoint: 'oss-cn-hangzhou.aliyuncs.com',
          region: 'cn-hangzhou',
          cname: false,
        );

        expect(config.cname, isFalse);
        expect(config.endpoint, 'oss-cn-hangzhou.aliyuncs.com');
        expect(config.bucketName, 'test-bucket');
      });
    });

    group('签名URL生成测试', () {
      test('V1签名应该支持自定义域名', () {
        // 由于OSSClient是单例，我们使用已初始化的客户端
        // 这里主要测试签名URL是否包含正确的域名
        final OSSClient client = OSSClient.instance;
        final String signedUrl = client.signedUrl(
          'test/file.jpg',
          isV1Signature: true,
        );

        // 验证URL包含自定义域名（从之前的测试中设置）
        expect(signedUrl, contains('img.example.com'));
        expect(signedUrl, contains('test/file.jpg'));
        expect(signedUrl, contains('OSSAccessKeyId=test-key-id'));
        expect(signedUrl, contains('Signature='));
      });

      test('V4签名应该支持自定义域名', () {
        // 使用已初始化的客户端测试V4签名
        final OSSClient client = OSSClient.instance;
        final String signedUrl = client.signedUrl(
          'test/file.jpg',
          isV1Signature: false,
        );

        // 验证URL包含自定义域名
        expect(signedUrl, contains('img.example.com'));
        expect(signedUrl, contains('test/file.jpg'));
        expect(signedUrl, contains('x-oss-credential=test-key-id'));
        expect(signedUrl, contains('x-oss-signature='));
      });
    });

    group('签名工具类直接测试', () {
      test('V1SignUtils应该支持cname参数', () {
        final Uri uri = AliOssV1SignUtils.signatureUri(
          accessKeyId: 'test-key-id',
          accessKeySecret: 'test-key-secret',
          endpoint: 'img.example.com',
          method: 'GET',
          bucket: 'test-bucket',
          key: 'test/file.jpg',
          expires: 3600,
          cname: true,
        );

        expect(uri.host, 'img.example.com');
        expect(uri.path, '/test/file.jpg');
        expect(uri.queryParameters['OSSAccessKeyId'], 'test-key-id');
      });

      test('V4SignUtils应该支持cname参数', () {
        final Uri uri = AliOssV4SignUtils.signatureUri(
          accessKeyId: 'test-key-id',
          accessKeySecret: 'test-key-secret',
          endpoint: 'img.example.com',
          region: 'cn-hangzhou',
          method: 'GET',
          bucket: 'test-bucket',
          key: 'test/file.jpg',
          expires: 3600,
          cname: true,
        );

        expect(uri.host, 'img.example.com');
        expect(uri.path, '/test/file.jpg');
        expect(
            uri.queryParameters['x-oss-credential'], contains('test-key-id'));
      });
    });

    group('配置验证测试', () {
      test('toString方法应该包含cname信息', () {
        final OSSConfig config = OSSConfig.static(
          accessKeyId: 'test-key-id',
          accessKeySecret: 'test-key-secret',
          bucketName: 'test-bucket',
          endpoint: 'img.example.com',
          region: 'cn-hangzhou',
          cname: true,
        );

        final String configString = config.toString();
        expect(configString, contains('cname: true'));
      });

      test('equals和hashCode应该考虑cname参数', () {
        final OSSConfig config1 = OSSConfig.static(
          accessKeyId: 'test-key-id',
          accessKeySecret: 'test-key-secret',
          bucketName: 'test-bucket',
          endpoint: 'img.example.com',
          region: 'cn-hangzhou',
          cname: true,
        );

        final OSSConfig config2 = OSSConfig.static(
          accessKeyId: 'test-key-id',
          accessKeySecret: 'test-key-secret',
          bucketName: 'test-bucket',
          endpoint: 'img.example.com',
          region: 'cn-hangzhou',
          cname: true,
        );

        final OSSConfig config3 = OSSConfig.static(
          accessKeyId: 'test-key-id',
          accessKeySecret: 'test-key-secret',
          bucketName: 'test-bucket',
          endpoint: 'img.example.com',
          region: 'cn-hangzhou',
          cname: false,
        );

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
        expect(config1, isNot(equals(config3)));
        expect(config1.hashCode, isNot(equals(config3.hashCode)));
      });
    });
  });
}
