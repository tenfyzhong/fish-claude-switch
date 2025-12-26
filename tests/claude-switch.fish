# Source the function to test
source (dirname (status --current-filename))/../functions/claude-switch.fish

# Test helper functions
function _test_setup_env
    set -gx TEST_HOME (mktemp -d)
    set -gx OLD_HOME $HOME
    set -gx HOME $TEST_HOME
end

function _test_cleanup_env
    if set -q TEST_HOME
        rm -rf "$TEST_HOME"
        set -ge TEST_HOME
    end
    if set -q OLD_HOME
        set -gx HOME $OLD_HOME
        set -ge OLD_HOME
    end
end

function _test_create_mock_config
    set -l models_file "$HOME/.config/claude/claude-switch/models.json"
    mkdir -p (dirname "$models_file")
    echo '{
  "providers": {
    "TestProvider": {
      "auth_token": "test-token-123",
      "base_url": "https://test.example.com/anthropic",
      "models": [
        {
          "model": "test-model-v1",
          "description": "Test Model Description",
          "default_haiku_model": "test-haiku",
          "default_opus_model": "test-opus",
          "default_sonnet_model": "test-sonnet"
        },
        {
          "model": "test-model-v2",
          "description": "Test Model 2 Description"
        }
      ]
    },
    "Xiaomi": {
      "auth_token": "mimo-api-key",
      "base_url": "https://api.xiaomimimo.com/anthropic",
      "models": [
        {
          "model": "mimo-v2-flash",
          "description": "Xiaomi Mimo V2 Flash",
          "default_haiku_model": "mimo-v2-flash",
          "default_opus_model": "mimo-v2-flash",
          "default_sonnet_model": "mimo-v2-flash"
        }
      ]
    }
  }
}' > "$models_file"
end

function _test_create_current_config
    set -l current_file "$HOME/.config/claude/claude-switch/current.json"
    mkdir -p (dirname "$current_file")
    echo '{"provider": "TestProvider", "model": "test-model-v1"}' > "$current_file"
end

# Help tests
@test "claude-switch --help shows help" (_test_setup_env; claude-switch --help 2>&1 | string collect; _test_cleanup_env) = "claude-switch: Switch between different Claude code provider APIs
Usage: claude-switch [subcommand] [options]

Main Subcommands:
  edit                    Edit the configuration file
  switch <provider/model> Switch to a model
  clear                   Clear current model configuration
  export                  Export environment variables from current model
  unexport                Unload all ANTHROPIC environment variables
  help                    Show this help message

Provider Management:
  provider add <name> [--auth-token <token>] [--base-url <url>]
                        Add a new provider (interactive if options omitted)
  provider list          List all providers
  provider remove <name> Remove a provider (prompts if has models)
  provider update <name> [--auth-token <token>] [--base-url <url>]
                        Update provider settings (partial update)

Model Management:
  model add <provider> <model> [--description <desc>] [--default-haiku <model>] [--default-opus <model>] [--default-sonnet <model>]
                        Add a new model (interactive if description omitted)
  model list [provider]  List models (all or for specific provider)
  model remove <provider> <model>
                        Remove a model (prompts if currently active)
  model update <provider> <model> [--description <desc>] [--default-haiku <model>] [--default-opus <model>] [--default-sonnet <model>]
                        Update model settings (partial update)

Examples:
  claude-switch                          Show current configuration
  claude-switch model list               List all models
  claude-switch switch Xiaomi/mimo-v2-flash  Switch to a model
  claude-switch export                   Export environment variables
  claude-switch provider add MyProvider --auth-token token123 --base-url https://api.example.com
  claude-switch model add MyProvider my-model --description \"My Model\"
  claude-switch model list MyProvider    List models for a provider

Configuration:
  Config file: ~/.config/claude/claude-switch/models.json
  Current model: ~/.config/claude/claude-switch/current.json
  Editor:      \$EDITOR (or vim/vi/nano)

Environment Variables Set (using set -gx):
  ANTHROPIC_AUTH_TOKEN (from provider)
  ANTHROPIC_BASE_URL (from provider)
  ANTHROPIC_MODEL (from model)
  ANTHROPIC_DEFAULT_HAIKU_MODEL (optional)
  ANTHROPIC_DEFAULT_OPUS_MODEL (optional)
  ANTHROPIC_DEFAULT_SONNET_MODEL (optional)"

