# fish-claude-switch

A Fish shell plugin for switching between different Claude code provider APIs. Easily manage multiple providers (official Anthropic, Xiaomi Mimo, custom endpoints) and switch between models with automatic environment variable configuration.

## Features

- ✅ **Multiple Provider Support** - Configure and switch between different API providers
- ✅ **Interactive Setup** - Guided prompts for adding providers and models
- ✅ **Tab Completions** - Full Fish shell tab completion support
- ✅ **Environment Management** - Automatic export/unexport of ANTHROPIC_* variables
- ✅ **Seamless Integration** - Wrapper function for the `claude` command
- ✅ **Safe Configuration** - JSON-based config with validation
- ✅ **Disable/Enable** - Temporarily disable providers or models without removing them

## Installation

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/tenfyzhong/fish-claude-switch.git
cd fish-claude-switch

# Link functions and completions to Fish config
ln -s (pwd)/functions/claude-switch.fish ~/.config/fish/functions/
ln -s (pwd)/functions/claude.fish ~/.config/fish/functions/
ln -s (pwd)/completions/claude-switch.fish ~/.config/fish/completions/

# Reload Fish configuration
source ~/.config/fish/config.fish
```

### Using Fisher (Recommended)

```bash
# Install with Fisher (if you use it)
fisher install tenfyzhong/fish-claude-switch
```

## Quick Start

### 1. Add a Provider

```bash
# Interactive mode (will prompt for token and URL)
claude-switch provider add Xiaomi

# Or specify parameters directly
claude-switch provider add Xiaomi \
  --auth-token "your-api-key" \
  --base-url "https://api.xiaomimimo.com/anthropic"
```

### 2. Add Models

```bash
# Interactive mode
claude-switch model add Xiaomi mimo-v2-flash

# With description and default models
claude-switch model add Xiaomi mimo-v2-flash \
  --description "Xiaomi Mimo V2 Flash" \
  --default-haiku "mimo-v2-flash" \
  --default-opus "mimo-v2-flash" \
  --default-sonnet "mimo-v2-flash"
```

### 3. Switch Models

```bash
# List available models
claude-switch model list

# Switch to a specific model
claude-switch switch Xiaomi/mimo-v2-flash

# Export environment variables
claude-switch export
```

### 4. Use with Claude CLI

```bash
# Use the wrapper (automatically handles env vars)
claude "what is 2+2"

# Or manually export then use claude
claude-switch export
claude "what is 2+2"
claude-switch unexport  # Clean up when done
```

## Commands

### Main Commands

```bash
claude-switch                    # Show current configuration
claude-switch edit               # Edit configuration file
claude-switch switch <provider/model>  # Switch to a model
claude-switch clear              # Clear current configuration
claude-switch export             # Export environment variables
claude-switch unexport           # Unload environment variables
claude-switch help               # Show help message
```

### Provider Management

```bash
claude-switch provider add <name> [--auth-token <token>] [--base-url <url>]
claude-switch provider list [--all]      # Use --all to show disabled providers
claude-switch provider remove <name>
claude-switch provider update <name> [--auth-token <token>] [--base-url <url>]
claude-switch provider disable <name>     # Disable a provider
claude-switch provider enable <name>      # Enable a disabled provider
```

### Model Management

```bash
claude-switch model add <provider> <model> [--description <desc>] [--default-haiku <model>] [--default-opus <model>] [--default-sonnet <model>] [--small-fast-model <model>]
claude-switch model list [provider] [--all]  # Use --all to show disabled models
claude-switch model remove <provider> <model>
claude-switch model update <provider> <model> [--description <desc>] [--default-haiku <model>] [--default-opus <model>] [--default-sonnet <model>] [--small-fast-model <model>]
claude-switch model disable <provider> <model>   # Disable a model
claude-switch model enable <provider> <model>    # Enable a disabled model
```

## Configuration

### Config Files

Configuration is stored in `~/.config/claude/claude-switch/`:

- **models.json** - Provider and model definitions
- **current.json** - Currently selected model

### Example Configuration

```json
{
  "providers": {
    "Xiaomi": {
      "auth_token": "your-api-key",
      "base_url": "https://api.xiaomimimo.com/anthropic",
      "disabled": false,
      "models": [
        {
          "model": "mimo-v2-flash",
          "description": "Xiaomi Mimo V2 Flash",
          "default_haiku_model": "mimo-v2-flash",
          "default_opus_model": "mimo-v2-flash",
          "default_sonnet_model": "mimo-v2-flash",
          "small_fast_model": "mimo-v2-flash",
          "disabled": false
        }
      ]
    },
    "Official": {
      "auth_token": "sk-ant-api03-...",
      "base_url": "https://api.anthropic.com",
      "disabled": false,
      "models": [
        {
          "model": "claude-3-5-sonnet-20241022",
          "description": "Claude 3.5 Sonnet",
          "disabled": false
        }
      ]
    }
  }
}
```

### Environment Variables

When you run `claude-switch export`, the following environment variables are set:

- `ANTHROPIC_AUTH_TOKEN` - API authentication token
- `ANTHROPIC_BASE_URL` - API endpoint URL
- `ANTHROPIC_MODEL` - Selected model name
- `ANTHROPIC_DEFAULT_HAIKU_MODEL` - Default Haiku model (optional)
- `ANTHROPIC_DEFAULT_OPUS_MODEL` - Default Opus model (optional)
- `ANTHROPIC_DEFAULT_SONNET_MODEL` - Default Sonnet model (optional)
- `ANTHROPIC_SMALL_FAST_MODEL` - Small fast model (optional)

## Usage Examples

### Example 1: Multiple Providers

```bash
# Add official Anthropic provider
claude-switch provider add Official \
  --auth-token "sk-ant-api03-..." \
  --base-url "https://api.anthropic.com"

