import 'package:dio/dio.dart';

/// OSS 专用的日志拦截器
///
/// 该拦截器旨在提供更适合 OSS 场景的日志记录功能。
/// 主要特性包括：
/// - **优化二进制数据打印**：对于请求体或响应体中的二进制数据（`List<int>`）,仅打印其字节长度,避免控制台输出大量无意义内容。
/// - **敏感请求头自动屏蔽**：自动识别并屏蔽常见的敏感请求头（如 'Authorization'）,防止敏感信息泄露。支持自定义需要屏蔽的请求头列表。
/// - **日志截断**：对于过长的字符串日志（请求/响应体）,进行截断处理,并显示原始长度,保持日志简洁性。
/// - **灵活的日志控制**：可以通过构造函数参数控制请求、响应、头信息、体信息以及错误信息的打印开关。
/// - **自定义日志输出**：允许传入自定义的日志打印函数。
class OSSLogInterceptor extends Interceptor {
  /// 构造函数
  ///
  /// [request] 是否打印请求信息 (默认: true)
  /// [requestHeader] 是否打印请求头 (默认: true)
  /// [requestBody] 是否打印请求体 (默认: false)
  /// [responseHeader] 是否打印响应头 (默认: true)
  /// [responseBody] 是否打印响应体 (默认: false)
  /// [error] 是否打印错误信息 (默认: true)
  /// [logPrint] 日志打印函数 (默认: print)
  /// [sensitiveHeaders] 需要屏蔽的敏感请求头列表。这些请求头的值将在日志中显示为 '*** MASKED ***'。比较时会忽略大小写。(默认: ['Authorization', 'Proxy-Authorization'])
  /// [maxLogLength] 字符串日志的最大打印长度。超过此长度的字符串将被截断。(默认: 500)
  const OSSLogInterceptor({
    this.request = true,
    this.requestHeader = true,
    this.requestBody = false,
    this.responseHeader = true,
    this.responseBody = false,
    this.error = true,
    this.logPrint = print,
    this.sensitiveHeaders = const ['Authorization', 'Proxy-Authorization'],
    this.maxLogLength = 500,
  });

  /// 是否打印请求信息
  final bool request;

  /// 是否打印请求头
  final bool requestHeader;

  /// 是否打印请求体
  final bool requestBody;

  /// 是否打印响应体
  final bool responseBody;

  /// 是否打印响应头
  final bool responseHeader;

  /// 是否打印错误信息
  final bool error;

  /// 日志打印函数
  final void Function(Object object) logPrint;

  /// 需要屏蔽的敏感请求头列表
  final List<String> sensitiveHeaders;

  /// 字符串日志的最大打印长度
  final int maxLogLength;

  /// 拦截请求
  ///
  /// 在请求发送前被调用,打印请求相关信息。
  ///
  /// [options] 请求配置信息
  /// [handler] 请求拦截处理器
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logPrint('*** OSS Request ***');
    _printKV('uri', options.uri);

    if (request) {
      _printKV('method', options.method);
      _printKV('responseType', options.responseType.toString());
    }

    if (requestHeader) {
      logPrint('headers:');
      options.headers.forEach((String key, dynamic v) {
        // _printKV handles sensitive header masking
        _printKV(' $key', v);
      });
    }

    if (requestBody && options.data != null) {
      logPrint('data:');
      _printData(options.data);
    }

    logPrint('');
    handler.next(options);
  }

  /// 拦截响应
  ///
  /// 在接收到响应后被调用,打印响应相关信息。
  ///
  /// [response] 响应对象
  /// [handler] 响应拦截处理器
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logPrint('*** OSS Response ***');
    _printResponse(response);
    handler.next(response);
  }

  /// 拦截错误
  ///
  /// 在请求发生错误时被调用,打印错误信息。
  ///
  /// [err] Dio 异常对象
  /// [handler] 错误拦截处理器
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (error) {
      logPrint('*** OSS Error ***:');
      logPrint('uri: ${err.requestOptions.uri}');
      logPrint('$err');
      if (err.response != null) {
        _printResponse(err.response!);
      }
      logPrint('');
    }
    handler.next(err);
  }

  /// 打印响应的详细信息
  ///
  /// [response] Dio 响应对象
  void _printResponse(Response response) {
    _printKV('uri', response.requestOptions.uri);
    if (responseHeader) {
      _printKV('statusCode', response.statusCode);
      if (response.isRedirect == true) {
        _printKV('redirect', response.realUri);
      }

      logPrint('headers:');
      response.headers.forEach((String key, List<String> v) {
        // _printKV handles sensitive header masking
        _printKV(' $key', v.join('\r\n\t'));
      });
    }
    if (responseBody) {
      logPrint('Response Data:');
      _printData(response.data);
    }
    logPrint('');
  }

  /// 打印键值对,处理敏感信息屏蔽
  ///
  /// [key] 键
  /// [v] 值
  void _printKV(String key, Object? v) {
    // 统一转换为小写并移除前后空格以进行不区分大小写的比较
    final String lowerCaseKey = key.trim().toLowerCase();
    final bool isSensitive = sensitiveHeaders.any(
      (String sensitiveHeader) => sensitiveHeader.toLowerCase() == lowerCaseKey,
    );

    if (isSensitive) {
      logPrint('$key: *** MASKED ***');
    } else {
      logPrint('$key: $v');
    }
  }

  /// 打印请求或响应体数据
  ///
  /// 根据数据类型进行不同的处理：
  /// - `List<int>`: 打印字节长度。
  /// - `Map`: 如果条目过多,则截断打印。
  /// - `String`: 如果超过 `maxLogLength` 则截断打印。
  /// - 其他类型: 调用 `toString()` 打印。
  ///
  /// [data] 请求或响应体数据
  void _printData(dynamic data) {
    const int maxMapEntries = 10; // Maximum map entries to print
    if (data is List<int>) {
      // 二进制数据,只打印长度信息
      logPrint('File data: ${data.length} bytes');
    } else if (data is Map) {
      // Map 数据,如果过长则截断
      if (data.length > maxMapEntries) {
        logPrint(
          'Map data: {${data.keys.take(maxMapEntries).map((key) => '$key: ${data[key]}').join(', ')}, ...} (being cut down, total: ${data.length} entries)',
        );
      } else {
        logPrint(data);
      }
    } else if (data is String) {
      // 字符串数据,如果过长则截断
      if (data.length > maxLogLength) {
        logPrint(
          '${data.substring(0, maxLogLength)}... (being cut down, total: ${data.length})',
        );
      } else {
        logPrint(data);
      }
    } else {
      // 其他类型数据
      logPrint(data.toString());
    }
  }
}