@test "claude-switch -h shows help" (_test_setup_env; claude-switch -h 2>&1 | string collect; _test_cleanup_env) = "claude-switch: Switch between different Claude code provider APIs
Usage: claude-switch [subcommand] [options]

Main Subcommands:
  edit                    Edit the configuration file
  switch <provider/model> Switch to a model
  clear                   Clear current model configuration
  export                  Export environment variables from current model
  unexport                Unload all ANTHROPIC environment variables
  help                    Show this help message

Provider Management:
  provider add <name> [--auth-token <token>] [--base-url <url>]
                        Add a new provider (interactive if options omitted)
  provider list          List all providers
  provider remove <name> Remove a provider (prompts if has models)
  provider update <name> [--auth-token <token>] [--base-url <url>]
                        Update provider settings (partial update)

Model Management:
  model add <provider> <model> [--description <desc>] [--default-haiku <model>] [--default-opus <model>] [--default-sonnet <model>]
                        Add a new model (interactive if description omitted)
  model list [provider]  List models (all or for specific provider)
  model remove <provider> <model>
                        Remove a model (prompts if currently active)
  model update <provider> <model> [--description <desc>] [--default-haiku <model>] [--default-opus <model>] [--default-sonnet <model>]
                        Update model settings (partial update)

Examples:
  claude-switch                          Show current configuration
  claude-switch model list               List all models
  claude-switch switch Xiaomi/mimo-v2-flash  Switch to a model
  claude-switch export                   Export environment variables
  claude-switch provider add MyProvider --auth-token token123 --base-url https://api.example.com
  claude-switch model add MyProvider my-model --description \"My Model\"
  claude-switch model list MyProvider    List models for a provider

Configuration:
  Config file: ~/.config/claude/claude-switch/models.json
  Current model: ~/.config/claude/claude-switch/current.json
  Editor:      \$EDITOR (or vim/vi/nano)

Environment Variables Set (using set -gx):
  ANTHROPIC_AUTH_TOKEN (from provider)
  ANTHROPIC_BASE_URL (from provider)
  ANTHROPIC_MODEL (from model)
  ANTHROPIC_DEFAULT_HAIKU_MODEL (optional)
  ANTHROPIC_DEFAULT_OPUS_MODEL (optional)
  ANTHROPIC_DEFAULT_SONNET_MODEL (optional)"

# Show current tests
@test "claude-switch shows current when no config" (_test_setup_env; _test_create_mock_config; claude-switch 2>&1 | string collect; _test_cleanup_env) = "Current Claude Configuration:

  No model is currently set. It will use the official model.

To set a model, run: claude-switch switch <provider>/<model>
To list available models, run: claude-switch model list"

@test "claude-switch shows current with config" (_test_setup_env; _test_create_mock_config; _test_create_current_config; claude-switch 2>&1 | string collect; _test_cleanup_env) = "Current Claude Configuration:

  Provider: TestProvider
  Model: test-model-v1
  Description: Test Model Description
  Base URL: https://test.example.com/anthropic"

# List models tests
@test "claude-switch model list lists models" (_test_setup_env; _test_create_mock_config; claude-switch model list 2>&1 | string collect; _test_cleanup_env) = "Available Claude Models:

Provider: TestProvider
  Auth token: test-token-123
  Base URL: https://test.example.com/anthropic
  Models:
    - test-model-v1: Test Model Description
    - test-model-v2: Test Model 2 Description

Provider: Xiaomi
  Auth token: mimo-api-key
  Base URL: https://api.xiaomimimo.com/anthropic
  Models:
    - mimo-v2-flash: Xiaomi Mimo V2 Flash"

@test "claude-switch model list shows provider" (_test_setup_env; _test_create_mock_config; claude-switch model list 2>&1 | grep -c "Provider: TestProvider"; _test_cleanup_env) = "1"

@test "claude-switch model list shows model names" (_test_setup_env; _test_create_mock_config; claude-switch model list 2>&1 | grep -c "test-model"; _test_cleanup_env) = "2"