# Add Xiaomi provider
claude-switch provider add Xiaomi \
  --auth-token "your-xiaomi-key" \
  --base-url "https://api.xiaomimimo.com/anthropic"

# Add models for each
claude-switch model add Official claude-3-5-sonnet-20241022 \
  --description "Claude 3.5 Sonnet"

claude-switch model add Xiaomi mimo-v2-flash \
  --description "Xiaomi Mimo V2 Flash"

# Switch between them
claude-switch switch Official/claude-3-5-sonnet-20241022
claude-switch switch Xiaomi/mimo-v2-flash
```

### Example 2: Interactive Workflow

```bash
# Start interactive setup
claude-switch provider add MyProvider
# Enter auth token: my-token-123
# Enter base URL: https://api.example.com/anthropic

claude-switch model add MyProvider my-model
# Enter description: My Custom Model
# Enter default haiku model: (optional, press Enter to skip)
# Enter default opus model: (optional, press Enter to skip)
# Enter default sonnet model: (optional, press Enter to skip)
# Enter small fast model: (optional, press Enter to skip)

# Switch and use
claude-switch switch MyProvider/my-model
claude-switch export
claude "write a hello world in python"
```

### Example 3: Using the Wrapper

```bash
# The claude wrapper automatically handles export/unexport
claude-switch switch Xiaomi/mimo-v2-flash

# Just use claude directly
claude "explain quantum computing"

# The wrapper:
# 1. Exports environment variables
# 2. Runs the actual claude command
# 3. Cleans up environment variables
```

### Example 4: Disabling Providers and Models

You can temporarily disable a provider or model without removing it from your configuration:

```bash
# Disable a provider (all its models will be hidden)
claude-switch provider disable Xiaomi

# Disable a specific model
claude-switch model disable Xiaomi mimo-v2-flash

# List all providers including disabled ones
claude-switch provider list --all

# List all models including disabled ones
claude-switch model list --all

# Re-enable when needed
claude-switch provider enable Xiaomi
claude-switch model enable Xiaomi mimo-v2-flash

# Note: You cannot switch to a disabled provider or model
claude-switch switch Xiaomi/mimo-v2-flash
# Error: Provider 'Xiaomi' is disabled.
# To enable, run: claude-switch provider enable Xiaomi
```

## Testing

Run the test suite:

```bash
# Run main tests
fishtape tests/claude-switch.fish

# Run completion tests
fishtape tests/claude-switch-completions.fish
```

The tests use temporary directories and don't affect your actual configuration.

## Requirements

- **Fish shell** (≥ 3.0)
- **jq** - For JSON processing
- **claude CLI** - For actual usage (optional for testing)

## Troubleshooting

### "jq command is required"

Install jq: `brew install jq` (macOS) or `apt-get install jq` (Linux)

### "Provider not found"

Check your configuration: `claude-switch provider list`

### Tab completions not working

Ensure the completion file is linked and reload Fish: `source ~/.config/fish/config.fish`

### Environment variables not set

Run `claude-switch export` manually or use the `claude` wrapper function

### "Provider is disabled" or "Model is disabled"

If you see this error when trying to switch, the provider or model has been disabled. To re-enable:

```bash
# Check all providers including disabled ones
claude-switch provider list --all

# Enable the provider
claude-switch provider enable <provider-name>

# Or enable a specific model
claude-switch model enable <provider-name> <model-name>
```

## Contributing

Contributions are welcome! Please ensure:

1. All tests pass
2. Code follows existing patterns
3. Add tests for new features

## License

MIT License - See [LICENSE](LICENSE) file for details

## Related

- [Claude CLI](https://docs.anthropic.com/claude/docs/claude-code) - Official Claude command line tool
- [Fish Shell](https://fishshell.com/) - Friendly interactive shell
