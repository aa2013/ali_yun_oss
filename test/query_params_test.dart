import 'package:dart_aliyun_oss/dart_aliyun_oss.dart';
import 'package:dart_aliyun_oss/src/strategy/v1_sign_utils.dart';
import 'package:dart_aliyun_oss/src/strategy/v4_sign_utils.dart';
import 'package:test/test.dart';

void main() {
  group('自定义查询参数测试', () {
    const String accessKeyId = 'test-access-key-id';
    const String accessKeySecret = 'test-access-key-secret';
    const String endpoint = 'oss-cn-hangzhou.aliyuncs.com';
    const String region = 'cn-hangzhou';
    const String bucket = 'test-bucket';
    const String key = 'test-image.jpg';

    group('V4签名自定义查询参数', () {
      test('应该支持图片处理参数', () {
        final Map<String, String> queryParams = <String, String>{
          'x-oss-process': 'image/resize,l_100',
        };

        final Uri uri = AliOssV4SignUtils.signatureUri(
          accessKeyId: accessKeyId,
          accessKeySecret: accessKeySecret,
          endpoint: endpoint,
          region: region,
          method: 'GET',
          bucket: bucket,
          key: key,
          queryParameters: queryParams,
        );

        // 验证URL包含自定义参数
        expect(uri.queryParameters.containsKey('x-oss-process'), isTrue);
        expect(
          uri.queryParameters['x-oss-process'],
          equals('image/resize,l_100'),
        );

        // 验证URL包含必要的签名参数
        expect(uri.queryParameters.containsKey('x-oss-credential'), isTrue);
        expect(uri.queryParameters.containsKey('x-oss-date'), isTrue);
        expect(uri.queryParameters.containsKey('x-oss-expires'), isTrue);
        expect(uri.queryParameters.containsKey('x-oss-signature'), isTrue);
      });

      test('应该支持多个自定义参数', () {
        final Map<String, String> queryParams = <String, String>{
          'x-oss-process': 'image/resize,l_100',
          'response-content-type': 'image/jpeg',
          'custom-param': 'custom-value',
        };

        final Uri uri = AliOssV4SignUtils.signatureUri(
          accessKeyId: accessKeyId,
          accessKeySecret: accessKeySecret,
          endpoint: endpoint,
          region: region,
          method: 'GET',
          bucket: bucket,
          key: key,
          queryParameters: queryParams,
        );

        // 验证所有自定义参数都存在
        expect(
          uri.queryParameters['x-oss-process'],
          equals('image/resize,l_100'),
        );
        expect(
          uri.queryParameters['response-content-type'],
          equals('image/jpeg'),
        );
        expect(uri.queryParameters['custom-param'], equals('custom-value'));
      });

      test('应该拒绝与OSS保留参数冲突的参数', () {
        final Map<String, String> queryParams = <String, String>{
          'x-oss-credential': 'invalid-credential',
        };

        expect(
          () => AliOssV4SignUtils.signatureUri(
            accessKeyId: accessKeyId,
            accessKeySecret: accessKeySecret,
            endpoint: endpoint,
            region: region,
            method: 'GET',
            bucket: bucket,
            key: key,
            queryParameters: queryParams,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('V1签名自定义查询参数', () {
      test('应该支持图片处理参数', () {
        final Map<String, String> queryParams = <String, String>{
          'x-oss-process': 'image/resize,l_100',
        };

        final Uri uri = AliOssV1SignUtils.signatureUri(
          accessKeyId: accessKeyId,
          accessKeySecret: accessKeySecret,
          endpoint: endpoint,
          method: 'GET',
          bucket: bucket,
          key: key,
          queryParameters: queryParams,
        );

        // 验证URL包含自定义参数
        expect(uri.queryParameters.containsKey('x-oss-process'), isTrue);
        expect(
          uri.queryParameters['x-oss-process'],
          equals('image/resize,l_100'),
        );

        // 验证URL包含必要的签名参数
        expect(uri.queryParameters.containsKey('OSSAccessKeyId'), isTrue);
        expect(uri.queryParameters.containsKey('Expires'), isTrue);
        expect(uri.queryParameters.containsKey('Signature'), isTrue);
      });

      test('应该拒绝与OSS保留参数冲突的参数', () {
        final Map<String, String> queryParams = <String, String>{
          'OSSAccessKeyId': 'invalid-key-id',
        };

        expect(
          () => AliOssV1SignUtils.signatureUri(
            accessKeyId: accessKeyId,
            accessKeySecret: accessKeySecret,
            endpoint: endpoint,
            method: 'GET',
            bucket: bucket,
            key: key,
            queryParameters: queryParams,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    test('OSSClient应该支持V4签名的自定义查询参数', () {
      final OSSConfig config = OSSConfig.static(
        accessKeyId: accessKeyId,
        accessKeySecret: accessKeySecret,
        endpoint: endpoint,
        bucketName: bucket,
        region: region,
      );
      final OSSClient client = OSSClient.init(config);

      final String url = client.signedUrl(
        key,
        queryParameters: <String, String>{
          'x-oss-process': 'image/resize,l_100',
        },
        isV1Signature: false,
      );

      expect(url, contains('x-oss-process=image%2Fresize%2Cl_100'));
      expect(url, contains('x-oss-credential='));
      expect(url, contains('x-oss-signature='));
    });
  });
}
