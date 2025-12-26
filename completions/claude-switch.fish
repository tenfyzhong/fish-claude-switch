# Helper functions for completions
function _claude-switch_complete_models
    set -l models_file "$HOME/.config/claude/claude-switch/models.json"
    if test -f "$models_file" -a -r "$models_file"
        jq -r '.providers | to_entries[] | .key as $provider | .value.models[] | "\($provider)/\(.model)|\(.description // "")"' "$models_file" 2>/dev/null | while read -l line
            set -l parts (string split '|' "$line")
            set -l model_spec "$parts[1]"
            set -l description "$parts[2]"
            # If description is empty, use model name as default
            if test -z "$description"
                set -l model_parts (string split '/' "$model_spec")
                set description "$model_parts[-1]"
            end
            printf '%s\t%s\n' "$model_spec" "$description"
        end
    end
end

function _claude-switch_complete_providers
    set -l models_file "$HOME/.config/claude/claude-switch/models.json"
    if test -f "$models_file" -a -r "$models_file"
        jq -r '.providers | keys[]' "$models_file" 2>/dev/null
    end
end

function _claude-switch_complete_models_for_provider
    set -l models_file "$HOME/.config/claude/claude-switch/models.json"
    set -l provider "$argv[1]"
    if test -f "$models_file" -a -r "$models_file" -a -n "$provider"
        jq -r ".providers.\"$provider\".models[] | .model" "$models_file" 2>/dev/null
    end
end

# Main command completion
complete -c claude-switch -f -d "Switch between different Claude code provider APIs"

# Main subcommands
complete -c claude-switch -n '__fish_use_subcommand' -a edit -d "Edit configuration file"
complete -c claude-switch -n '__fish_use_subcommand' -a switch -d "Switch to a model"
complete -c claude-switch -n '__fish_use_subcommand' -a clear -d "Clear current model configuration"
complete -c claude-switch -n '__fish_use_subcommand' -a export -d "Export environment variables from current model"
complete -c claude-switch -n '__fish_use_subcommand' -a unexport -d "Unload all ANTHROPIC environment variables"
complete -c claude-switch -n '__fish_use_subcommand' -a help -d "Show help message"
complete -c claude-switch -n '__fish_use_subcommand' -a provider -d "Manage providers"
complete -c claude-switch -n '__fish_use_subcommand' -a model -d "Manage models"

# Switch subcommand
complete -c claude-switch -n '__fish_seen_subcommand_from switch' -x -a "(_claude-switch_complete_models)" -d "Provider/model"

# Provider subcommands
complete -c claude-switch -n '__fish_seen_subcommand_from provider' -n 'not __fish_seen_subcommand_from add list remove update' -a add -d "Add a new provider"
complete -c claude-switch -n '__fish_seen_subcommand_from provider' -n 'not __fish_seen_subcommand_from add list remove update' -a list -d "List all providers"
complete -c claude-switch -n '__fish_seen_subcommand_from provider' -n 'not __fish_seen_subcommand_from add list remove update' -a remove -d "Remove a provider"
complete -c claude-switch -n '__fish_seen_subcommand_from provider' -n 'not __fish_seen_subcommand_from add list remove update' -a update -d "Update a provider"

# Provider add
complete -c claude-switch -n '__fish_seen_subcommand_from provider; and __fish_seen_subcommand_from add' -n '__fish_is_nth_token 3' -x -a "(_claude-switch_complete_providers)" -d "Provider name"
complete -c claude-switch -n '__fish_seen_subcommand_from provider; and __fish_seen_subcommand_from add' -l auth-token -d "Auth token"
complete -c claude-switch -n '__fish_seen_subcommand_from provider; and __fish_seen_subcommand_from add' -l base-url -d "Base URL"

# Provider remove
complete -c claude-switch -n '__fish_seen_subcommand_from provider; and __fish_seen_subcommand_from remove' -n '__fish_is_nth_token 3' -x -a "(_claude-switch_complete_providers)" -d "Provider name"

# Provider update
complete -c claude-switch -n '__fish_seen_subcommand_from provider; and __fish_seen_subcommand_from update' -n '__fish_is_nth_token 3' -x -a "(_claude-switch_complete_providers)" -d "Provider name"
complete -c claude-switch -n '__fish_seen_subcommand_from provider; and __fish_seen_subcommand_from update' -l auth-token -d "Auth token"
complete -c claude-switch -n '__fish_seen_subcommand_from provider; and __fish_seen_subcommand_from update' -l base-url -d "Base URL"