# Switch model tests
@test "claude-switch switch switches to valid model" (_test_setup_env; _test_create_mock_config; claude-switch switch TestProvider/test-model-v1 2>&1 | string replace -r 'Config saved to: .+' 'Config saved to: REDACTED' | string collect; _test_cleanup_env) = "✓ Success: Switched to 'TestProvider/test-model-v1'
  Provider: TestProvider
  Model: test-model-v1
  Description: Test Model Description

  Config saved to: REDACTED

  Run 'claude-switch export' to load environment variables"

@test "claude-switch switch creates current.json when switching" (_test_setup_env; _test_create_mock_config; claude-switch switch TestProvider/test-model-v1 >/dev/null 2>&1; test -f "$HOME/.config/claude/claude-switch/current.json" && echo "exists" || echo "missing"; _test_cleanup_env) = "exists"

@test "claude-switch switch current.json has correct content after switching" (_test_setup_env; _test_create_mock_config; claude-switch switch TestProvider/test-model-v1 >/dev/null 2>&1; cat "$HOME/.config/claude/claude-switch/current.json" | string collect; _test_cleanup_env) = "{\"provider\": \"TestProvider\", \"model\": \"test-model-v1\"}"

@test "claude-switch switch fails without provider/model format" (_test_setup_env; _test_create_mock_config; claude-switch switch test-model-v1 2>&1 | string collect; _test_cleanup_env) = "Error: Model must be specified as 'provider/model' (e.g., 'Xiaomi/mimo-v2-flash')

Available Claude Models:

Provider: TestProvider
  Auth token: test-token-123
  Base URL: https://test.example.com/anthropic
  Models:
    - test-model-v1: Test Model Description
    - test-model-v2: Test Model 2 Description

Provider: Xiaomi
  Auth token: mimo-api-key
  Base URL: https://api.xiaomimimo.com/anthropic
  Models:
    - mimo-v2-flash: Xiaomi Mimo V2 Flash"

@test "claude-switch switch fails with invalid provider" (_test_setup_env; _test_create_mock_config; claude-switch switch InvalidProvider/test-model-v1 2>&1 | string collect; _test_cleanup_env) = "✗ Failed: Provider 'InvalidProvider' not found in config.

Available providers:
  - TestProvider
  - Xiaomi"

@test "claude-switch switch fails with invalid model" (_test_setup_env; _test_create_mock_config; claude-switch switch TestProvider/invalid-model 2>&1 | string collect; _test_cleanup_env) = "✗ Failed: Model 'invalid-model' not found in provider 'TestProvider'.

Available models in 'TestProvider':
  - test-model-v1: Test Model Description
  - test-model-v2: Test Model 2 Description"

# Clear tests
@test "claude-switch clear clears config" (_test_setup_env; _test_create_mock_config; _test_create_current_config; claude-switch clear 2>&1 | grep -c "Cleared model configuration file"; _test_cleanup_env) = "1"

@test "claude-switch clear removes current.json" (_test_setup_env; _test_create_mock_config; _test_create_current_config; claude-switch clear >/dev/null 2>&1; test -f "$HOME/.config/claude/claude-switch/current.json" && echo "exists" || echo "missing"; _test_cleanup_env) = "missing"

# Export tests
@test "claude-switch export exports env vars" (_test_setup_env; _test_create_mock_config; _test_create_current_config; claude-switch export >/dev/null 2>&1; echo "$ANTHROPIC_AUTH_TOKEN"; _test_cleanup_env) = "test-token-123"

@test "claude-switch export exports env vars base url" (_test_setup_env; _test_create_mock_config; _test_create_current_config; claude-switch export >/dev/null 2>&1; echo "$ANTHROPIC_BASE_URL"; _test_cleanup_env) = "https://test.example.com/anthropic"

@test "claude-switch export sets ANTHROPIC_MODEL" (_test_setup_env; _test_create_mock_config; _test_create_current_config; claude-switch export >/dev/null 2>&1; echo "$ANTHROPIC_MODEL"; _test_cleanup_env) = "test-model-v1"

@test "claude-switch export sets default model vars" (_test_setup_env; _test_create_mock_config; _test_create_current_config; claude-switch export >/dev/null 2>&1; echo "$ANTHROPIC_DEFAULT_HAIKU_MODEL"; _test_cleanup_env) = "test-haiku"

@test "claude-switch export shows success message" (_test_setup_env; _test_create_mock_config; _test_create_current_config; claude-switch export 2>&1 | string collect; _test_cleanup_env) = "✓ Loaded model: TestProvider/test-model-v1"

