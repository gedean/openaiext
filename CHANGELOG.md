# Changelog

All notable changes to this project will be documented in this file.

## [0.0.12] - Unreleased

### Added
- Streaming support for chat responses
- Enhanced error handling with custom exception types
- Model capability validation (vision, JSON mode, functions)
- Additional response helper methods (refusal, usage stats, completion info)
- Message builder helper methods (add_system, add_user, add_assistant)
- Message query methods (by_role, last_user_message, last_assistant_message)
- Model information methods (available_models, model_info)
- Response serialization methods (to_h, to_s, inspect)
- Input validation for all public methods
- Environment variable validation
- Function context validation with helpful error messages
- Support for function calls without arguments
- Cache for models list
- Demo script with usage examples

### Changed
- Improved function execution error handling
- Better JSON parsing with detailed error messages
- More descriptive error messages throughout
- Refactored code structure for better maintainability
- Enhanced documentation with more examples

### Fixed
- Function execution with empty arguments
- Response content validation
- URL validation for vision API
- String truncation in inspect method

## [0.0.11] - 2025-01-01

### Changed
- Initial implementation

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