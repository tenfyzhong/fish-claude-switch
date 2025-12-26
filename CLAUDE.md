# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Fish shell plugin (`fish-claude-switch`) that enables switching between different Claude code provider APIs. It allows users to configure multiple providers (like official Anthropic, Xiaomi Mimo, or custom endpoints) and easily switch between models by setting environment variables that the Claude CLI uses.

## Architecture

### Core Components

**1. Main Function File: `functions/claude-switch.fish`** (1123 lines)

- Primary command handler with subcommand routing
- Configuration management (models.json and current.json)
- Provider CRUD operations
- Model CRUD operations
- Environment variable export/unexport
- Interactive prompts for missing parameters

**2. Wrapper Function: `functions/claude.fish`** (15 lines)

- Wraps the actual `claude` command
- Automatically exports environment variables before running claude
- Cleans up after execution with unexport
- Provides seamless integration with the claude CLI

**3. Completions: `completions/claude-switch.fish`** (110 lines)

- Fish shell tab completions for all subcommands
- Dynamic completions for providers and models from config
- Context-aware completions for nested commands

**4. Tests: `tests/` directory**

- `claude-switch.fish`: 40+ unit tests covering all functionality
- `claude-switch-completions.fish`: 10+ tests for completion functions

### Configuration Files

**Config Location:** `~/.config/claude/claude-switch/`

- **models.json**: Stores provider configurations and model definitions

  ```json
  {
    "providers": {
      "ProviderName": {
        "auth_token": "...",
        "base_url": "...",
        "models": [
          {
            "model": "model-name",
            "description": "...",
            "default_haiku_model": "...",
            "default_opus_model": "...",
            "default_sonnet_model": "..."
          }
        ]
      }
    }
  }
  ```

- **current.json**: Stores currently selected provider/model

  ```json
  {"provider": "ProviderName", "model": "model-name"}
  ```

### Environment Variables Set

When `claude-switch export` is called (or via `claude` wrapper):

- `ANTHROPIC_AUTH_TOKEN` - From provider config
- `ANTHROPIC_BASE_URL` - From provider config
- `ANTHROPIC_MODEL` - From model config
- `ANTHROPIC_DEFAULT_HAIKU_MODEL` - Optional, from model
- `ANTHROPIC_DEFAULT_OPUS_MODEL` - Optional, from model
- `ANTHROPIC_DEFAULT_SONNET_MODEL` - Optional, from model

## Development Commands

### Running Tests

```bash
# Run all tests
fishtape tests/*
```

### Testing Changes

```bash
# Source the function to test manually
source functions/claude-switch.fish

# Test with a temporary config
set -gx TEST_HOME (mktemp -d)
HOME=$TEST_HOME claude-switch --help
```

### Installation for Testing

```bash
fisher install tenfyzhong/fish-claude-switch
```

## Key Implementation Details

### Subcommand Routing

The main function uses a switch statement to route subcommands:

- `edit` - Opens config in $EDITOR
- `switch <provider/model>` - Sets current model
- `clear` - Clears current config and env vars
- `export` - Exports env vars from current.json
- `unexport` - Clears all ANTHROPIC_* env vars
- `provider <cmd>` - Provider management
- `model <cmd>` - Model management

### Interactive Mode

Functions support both CLI args and interactive prompts:

- Missing parameters trigger interactive input
- Uses `_claude-switch_prompt_string` and `_claude-switch_prompt_optional`
- Defaults are shown in brackets
- Ctrl-C returns 130 (cancelled)

### JSON Processing

Uses `jq` for all JSON operations:

- Config creation uses `jq` with `--arg` for safe parameter passing
- Model updates use complex `jq` expressions to merge partial updates
- All JSON validation happens via `jq empty`

### Error Handling

- Returns non-zero status codes on errors
- Validates provider/model existence before operations
- Checks for `jq` availability early
- Provides helpful error messages with available alternatives

### Current Model Tracking

- `current.json` stores only provider name and model name (not full config)
- Full config is read from `models.json` during export
- Allows config changes without updating current.json

## Common Patterns

### Adding New Features

1. Add subcommand to main switch statement
2. Add corresponding completion rules
3. Add helper function for the operation
4. Add tests in `tests/claude-switch.fish`

### Modifying Config Schema

- Update `_claude-switch_create_default_config` for new defaults
- Update all `jq` queries that read/write the schema
- Update completion functions if new fields affect completions
- Update tests with new mock data

### Testing Edge Cases

- Missing config files
- Invalid JSON
- Non-existent providers/models
- Empty/missing optional fields
- User cancellation (Ctrl-C)
- Partial updates (provider/model update with some flags)

## Dependencies

- **fish shell** - Required
- **jq** - Required for JSON processing
- **claude CLI** - Required for actual usage (optional for testing)

## File Structure Summary

```
fish-claude-switch/
├── functions/
│   ├── claude-switch.fish    # Main command (1123 lines)
│   └── claude.fish           # Wrapper for claude CLI (15 lines)
├── completions/
│   └── claude-switch.fish    # Tab completions (110 lines)
├── tests/
│   ├── claude-switch.fish              # Main tests (40+ tests)
│   └── claude-switch-completions.fish  # Completion tests (10+ tests)
├── README.md
├── LICENSE
└── CLAUDE.md (this file)
```

## Usage Examples

```bash
# Initial setup
claude-switch provider add Xiaomi --auth-token "key" --base-url "https://api.xiaomimimo.com/anthropic"
claude-switch model add Xiaomi mimo-v2-flash --description "Xiaomi Mimo V2 Flash"

# Switch and use
claude-switch switch Xiaomi/mimo-v2-flash
claude-switch export
claude "what is 2+2"  # Uses the wrapper

# Or use the wrapper directly (automatically exports)
claude "what is 2+2"

# Check current config
claude-switch
```
