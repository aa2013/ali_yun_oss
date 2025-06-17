import 'package:dart_aliyun_oss/dart_aliyun_oss.dart';

/// 自定义查询参数示例
/// 
/// 本示例展示如何在生成OSS签名URL时添加自定义查询参数，
/// 特别是用于图片处理的参数，如 x-oss-process=image/resize,l_100
void main() async {
  // 配置OSS客户端
  final OSSConfig config = OSSConfig.static(
    accessKeyId: 'your-access-key-id',
    accessKeySecret: 'your-access-key-secret',
    endpoint: 'oss-cn-hangzhou.aliyuncs.com',
    bucketName: 'your-bucket-name',
    region: 'cn-hangzhou',
  );

  final OSSClient client = OSSClient.init(config);

  print('=== OSS 自定义查询参数示例 ===\n');

  // 示例1：基础图片处理参数
  print('1. 基础图片处理参数（V4签名）');
  final String imageResizeUrl = client.signedUrl(
    'images/photo.jpg',
    queryParameters: <String, String>{
      'x-oss-process': 'image/resize,l_100', // 限制长边为100像素
    },
    isV1Signature: false, // 使用V4签名
    expires: 3600, // 1小时有效期
  );
  print('图片缩放URL: $imageResizeUrl\n');

  // 示例2：复杂图片处理参数
  print('2. 复杂图片处理参数（V4签名）');
  final String complexImageUrl = client.signedUrl(
    'images/photo.jpg',
    queryParameters: <String, String>{
      'x-oss-process': 'image/resize,w_200,h_200/quality,q_80/format,webp',
    },
    isV1Signature: false,
  );
  print('复杂图片处理URL: $complexImageUrl\n');

  // 示例3：多个自定义参数
  print('3. 多个自定义参数（V4签名）');
  final String multiParamsUrl = client.signedUrl(
    'documents/report.pdf',
    queryParameters: <String, String>{
      'response-content-type': 'application/pdf',
      'response-content-disposition': 'attachment; filename="report.pdf"',
      'response-cache-control': 'no-cache',
    },
    isV1Signature: false,
  );
  print('多参数URL: $multiParamsUrl\n');

  // 示例4：V1签名也支持自定义参数
  print('4. V1签名支持自定义参数');
  final String v1ImageUrl = client.signedUrl(
    'images/photo.jpg',
    queryParameters: <String, String>{
      'x-oss-process': 'image/resize,l_150',
    },
    // isV1Signature: true, // 默认值，可以省略
  );
  print('V1签名图片处理URL: $v1ImageUrl\n');

  // 示例5：水印处理
  print('5. 图片水印处理（V4签名）');
  final String watermarkUrl = client.signedUrl(
    'images/photo.jpg',
    queryParameters: <String, String>{
      'x-oss-process': 'image/watermark,text_SGVsbG8gV29ybGQ,color_FF0000,size_30',
    },
    isV1Signature: false,
  );
  print('水印处理URL: $watermarkUrl\n');

  // 示例6：图片信息获取
  print('6. 图片信息获取（V4签名）');
  final String infoUrl = client.signedUrl(
    'images/photo.jpg',
    queryParameters: <String, String>{
      'x-oss-process': 'image/info',
    },
    isV1Signature: false,
  );
  print('图片信息URL: $infoUrl\n');

  // 示例7：视频截帧
  print('7. 视频截帧（V4签名）');
  final String videoSnapshotUrl = client.signedUrl(
    'videos/movie.mp4',
    queryParameters: <String, String>{
      'x-oss-process': 'video/snapshot,t_10000,f_jpg,w_800,h_600',
    },
    isV1Signature: false,
  );
  print('视频截帧URL: $videoSnapshotUrl\n');

  print('=== 注意事项 ===');
  print('1. 自定义查询参数会参与签名计算，确保URL的安全性');
  print('2. 不能使用与OSS保留参数冲突的参数名');
  print('3. V4签名提供更高的安全性，推荐在新项目中使用');
  print('4. 图片处理参数需要根据阿里云OSS文档进行配置');
  print('5. 生成的URL有效期由expires参数控制');

  print('\n=== 错误示例 ===');
  try {
    // 这会抛出异常，因为x-oss-credential是OSS保留参数
    client.signedUrl(
      'test.jpg',
      queryParameters: <String, String>{
        'x-oss-credential': 'invalid-value',
      },
      isV1Signature: false,
    );
  } catch (e) {
    print('预期的错误: $e');
  }
}