@test "claude-switch export handles missing current.json" (_test_setup_env; _test_create_mock_config; claude-switch export 2>&1; echo "status:$status"; _test_cleanup_env) = "status:0"

# Unexport tests
@test "claude-switch unexport unexports env vars" (_test_setup_env; _test_create_mock_config; _test_create_current_config; claude-switch export >/dev/null 2>&1; claude-switch unexport 2>&1 | string collect; _test_cleanup_env) = "✓ Unloaded all ANTHROPIC environment variables"

@test "claude-switch unexport clears ANTHROPIC_AUTH_TOKEN" (_test_setup_env; _test_create_mock_config; _test_create_current_config; claude-switch export >/dev/null 2>&1; claude-switch unexport >/dev/null 2>&1; test -z "$ANTHROPIC_AUTH_TOKEN" && echo "cleared" || echo "not cleared"; _test_cleanup_env) = "cleared"

@test "claude-switch unexport clears ANTHROPIC_BASE_URL" (_test_setup_env; _test_create_mock_config; _test_create_current_config; claude-switch export >/dev/null 2>&1; claude-switch unexport >/dev/null 2>&1; test -z "$ANTHROPIC_BASE_URL" && echo "cleared" || echo "not cleared"; _test_cleanup_env) = "cleared"

@test "claude-switch unexport clears all env vars" (_test_setup_env; _test_create_mock_config; _test_create_current_config; claude-switch export >/dev/null 2>&1; claude-switch unexport >/dev/null 2>&1; test -z "$ANTHROPIC_MODEL" -a -z "$ANTHROPIC_DEFAULT_HAIKU_MODEL" && echo "all cleared" || echo "not all cleared"; _test_cleanup_env) = "all cleared"

@test "claude-switch export calls unexport first" (_test_setup_env; _test_create_mock_config; _test_create_current_config; set -gx ANTHROPIC_AUTH_TOKEN "old-token"; claude-switch export >/dev/null 2>&1; echo "$ANTHROPIC_AUTH_TOKEN"; _test_cleanup_env) = "test-token-123"

# Default config creation test
@test "claude-switch creates default config on first run" (_test_setup_env; claude-switch switch Xiaomi/mimo-v2-flash >/dev/null 2>&1; test -f "$HOME/.config/claude/claude-switch/models.json" && echo "exists" || echo "missing"; _test_cleanup_env) = "exists"

# Error handling tests
@test "claude-switch export shows error for invalid JSON in current.json" (_test_setup_env; _test_create_mock_config; mkdir -p "$HOME/.config/claude/claude-switch"; echo "invalid json" > "$HOME/.config/claude/claude-switch/current.json"; claude-switch export 2>&1 | string collect; _test_cleanup_env) = "Warning: current.json contains invalid JSON, skipping export"

@test "claude-switch export shows error for missing provider in export" (_test_setup_env; _test_create_mock_config; mkdir -p "$HOME/.config/claude/claude-switch"; echo '{"provider": "NonExistent", "model": "test-model"}' > "$HOME/.config/claude/claude-switch/current.json"; claude-switch export 2>&1 | string collect; _test_cleanup_env) = "Error: Provider 'NonExistent' not found in models.json"

@test "claude-switch export shows error for missing model in export" (_test_setup_env; _test_create_mock_config; mkdir -p "$HOME/.config/claude/claude-switch"; echo '{"provider": "TestProvider", "model": "non-existent"}' > "$HOME/.config/claude/claude-switch/current.json"; claude-switch export 2>&1 | string collect; _test_cleanup_env) = "Error: Model 'non-existent' not found in provider 'TestProvider'"

# Provider CRUD tests
@test "claude-switch provider list lists providers" (_test_setup_env; _test_create_mock_config; claude-switch provider list 2>&1 | grep -c "Provider: TestProvider"; _test_cleanup_env) = "1"

