# Repository Guidelines

## Project Structure

This repository contains a Fish shell tool for switching between Claude API providers and models.

- `functions/`: Main source code (Claude-switch core functions)
  - `claude-switch.fish`: Main functionality
  - `claude.fish`: Helper functions
- `completions/`: Fish shell auto-completions
  - `claude-switch.fish`: Completion script
- `tests/`: Test files
  - `claude-switch.fish`: Main tests
  - `claude-switch-completions.fish`: Completion tests

## Build, Test, and Development Commands

### Testing

- `fish -c 'fishtape tests/*.fish'`: Run all tests using fishtape framework

### Development

- Source the functions directly or install via Fisher for testing locally

## Coding Style

- Follow standard Fish shell conventions
- Indent with 4 spaces
- Use clear, descriptive function names prefixed with underscores for internal functions

## Testing Guidelines

- Tests use the `fishtape` framework
- Test files should mirror functionality in `functions/`
- All tests must pass before submitting a PR
- Run tests locally with `fishtape tests/*.fish` before pushing

## Commit & Pull Request Guidelines

### Commit Messages

- Use clear, descriptive messages (e.g., "Add provider disable feature")
- Keep messages concise but informative

### Pull Requests

- Link related issues if applicable
- Ensure all tests pass
- Keep PRs focused on a single feature or bug fix
- Update documentation if changing functionality
