# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- `debug_info` method to ResponseExtender for easier debugging of responses
- Basic test suite for Messages class with RSpec
- Added spec_helper.rb for testing support
- Created CHANGELOG.md file

### Changed
- Resolved all merge conflicts in codebase
- Standardized error messages to English
- Improved error handling in function execution
- Enhanced message parsing and validation
- Renamed O1 model constants to more generic reasoning model names
- Added `reasoning?` method to replace `o1?`
- Improved content validation in Messages class
- Better error messages with more context in ResponseExtender

### Fixed
- Fixed duplicate code in openaiext.rb
- Standardized parameter handling for chat methods
- Fixed tool_calls handling in Messages class
- Added proper nil checking for message response
- Fixed issues with message format handling in various scenarios
- Improved JSON error handling in function arguments