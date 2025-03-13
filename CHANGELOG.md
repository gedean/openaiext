# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- `debug_info` method to ResponseExtender for easier debugging of responses
- Comprehensive test suite with RSpec:
  - Tests for Messages class
  - Tests for Model module
  - Tests for ResponseExtender module
  - Basic tests for main OpenAIExt module
- Spec helper with mock OpenAI response generation
- Added WebMock support for API testing
- Added Rakefile with tasks for tests, linting, and documentation
- Created CHANGELOG.md file
- Updated gemspec with development dependencies

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