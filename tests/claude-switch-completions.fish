# Source the completion script to test
source (dirname (status --current-filename))/../completions/claude-switch.fish

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
          "name": "test-model-v1",
          "model": "test-model-v1",
          "description": "Test Model Description"
        },
        {
          "name": "test-model-v2",
          "description": "Test Model 2 Description"
        }
      ]
    },
    "Xiaomi": {
      "auth_token": "mimo-api-key",
      "base_url": "https://api.xiaomimimo.com/anthropic",
      "models": [
        {
          "name": "mimo-v2-flash",
          "model": "mimo-v2-flash",
          "description": "Xiaomi Mimo V2 Flash"
        }
      ]
    }
  }
}' > "$models_file"
end

# Test _claude-switch_complete_providers
@test "_claude-switch_complete_providers returns all providers" (_test_setup_env; _test_create_mock_config; _claude-switch_complete_providers | string collect; _test_cleanup_env) = "TestProvider
Xiaomi"

@test "_claude-switch_complete_providers returns empty when no config" (_test_setup_env; set -l result (_claude-switch_complete_providers | string collect); _test_cleanup_env; test -z "$result"; echo $status) = "0"

# Test _claude-switch_complete_models
@test "_claude-switch_complete_models returns all models with descriptions" (_test_setup_env; _test_create_mock_config; _claude-switch_complete_models | string collect; _test_cleanup_env) = "TestProvider/test-model-v1	Test Model Description
TestProvider/test-model-v2	Test Model 2 Description
Xiaomi/mimo-v2-flash	Xiaomi Mimo V2 Flash"

@test "_claude-switch_complete_models returns empty when no config" (_test_setup_env; set -l result (_claude-switch_complete_models | string collect); _test_cleanup_env; test -z "$result"; echo $status) = "0"

# Test _claude-switch_complete_models_for_provider
@test "_claude-switch_complete_models_for_provider returns models for TestProvider" (_test_setup_env; _test_create_mock_config; _claude-switch_complete_models_for_provider TestProvider | string collect; _test_cleanup_env) = "test-model-v1
test-model-v2"

@test "_claude-switch_complete_models_for_provider returns models for Xiaomi" (_test_setup_env; _test_create_mock_config; _claude-switch_complete_models_for_provider Xiaomi | string collect; _test_cleanup_env) = "mimo-v2-flash"

@test "_claude-switch_complete_models_for_provider returns empty for non-existent provider" (_test_setup_env; _test_create_mock_config; set -l result (_claude-switch_complete_models_for_provider NonExistent | string collect); _test_cleanup_env; test -z "$result"; echo $status) = "0"

@test "_claude-switch_complete_models_for_provider returns empty when no provider specified" (_test_setup_env; _test_create_mock_config; set -l result (_claude-switch_complete_models_for_provider "" | string collect); _test_cleanup_env; test -z "$result"; echo $status) = "0"

@test "_claude-switch_complete_models_for_provider returns empty when no config" (_test_setup_env; set -l result (_claude-switch_complete_models_for_provider TestProvider | string collect); _test_cleanup_env; test -z "$result"; echo $status) = "0"

# Test _claude-switch_get_provider_from_cmdline
# Note: This function uses commandline -op which cannot be tested in non-interactive mode
# Instead, we test the function logic by creating a wrapper that simulates the behavior
function _test_get_provider_from_tokens
    set -l tokens $argv
    if test (count $tokens) -ge 4
        echo $tokens[4]
    end
end

@test "_claude-switch_get_provider_from_cmdline logic extracts provider from tokens" (_test_get_provider_from_tokens claude-switch model update TestProvider test-model) = "TestProvider"

@test "_claude-switch_get_provider_from_cmdline logic returns empty when not enough tokens" (_test_setup_env; set -l result (_test_get_provider_from_tokens claude-switch model); _test_cleanup_env; test -z "$result"; echo $status) = "0"

# Test edge cases with models without descriptions
function _test_create_config_without_descriptions
    set -l models_file "$HOME/.config/claude/claude-switch/models.json"
    mkdir -p (dirname "$models_file")
    echo '{
  "providers": {
    "TestProvider": {
      "auth_token": "test-token-123",
      "base_url": "https://test.example.com/anthropic",
      "models": [
        {
          "name": "test-model-v1"
        },
        {
          "name": "test-model-v2",
          "description": "Test Model 2 Description"
        }
      ]
    }
  }
}' > "$models_file"
end

@test "_claude-switch_complete_models handles models without descriptions" (_test_setup_env; _test_create_config_without_descriptions; _claude-switch_complete_models | string collect; _test_cleanup_env) = "TestProvider/test-model-v1	test-model-v1
TestProvider/test-model-v2	Test Model 2 Description"
