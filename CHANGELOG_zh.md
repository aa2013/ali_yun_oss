# 更新日志

[English](CHANGELOG.md) | [中文](CHANGELOG_zh.md)

## 1.0.3

### 代码重构和接口改进
- ✨ 版本升级至 1.0.3
- 🔨 优化 createSignedHeaders 方法

## 1.0.2

### 代码重构和接口改进
- 在 OSSRequestParams 类中添加 queryParameters 参数，统一查询参数处理
- 将 URI 构建逻辑重构为专用的 buildOssUri 方法
- 使用 jsonEncode 改进复杂查询参数类型的处理
- 更新所有实现类，使用统一的查询参数方式
- 移除实现类中冗余的 URI 构建代码
- 优化 createSignedHeaders 方法，移除 uri 参数并添加 queryParameters 支持

### 错误修复
- 更新包元数据中的仓库链接

## 1.0.1

### 接口改进
- 统一进度回调参数，将所有回调移至 OSSRequestParams 类中
- 在 OSSRequestParams 类中添加 onSendProgress 参数
- 移除各方法中独立的 onSendProgress/onProgress 参数
- 更新所有网络请求，使用统一的进度回调方式
- 更新示例代码，使用新的参数传递方式
- 简化进度显示格式

### 包可发现性优化
- 改进包元数据，提高在 pub.dev 上的可发现性
- 更新包描述和关键词
- 添加正确的许可证引用

### OSS签名改进
- 修复V1和V4签名URL生成问题，确保与阿里云API兼容
- 添加签名版本选择功能，支持在所有示例方法中选择V1或V4签名
- 优化代码结构，将签名URL实现移至独立文件
- 添加DateFormatter工具类，统一日期格式处理

## 1.0.0

- 初始版本发布
- 支持文件的上传和下载
- 支持大文件的分片上传
- 支持上传和下载进度监控
- 支持分片上传的管理操作（列出、终止等）
- 支持V1和V4两种签名算法