# Model subcommands
complete -c claude-switch -n '__fish_seen_subcommand_from model' -n 'not __fish_seen_subcommand_from add list remove update' -a add -d "Add a new model"
complete -c claude-switch -n '__fish_seen_subcommand_from model' -n 'not __fish_seen_subcommand_from add list remove update' -a list -d "List models"
complete -c claude-switch -n '__fish_seen_subcommand_from model' -n 'not __fish_seen_subcommand_from add list remove update' -a remove -d "Remove a model"
complete -c claude-switch -n '__fish_seen_subcommand_from model' -n 'not __fish_seen_subcommand_from add list remove update' -a update -d "Update a model"

# Model add
complete -c claude-switch -n '__fish_seen_subcommand_from model; and __fish_seen_subcommand_from add' -n '__fish_is_nth_token 3' -x -a "(_claude-switch_complete_providers)" -d "Provider name"
complete -c claude-switch -n '__fish_seen_subcommand_from model; and __fish_seen_subcommand_from add' -n '__fish_is_nth_token 4' -x -d "Model name"
complete -c claude-switch -n '__fish_seen_subcommand_from model; and __fish_seen_subcommand_from add' -l description -d "Model description"
complete -c claude-switch -n '__fish_seen_subcommand_from model; and __fish_seen_subcommand_from add' -l default-haiku -d "Default haiku model"
complete -c claude-switch -n '__fish_seen_subcommand_from model; and __fish_seen_subcommand_from add' -l default-opus -d "Default opus model"
complete -c claude-switch -n '__fish_seen_subcommand_from model; and __fish_seen_subcommand_from add' -l default-sonnet -d "Default sonnet model"
complete -c claude-switch -n '__fish_seen_subcommand_from model; and __fish_seen_subcommand_from add' -l small-fast-model -d "Small fast model"

# Model list
complete -c claude-switch -n '__fish_seen_subcommand_from model; and __fish_seen_subcommand_from list' -n '__fish_is_nth_token 3' -x -a "(_claude-switch_complete_providers)" -d "Provider name (optional)"

# Helper function to get provider from commandline for model update/remove
function _claude-switch_get_provider_from_cmdline
    set -l tokens (commandline -op)
    # For "claude-switch model update/remove ProviderName ModelName"
    # tokens[1] = "claude-switch", tokens[2] = "model", tokens[3] = "update"/"remove", tokens[4] = ProviderName
    if test (count $tokens) -ge 4
        echo $tokens[4]
    end
end

# Model remove
complete -c claude-switch -n '__fish_seen_subcommand_from model; and __fish_seen_subcommand_from remove' -n '__fish_is_nth_token 3' -x -a "(_claude-switch_complete_providers)" -d "Provider name"
complete -c claude-switch -n '__fish_seen_subcommand_from model; and __fish_seen_subcommand_from remove' -n '__fish_is_nth_token 4' -x -a "(_claude-switch_complete_models_for_provider (_claude-switch_get_provider_from_cmdline))" -d "Model name"

# Model update
complete -c claude-switch -n '__fish_seen_subcommand_from model; and __fish_seen_subcommand_from update' -n '__fish_is_nth_token 3' -x -a "(_claude-switch_complete_providers)" -d "Provider name"
complete -c claude-switch -n '__fish_seen_subcommand_from model; and __fish_seen_subcommand_from update' -n '__fish_is_nth_token 4' -x -a "(_claude-switch_complete_models_for_provider (_claude-switch_get_provider_from_cmdline))" -d "Model name"
complete -c claude-switch -n '__fish_seen_subcommand_from model; and __fish_seen_subcommand_from update' -l description -d "Model description"
complete -c claude-switch -n '__fish_seen_subcommand_from model; and __fish_seen_subcommand_from update' -l default-haiku -d "Default haiku model"
complete -c claude-switch -n '__fish_seen_subcommand_from model; and __fish_seen_subcommand_from update' -l default-opus -d "Default opus model"
complete -c claude-switch -n '__fish_seen_subcommand_from model; and __fish_seen_subcommand_from update' -l default-sonnet -d "Default sonnet model"
complete -c claude-switch -n '__fish_seen_subcommand_from model; and __fish_seen_subcommand_from update' -l small-fast-model -d "Small fast model"

# Backward compatibility: -h/--help flags
complete -c claude-switch -s h -l help -d "Show help message"
