# Contributing to nomad.nvim

Thank you for your interest in contributing to nomad.nvim! This document provides guidelines and information for contributors.

## Development Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/nomad.nvim.git
   cd nomad.nvim
   ```

2. **Install development dependencies:**
   ```bash
   make dev-setup
   ```

3. **Start a local Nomad instance for testing:**
   ```bash
   make nomad-dev
   ```

## Development Workflow

### Code Style

- We use [StyLua](https://github.com/JohnnyMorganz/StyLua) for code formatting
- Run `make format` to format your code
- Run `make format-check` to check formatting without making changes

### Linting

- We use [Luacheck](https://github.com/mpeterv/luacheck) for linting
- Run `make lint` to check your code
- Configuration is in `.luacheckrc`

### Testing

- We use [Busted](https://olivinelabs.com/busted/) for testing
- Run `make test` to run all tests
- Run `make test-unit` for unit tests only
- Run `make test-integration` for integration tests (requires running Nomad)

### Coverage

- Run `make coverage` to generate a coverage report
- Aim for >80% code coverage on new features

## Pull Request Process

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes:**
   - Write tests for new functionality
   - Update documentation if needed
   - Follow the existing code style

3. **Run the full test suite:**
   ```bash
   make ci
   ```

4. **Commit your changes:**
   ```bash
   git commit -m "feat: add new feature description"
   ```

   We follow [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation changes
   - `style:` for formatting changes
   - `refactor:` for code refactoring
   - `test:` for adding tests
   - `chore:` for maintenance tasks

5. **Push and create a pull request:**
   ```bash
   git push origin feature/your-feature-name
   ```

## Code Organization

```
lua/nomad/
├── init.lua          # Main plugin entry point
├── config.lua        # Configuration management
├── nomad.lua         # Nomad API integration
├── ui.lua            # UI components
├── utils.lua         # Utility functions
├── telescope.lua     # Telescope integration
└── health.lua        # Health checks
```

## Testing Guidelines

### Unit Tests

- Test individual functions and modules
- Mock external dependencies
- Place in `tests/` directory with `_spec.lua` suffix

### Integration Tests

- Test with real Nomad instance
- Use the `integration` tag: `describe("integration test", function() ... end)`
- Ensure tests clean up after themselves

### Example Test

```lua
describe("nomad.config", function()
  it("should merge user configuration", function()
    local config = require("nomad.config")
    local user_config = { nomad = { address = "http://test:4646" } }
    
    config.setup(user_config)
    local result = config.get()
    
    assert.equals("http://test:4646", result.nomad.address)
  end)
end)
```

## Documentation

- Use [LDoc](https://github.com/lunarmodules/LDoc) for code documentation
- Document all public functions
- Include usage examples
- Run `make docs` to generate documentation

### Documentation Example

```lua
--- Starts a Nomad job
-- @function start_job
-- @param job_id string The ID of the job to start
-- @param callback function Callback function(success, error)
-- @usage nomad.start_job("my-job", function(success, error) ... end)
function M.start_job(job_id, callback)
  -- implementation
end
```

## Issue Guidelines

### Bug Reports

- Use the bug report template
- Include reproduction steps
- Provide environment details
- Include relevant logs/errors

### Feature Requests

- Use the feature request template
- Describe the use case clearly
- Consider implementation complexity
- Check existing issues first

## Code Review

All contributions require code review. Please:

- Be patient and responsive to feedback
- Keep discussions focused and constructive
- Address all review comments
- Update tests and documentation as needed

## Release Process

Releases are automated via GitHub Actions:

1. Create a tag: `git tag v1.0.0`
2. Push the tag: `git push origin v1.0.0`
3. GitHub Actions will create a release with changelog

## Getting Help

- Create an issue for bugs or feature requests
- Check existing issues and documentation first
- Be specific and provide context

## License

By contributing, you agree that your contributions will be licensed under the same license as the project. 