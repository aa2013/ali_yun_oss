import 'package:xml/xml.dart';

/// 表示ListBucket请求结果的容器
class ListBucketResultV2 {

  ListBucketResultV2({
    required this.name,
    this.prefix,
    this.maxKeys,
    this.delimiter,
    this.isTruncated,
    this.startAfter,
    this.keyCount,
    this.continuationToken,
    this.nextContinuationToken,
    this.encodingType,
    required this.contents,
    required this.commonPrefixes,
  });

  /// 从XML文档解析ListBucketResult
  factory ListBucketResultV2.fromXml(XmlElement xml) {
    return ListBucketResultV2(
      name: xml.getElement('Name')?.innerText ?? '',
      prefix: xml.getElement('Prefix')?.innerText,
      maxKeys: int.tryParse(xml.getElement('MaxKeys')?.innerText ?? ''),
      delimiter: xml.getElement('Delimiter')?.innerText,
      isTruncated: _parseBool(xml.getElement('IsTruncated')?.innerText),
      startAfter: xml.getElement('StartAfter')?.innerText,
      keyCount: int.tryParse(xml.getElement('KeyCount')?.innerText ?? ''),
      continuationToken: xml.getElement('ContinuationToken')?.innerText,
      nextContinuationToken: xml.getElement('NextContinuationToken')?.innerText,
      encodingType: xml.getElement('EncodingType')?.innerText,
      contents: xml.findElements('Contents').map((XmlElement e) => Contents.fromXml(e)).toList(),
      commonPrefixes: xml.findElements('CommonPrefixes').map((XmlElement e) => CommonPrefixes.fromXml(e)).toList(),
    );
  }

  /// 从XML字符串解析ListBucketResult
  factory ListBucketResultV2.parse(String xmlString) {
    try {
      final XmlDocument document = XmlDocument.parse(xmlString);
      return ListBucketResultV2.fromXml(document.rootElement);
    } catch (e) {
      throw Exception('Failed to parse XML: $e');
    }
  }
  /// Bucket名称
  final String name;

  /// 本次查询结果的前缀
  final String? prefix;

  /// 响应请求内返回结果的最大数目
  final int? maxKeys;

  /// 对Object名字进行分组的字符
  final String? delimiter;

  /// 请求中返回的结果是否被截断
  final bool? isTruncated;

  /// 如果请求中指定了StartAfter参数，则会在返回的响应中包含StartAfter元素
  final String? startAfter;

  /// 此次请求返回的Key的个数
  final int? keyCount;

  /// 如果请求中指定了ContinuationToken参数，则会在返回的响应中包含ContinuationToken元素
  final String? continuationToken;

  /// 表明此次请求包含后续结果，需要将此值指定为ContinuationToken继续获取结果
  final String? nextContinuationToken;

  /// 指明返回结果中编码使用的类型
  final String? encodingType;

  /// Object列表
  final List<Contents> contents;

  /// 共同前缀列表
  final List<CommonPrefixes> commonPrefixes;

  /// 解析布尔值
  static bool? _parseBool(String? value) {
    if (value == null) {
      return null;
    }
    return value.toLowerCase() == 'true';
  }
}

/// 表示Object的元数据
class Contents {

  Contents({
    this.key,
    this.lastModified,
    this.eTag,
    this.size,
    this.storageClass,
    this.type,
    this.restoreInfo,
    this.owner,
  });

  factory Contents.fromXml(XmlElement xml) {
    return Contents(
      key: xml.getElement('Key')?.innerText,
      lastModified: _parseDateTime(xml.getElement('LastModified')?.innerText),
      eTag: xml.getElement('ETag')?.innerText,
      size: int.tryParse(xml.getElement('Size')?.innerText ?? ''),
      storageClass: xml.getElement('StorageClass')?.innerText,
      type: xml.getElement('Type')?.innerText,
      restoreInfo: xml.getElement('RestoreInfo')?.innerText,
      owner: xml.getElement('Owner') != null ? Owner.fromXml(xml.getElement('Owner')!) : null,
    );
  }
  /// Object的Key
  final String? key;

  /// Object最后被修改的时间
  final DateTime? lastModified;

  /// ETag值可以用于检查Object内容是否发生变化
  final String? eTag;

  /// 返回Object大小，单位为字节
  final int? size;

  /// Object的存储类型
  final String? storageClass;

  /// 文件类型
  final String? type;

  /// Object的解冻状态
  final String? restoreInfo;

  /// 拥有者信息
  final Owner? owner;

  void buildXml(XmlBuilder builder) {
    if (key != null) {
      builder.element('Key', nest: key);
    }
    if (lastModified != null) {
      builder.element('LastModified', nest: lastModified!.toIso8601String());
    }
    if (eTag != null) {
      builder.element('ETag', nest: eTag);
    }
    if (size != null) {
      builder.element('Size', nest: size.toString());
    }
    if (storageClass != null) {
      builder.element('StorageClass', nest: storageClass);
    }
    if (type != null) {
      builder.element('Type', nest: type);
    }
    if (restoreInfo != null) {
      builder.element('RestoreInfo', nest: restoreInfo);
    }

    if (owner != null) {
      builder.element('Owner', nest: () {
        owner!.buildXml(builder);
      },);
    }
  }

  /// 解析日期时间
  static DateTime? _parseDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
}

/// 表示共同前缀
class CommonPrefixes {

  CommonPrefixes({this.prefix});

  factory CommonPrefixes.fromXml(XmlElement xml) {
    return CommonPrefixes(
      prefix: xml.getElement('Prefix')?.innerText,
    );
  }
  /// 共同前缀
  final String? prefix;

  void buildXml(XmlBuilder builder) {
    if (prefix != null) {
      builder.element('Prefix', nest: prefix);
    }
  }
}

/// 表示拥有者信息
class Owner {

  Owner({this.id, this.displayName});

  factory Owner.fromXml(XmlElement xml) {
    return Owner(
      id: xml.getElement('ID')?.innerText,
      displayName: xml.getElement('DisplayName')?.innerText,
    );
  }
  /// Bucket拥有者的用户ID
  final String? id;

  /// Object拥有者名称
  final String? displayName;

  void buildXml(XmlBuilder builder) {
    if (id != null) {
      builder.element('ID', nest: id);
    }
    if (displayName != null) {
      builder.element('DisplayName', nest: displayName);
    }
  }
}