# Makefile for nomad.nvim development

.PHONY: help test lint format check install clean coverage docs

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Install development dependencies
	@echo "Installing development dependencies..."
	luarocks install busted
	luarocks install luacheck
	luarocks install luacov
	luarocks install ldoc
	@echo "Installing StyLua..."
	@if ! command -v stylua >/dev/null 2>&1; then \
		echo "Please install StyLua manually: https://github.com/JohnnyMorganz/StyLua#installation"; \
	fi

test: ## Run all tests
	@echo "Running tests..."
	busted --verbose tests/

test-unit: ## Run only unit tests (exclude integration tests)
	@echo "Running unit tests..."
	busted --verbose tests/ --exclude-tags=integration

test-integration: ## Run only integration tests
	@echo "Running integration tests..."
	@echo "Make sure Nomad is running on localhost:4646"
	busted --verbose tests/integration_spec.lua

lint: ## Run Luacheck linting
	@echo "Running Luacheck..."
	luacheck lua/ --config .luacheckrc

format: ## Format code with StyLua
	@echo "Formatting code with StyLua..."
	stylua lua/

format-check: ## Check if code is properly formatted
	@echo "Checking code formatting..."
	stylua --check lua/

coverage: test ## Generate coverage report
	@echo "Generating coverage report..."
	luacov
	@echo "Coverage report generated: luacov.report.out"

docs: ## Generate documentation
	@echo "Generating documentation..."
	ldoc -d docs lua/
	@echo "Documentation generated in docs/"

check: lint format-check test-unit ## Run all checks (lint, format, unit tests)
	@echo "All checks completed!"

clean: ## Clean generated files
	@echo "Cleaning generated files..."
	rm -f luacov.*.out
	rm -rf docs/
	rm -f *.tmp

dev-setup: install ## Setup development environment
	@echo "Setting up development environment..."
	@echo "Development environment ready!"
	@echo "Run 'make help' to see available commands"

ci: lint format-check test ## Run CI checks locally
	@echo "CI checks completed!"

# Docker targets for testing with different Nomad versions
nomad-dev: ## Start Nomad in development mode (Docker)
	@echo "Starting Nomad in development mode..."
	docker run -d --name nomad-dev \
		-p 4646:4646 \
		-e NOMAD_LOCAL_CONFIG='datacenter="dc1" data_dir="/tmp/nomad" server{enabled=true bootstrap_expect=1} client{enabled=true}' \
		hashicorp/nomad:latest

nomad-stop: ## Stop Nomad development container
	@echo "Stopping Nomad development container..."
	docker stop nomad-dev || true
	docker rm nomad-dev || true

nomad-logs: ## Show Nomad development container logs
	docker logs -f nomad-dev 