@test "claude-switch provider add adds provider with args" (_test_setup_env; _test_create_mock_config; echo "n" | claude-switch provider add NewProvider --auth-token new-token --base-url https://new.example.com >/dev/null 2>&1; jq -r '.providers.NewProvider.auth_token' "$HOME/.config/claude/claude-switch/models.json" 2>/dev/null; _test_cleanup_env) = "new-token"

@test "claude-switch provider add fails if provider exists" (_test_setup_env; _test_create_mock_config; claude-switch provider add TestProvider --auth-token token --base-url url 2>&1 | string collect; _test_cleanup_env) = "Error: Provider 'TestProvider' already exists"

@test "claude-switch provider remove removes provider" (_test_setup_env; _test_create_mock_config; echo "y" | claude-switch provider remove Xiaomi >/dev/null 2>&1; jq -r '.providers | has("Xiaomi")' "$HOME/.config/claude/claude-switch/models.json" 2>/dev/null; _test_cleanup_env) = "false"

@test "claude-switch provider remove fails if provider not found" (_test_setup_env; _test_create_mock_config; claude-switch provider remove NonExistent 2>&1 | string collect; _test_cleanup_env) = "Error: Provider 'NonExistent' not found"

@test "claude-switch provider update updates provider" (_test_setup_env; _test_create_mock_config; claude-switch provider update TestProvider --auth-token updated-token >/dev/null 2>&1; jq -r '.providers.TestProvider.auth_token' "$HOME/.config/claude/claude-switch/models.json" 2>/dev/null; _test_cleanup_env) = "updated-token"

# Model CRUD tests
@test "claude-switch model list lists all models" (_test_setup_env; _test_create_mock_config; claude-switch model list 2>&1 | grep -c "test-model-v1"; _test_cleanup_env) = "1"

@test "claude-switch model list filters by provider" (_test_setup_env; _test_create_mock_config; claude-switch model list TestProvider 2>&1 | grep -c "test-model"; _test_cleanup_env) = "2"

@test "claude-switch model add adds model with args" (_test_setup_env; _test_create_mock_config; claude-switch model add TestProvider new-model --description "New Model" --default-haiku "" --default-opus "" --default-sonnet "" >/dev/null 2>&1; jq -r '.providers.TestProvider.models[] | select(.model == "new-model") | .description' "$HOME/.config/claude/claude-switch/models.json" 2>/dev/null; _test_cleanup_env) = "New Model"

@test "claude-switch model add fails if model exists" (_test_setup_env; _test_create_mock_config; claude-switch model add TestProvider test-model-v1 --description "Test" --default-haiku "" --default-opus "" --default-sonnet "" 2>&1 | string collect; _test_cleanup_env) = "Error: Model 'test-model-v1' already exists in provider 'TestProvider'"

@test "claude-switch model add fails if provider not found" (_test_setup_env; _test_create_mock_config; claude-switch model add NonExistent model --description "Test" --default-haiku "" --default-opus "" --default-sonnet "" 2>&1 | string collect; _test_cleanup_env) = "Error: Provider 'NonExistent' not found"

@test "claude-switch model remove removes model" (_test_setup_env; _test_create_mock_config; echo "y" | claude-switch model remove TestProvider test-model-v2 >/dev/null 2>&1; test (jq -r '.providers.TestProvider.models[] | select(.model == "test-model-v2") | .model' "$HOME/.config/claude/claude-switch/models.json" 2>/dev/null | wc -l) -eq 0 && echo "removed" || echo "not removed"; _test_cleanup_env) = "removed"

@test "claude-switch model remove fails if model not found" (_test_setup_env; _test_create_mock_config; claude-switch model remove TestProvider non-existent 2>&1 | string collect; _test_cleanup_env) = "Error: Model 'non-existent' not found in provider 'TestProvider'"

@test "claude-switch model update updates model" (_test_setup_env; _test_create_mock_config; claude-switch model update TestProvider test-model-v1 --description "Updated Description" --default-haiku "test-haiku" --default-opus "test-opus" --default-sonnet "test-sonnet" >/dev/null 2>&1; jq -r '.providers.TestProvider.models[] | select(.model == "test-model-v1") | .description' "$HOME/.config/claude/claude-switch/models.json" 2>/dev/null; _test_cleanup_env) = "Updated Description"

@test "claude-switch model update fails if model not found" (_test_setup_env; _test_create_mock_config; claude-switch model update TestProvider non-existent --description "Test" --default-haiku "" --default-opus "" --default-sonnet "" 2>&1 | string collect; _test_cleanup_env) = "Error: Model 'non-existent' not found in provider 'TestProvider'"
