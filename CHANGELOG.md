# Changelog

[English](CHANGELOG.md) | [中文](CHANGELOG_zh.md)

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
