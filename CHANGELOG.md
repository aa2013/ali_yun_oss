# Changelog

[English](CHANGELOG.md) | [中文](CHANGELOG_zh.md)

## 1.2.0

### ✨ Major New Features

#### 🌐 Custom Domain (CNAME) Support
- **Enterprise-Grade Domain Customization**: Full support for custom domain names (CNAME) configuration
  - Added `cname` parameter to `OSSConfig` class for seamless custom domain integration
  - Enhanced `buildOssUri` method to automatically select appropriate domain format
  - Complete V1 and V4 signature algorithm support for custom domains
  - Signed URL generation fully compatible with custom domain configurations
  - Resolves **GitHub Issue #3**: 【功能请求】支持一下自定义域名

#### 🔧 Advanced Query Parameters Support
- **Flexible URL Query Parameter Handling**: Enhanced V4 signature URLs with custom query parameter support
  - Added `queryParameters` support for image processing and other advanced OSS features
  - Example: `?x-oss-process=image/resize,l_100` for image transformation
  - Built-in parameter conflict detection to prevent OSS reserved parameter conflicts
  - Maintained API consistency by adding equivalent functionality to V1 signatures
  - Comprehensive validation and error handling for parameter safety
  - Resolves **GitHub Issue #5**: 【功能请求】url请求的v4签名增加自定义queryParams

### 🛠️ Technical Implementation

#### Custom Domain Architecture
- **Backward Compatible Design**: Default `cname=false` preserves existing behavior
- **Flexible URI Construction**: Smart domain selection based on configuration
- **Complete Signature Support**: Both V1 and V4 algorithms handle custom domains seamlessly
- **Enterprise Ready**: Perfect for brand consistency and corporate requirements

#### Query Parameters Enhancement
- **Type-Safe Parameter Handling**: Robust validation prevents configuration conflicts
- **Comprehensive Testing**: Full test coverage for all parameter combinations
- **Developer-Friendly API**: Intuitive parameter passing with clear error messages
- **Performance Optimized**: Efficient parameter processing without overhead

### 📚 Documentation & Examples
- **Complete CNAME Documentation**: Detailed setup guides in both English and Chinese README
- **Dedicated Example Programs**:
  - `example/cname_demo.dart` - Complete CNAME functionality demonstration
  - `example/query_params_example.dart` - Advanced query parameter usage examples
- **Integrated Main Examples**: Enhanced `example/example.dart` with new feature demonstrations
- **Comprehensive Code Comments**: Detailed inline documentation for all new features

### 🧪 Testing & Quality Assurance
- **Extensive Test Coverage**:
  - `test/cname_test.dart` - Complete CNAME functionality testing
  - `test/query_params_test.dart` - Comprehensive query parameter validation
- **Backward Compatibility Verified**: All existing functionality remains unchanged
- **Cross-Platform Testing**: Validated on multiple Dart/Flutter environments
- **Performance Benchmarking**: Ensured no performance regression with new features

### 🔄 Migration & Compatibility
- **Zero Breaking Changes**: Existing code continues to work without modifications
- **Optional Feature Adoption**: New features are opt-in, maintaining stability
- **Clear Upgrade Path**: Simple configuration changes to enable new capabilities
- **Production Ready**: Thoroughly tested for enterprise deployment scenarios

## 1.1.0

### ✨ Major New Features

#### 🔐 Dynamic Credential Management
- **Dynamic AccessKey/Secret/STS Token Support**: Enhanced `OSSConfig` to support dynamic credential retrieval
  - Added `accessKeyIdProvider`, `accessKeySecretProvider`, and `securityTokenProvider` functions
  - Enables automatic STS token refresh without client reinitialization
  - Maintains backward compatibility with static credential configuration via `OSSConfig.static()`
  - Perfect for production environments requiring automatic credential rotation

#### 📤 Extended Upload Methods
- **Multi-Type Upload Support**: Added convenient upload methods for different data types
  - `putObjectFromString()` - Upload string content with automatic UTF-8 encoding
  - `putObjectFromBytes()` - Upload byte array data directly
  - Maintains full compatibility with existing `putObject()` for file uploads
  - Implemented as extension methods in implementation classes, keeping interfaces clean

### 📚 Documentation & Examples
- **Enhanced STS Documentation**: Complete examples for both static and dynamic STS token management
- **Comprehensive Examples**: Added examples for all upload types in `example.dart`
- **README Synchronization**: Ensured complete correspondence between English and Chinese versions

### 🧪 Testing & Quality
- **Comprehensive Test Coverage**: Added extensive unit tests for new functionality
- **All Tests Passing**: 21/21 tests pass, including new multi-type upload tests
- **Signature Compatibility**: Verified compatibility with both V1 and V4 signature algorithms

## 1.0.4

### Bug Fixes
- 🐛 Fixed type mismatch in `createSignedHeaders` method
- 🔨 Improved header content-type extraction to avoid runtime type errors

## 1.0.3

### Code Refactoring and Interface Improvements
- ✨ Bump version to 1.0.3
- 🔨 Optimized createSignedHeaders method

## 1.0.2

### Code Refactoring and Interface Improvements
- Added queryParameters parameter to OSSRequestParams class for unified query parameter handling
- Refactored URI building logic into a dedicated buildOssUri method
- Improved handling of complex query parameter types using jsonEncode
- Updated all implementation classes to use the unified query parameter approach
- Removed redundant URI construction code across implementation classes
- Optimized createSignedHeaders method by removing uri parameter and adding queryParameters support

### Bug Fixes
- Updated repository links in package metadata

## 1.0.1

### Interface Improvements
- Unified progress callback parameters by moving all to OSSRequestParams class
- Added onSendProgress parameter to OSSRequestParams class
- Removed standalone onSendProgress/onProgress parameters from methods
- Updated all network requests to use the unified progress callback approach
- Updated example code to use the new parameter passing approach
- Simplified progress display format

### Package Discoverability
- Improved package metadata for better discoverability on pub.dev
- Updated package description and keywords
- Added proper license references

### OSS Signature Improvements
- Fixed V1 and V4 signature URL generation to ensure compatibility with Alibaba Cloud API
- Added signature version selection feature for all example methods
- Optimized code structure by moving signature URL implementation to separate files
- Added DateFormatter utility class for unified date format handling

## 1.0.0

- Initial release
- Support for file upload and download
- Support for large file multipart upload
- Support for upload and download progress monitoring
- Support for multipart upload management operations (list, abort, etc.)
- Support for both V1 and V4 signature algorithms
