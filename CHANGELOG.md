# Changelog | 更新日志

## 1.0.1

### English

- Unified progress callback parameters by moving all to OSSRequestParams class
- Added onSendProgress parameter to OSSRequestParams class
- Removed standalone onSendProgress/onProgress parameters from methods
- Updated all network requests to use the unified progress callback approach
- Updated example code to use the new parameter passing approach
- Simplified progress display format

### 中文

- 统一进度回调参数，将所有回调移至 OSSRequestParams 类中
- 在 OSSRequestParams 类中添加 onSendProgress 参数
- 移除各方法中独立的 onSendProgress/onProgress 参数
- 更新所有网络请求，使用统一的进度回调方式
- 更新示例代码，使用新的参数传递方式
- 简化进度显示格式

## 1.0.0

### English

- Initial release
- Support for file upload and download
- Support for large file multipart upload
- Support for upload and download progress monitoring
- Support for multipart upload management operations (list, abort, etc.)
- Support for both V1 and V4 signature algorithms

### 中文

- 初始版本发布
- 支持文件的上传和下载
- 支持大文件的分片上传
- 支持上传和下载进度监控
- 支持分片上传的管理操作（列出、终止等）
- 支持V1和V4两种签名算法
