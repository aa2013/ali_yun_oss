# 更新日志

[English](CHANGELOG.md) | [中文](CHANGELOG_zh.md)

## 1.1.0

### ✨ 主要新功能

#### 🔐 动态凭证管理
- **动态 AccessKey/Secret/STS 令牌支持**：增强 `OSSConfig` 以支持动态凭证获取
  - 添加 `accessKeyIdProvider`、`accessKeySecretProvider` 和 `securityTokenProvider` 函数
  - 支持自动 STS 令牌刷新，无需重新初始化客户端
  - 通过 `OSSConfig.static()` 保持与静态凭证配置的向后兼容性
  - 非常适合需要自动凭证轮换的生产环境

#### 📤 扩展上传方法
- **多类型上传支持**：为不同数据类型添加便利的上传方法
  - `putObjectFromString()` - 上传字符串内容，自动 UTF-8 编码
  - `putObjectFromBytes()` - 直接上传字节数组数据
  - 保持与现有 `putObject()` 文件上传的完全兼容性
  - 作为扩展方法在实现类中实现，保持接口清洁

### 📚 文档和示例
- **增强 STS 文档**：提供静态和动态 STS 令牌管理的完整示例
- **全面示例**：在 `example.dart` 中添加所有上传类型的示例
- **README 同步**：确保中英文版本完全对应

### 🧪 测试和质量
- **全面测试覆盖**：为新功能添加了广泛的单元测试
- **所有测试通过**：21/21 测试通过，包括新的多类型上传测试
- **签名兼容性**：验证了与 V1 和 V4 签名算法的兼容性

## 1.0.4

### 错误修复
- 🐛 修复 `createSignedHeaders` 方法中的类型不匹配问题
- 🔨 改进头部 content-type 提取逻辑，避免运行时类型错误

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
