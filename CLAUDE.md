# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Environment

### Docker Development
This repository uses Docker for development. Use the Makefile commands:
- `make` or `make console` - Build Docker image and enter interactive shell with bundler
- `make build` - Build the Docker image
- `make lint` - Run linting in Docker container

### Direct Development
- `bundle install` - Install dependencies
- `rake dev_console` - Start IRB console with Braintree loaded in development environment

## Testing

### Test Commands
- `rake test:unit` - Run unit tests (with automatic linting)
- `rake test:unit[file_name]` - Run specific unit test file
- `rake test:unit[file_name,"test description"]` - Run specific test case
- `rake test:integration` - Run integration tests (requires local gateway server)
- `rake test:integration[file_name]` - Run specific integration test file
- `rake test:all` or `rake` - Run all tests (unit + integration)

### Test Structure
- Unit tests: `spec/unit/**/*_spec.rb` - Can run on any system
- Integration tests: `spec/integration/**/*_spec.rb` - Require local development server
- Uses RSpec testing framework
- Test configuration in `spec/spec_helper.rb`

## Linting and Code Quality
- `rake lint` - Run Rubocop linter
- `rubocop -a` - Auto-correct linting issues
- Linting runs automatically before tests

## Architecture

### Main Gateway Pattern
The SDK uses a gateway pattern where `Braintree::Gateway` provides access to all service gateways:
- Configuration can be passed as hash or `Braintree::Configuration` object
- Each resource has its own gateway (e.g., `gateway.transaction`, `gateway.customer`)
- Gateway methods return either `SuccessfulResult` or `ErrorResult` objects
- Bang methods (e.g., `create!`) return the resource directly or raise `ValidationsFailed`

### Key Components
- `lib/braintree.rb` - Main entry point with all requires
- `lib/braintree/gateway.rb` - Central gateway providing access to all service gateways
- `lib/braintree/configuration.rb` - Configuration management with environment support
- Gateway classes in `lib/braintree/*_gateway.rb` - Service-specific API wrappers
- Model classes in `lib/braintree/*.rb` - Data objects for API resources

### Environments
- `:sandbox` - Testing environment (default for integration)
- `:production` - Live environment
- `:development` - Local development server
- `:qa` - QA environment

### XML Processing
- Supports both LibXML (faster) and REXML (fallback)
- XML parsing/generation in `lib/braintree/xml/`

## Gem Structure
- Entry point: `require "braintree"`
- Version defined in `lib/braintree/version.rb`
- Dependencies: builder, rexml (required), libxml-ruby (optional)
- Supports Ruby 2.6+

## CI/Build
- `ci.sh` - CI script using RVM for different Ruby versions
- `rake gem` - Build gem file
- `rake clean` - Remove generated files

## Important Notes
- Never commit sensitive credentials
- Integration tests require local Braintree gateway server (not for public use)
- SSL certificates bundled in `lib/ssl/`
- Support for multiple credential types: public/private keys, client credentials, access tokens