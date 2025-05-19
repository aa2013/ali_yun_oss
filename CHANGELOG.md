# Changelog

[English](CHANGELOG.md) | [中文](CHANGELOG_zh.md)

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
