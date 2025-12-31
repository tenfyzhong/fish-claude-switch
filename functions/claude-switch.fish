function claude-switch --description 'Switch between different Claude code provider APIs'
    # Support -h/--help flag for backward compatibility (main command)
    if test (count $argv) -gt 0
        if test "$argv[1]" = "-h"; or test "$argv[1]" = "--help"
            _claude-switch_help
            return 0
        end
    end

    # Config file paths
    set -l models_file "$HOME/.config/claude/claude-switch/models.json"
    set -l current_file "$HOME/.config/claude/claude-switch/current.json"

    # Check if jq is available
    if not command -q jq
        echo "Error: 'jq' command is required for JSON parsing." >&2
        echo "Install with: brew install jq" >&2
        return 1
    end

    # Create config directory and default config if it doesn't exist
    if not test -f "$models_file"
        _claude-switch_create_default_config "$models_file"
        echo "Created default config at: $models_file" >&2
        echo "You can edit this file to add your own models." >&2
        echo ""
    end

    # Check if models file exists (after potential creation)
    if not test -f "$models_file"
        echo "Error: Models file not found at $models_file" >&2
        return 1
    end

    # Get subcommand
    set -l subcommand "$argv[1]"

    # Route to subcommands
    switch "$subcommand"
        case edit
            # Check for help flag
            if test (count $argv) -ge 2
                if test "$argv[2]" = "-h"; or test "$argv[2]" = "--help"
                    _claude-switch_help_edit
                    return 0
                end
            end
            _claude-switch_edit_config "$models_file"
            return $status

        case switch
            # Check for help flag
            if test (count $argv) -ge 2
                if test "$argv[2]" = "-h"; or test "$argv[2]" = "--help"
                    _claude-switch_help_switch
                    return 0
                end
            end
            if test (count $argv) -lt 2
                echo "Error: 'switch' requires a provider/model argument" >&2
                echo "Usage: claude-switch switch <provider/model>" >&2
                return 1
            end
            set -l model_spec "$argv[2]"
            if not string match -q '*/*' "$model_spec"
                echo "Error: Model must be specified as 'provider/model' (e.g., 'Xiaomi/mimo-v2-flash')" >&2
                echo "" >&2
                _claude-switch_list_models "$models_file"
                return 1
            end
            set -l parts (string split '/' "$model_spec" -m 1)
            set -l provider "$parts[1]"
            set -l model "$parts[2]"
            _claude-switch_set_model "$models_file" "$current_file" "$provider" "$model"
            return $status

        case clear
            # Check for help flag
            if test (count $argv) -ge 2
                if test "$argv[2]" = "-h"; or test "$argv[2]" = "--help"
                    _claude-switch_help_clear
                    return 0
                end
            end
            _claude-switch_clear "$current_file"
            return $status

        case export
            # Check for help flag
            if test (count $argv) -ge 2
                if test "$argv[2]" = "-h"; or test "$argv[2]" = "--help"
                    _claude-switch_help_export
                    return 0
                end
            end
            _claude-switch_export_env "$current_file" "$models_file"
            return $status

        case unexport
            # Check for help flag
            if test (count $argv) -ge 2
                if test "$argv[2]" = "-h"; or test "$argv[2]" = "--help"
                    _claude-switch_help_unexport
                    return 0
                end
            end
            _claude-switch_unexport_env
            return $status

        case provider
            # Check for help flag
            if test (count $argv) -ge 2
                if test "$argv[2]" = "-h"; or test "$argv[2]" = "--help"
                    _claude-switch_help_provider
                    return 0
                end
            end
            if test (count $argv) -lt 2
                echo "Error: 'provider' requires a subcommand (add, list, remove, update, disable, enable)" >&2
                echo "Use 'claude-switch provider --help' for more information" >&2
                return 1
            end
            set -l provider_cmd "$argv[2]"
            switch "$provider_cmd"
                case add
                    # Check for help flag
                    if test (count $argv) -ge 3
                        if test "$argv[3]" = "-h"; or test "$argv[3]" = "--help"
                            _claude-switch_help_provider
                            return 0
                        end
                    end
                    # Check for help flag in arguments
                    set -l i 4
                    while test $i -le (count $argv)
                        if test "$argv[$i]" = "-h"; or test "$argv[$i]" = "--help"
                            _claude-switch_help_provider
                            return 0
                        end
                        set i (math $i + 1)
                    end
                    if test (count $argv) -lt 3
                        echo "Error: 'provider add' requires a provider name" >&2
                        echo "Usage: claude-switch provider add <name> [--auth-token <token>] [--base-url <url>]" >&2
                        return 1
                    end
                    set -l provider_name "$argv[3]"
                    set -l auth_token ""
                    set -l base_url ""
                    # Parse flags
                    set -l i 4
                    while test $i -le (count $argv)
                        switch "$argv[$i]"
                            case --auth-token
                                set i (math $i + 1)
                                if test $i -le (count $argv)
                                    set auth_token "$argv[$i]"
                                end
                            case --base-url
                                set i (math $i + 1)
                                if test $i -le (count $argv)
                                    set base_url "$argv[$i]"
                                end
                        end
                        set i (math $i + 1)
                    end
                    _claude-switch_provider_add "$models_file" "$provider_name" "$auth_token" "$base_url"
                    return $status

                case list
                    set -l show_all 0
                    # Parse flags
                    set -l i 3
                    while test $i -le (count $argv)
                        if test "$argv[$i]" = "--all"
                            set show_all 1
                        end
                        set i (math $i + 1)
                    end
                    _claude-switch_provider_list "$models_file" "$show_all"
                    return 0

                case remove
                    if test (count $argv) -lt 3
                        echo "Error: 'provider remove' requires a provider name" >&2
                        echo "Usage: claude-switch provider remove <name>" >&2
                        return 1
                    end
                    set -l provider_name "$argv[3]"
                    _claude-switch_provider_remove "$models_file" "$provider_name"
                    return $status

                case update
                    # Check for help flag
                    if test (count $argv) -ge 3
                        if test "$argv[3]" = "-h"; or test "$argv[3]" = "--help"
                            _claude-switch_help_provider
                            return 0
                        end
                    end
                    # Check for help flag in arguments
                    set -l i 4
                    while test $i -le (count $argv)
                        if test "$argv[$i]" = "-h"; or test "$argv[$i]" = "--help"
                            _claude-switch_help_provider
                            return 0
                        end
                        set i (math $i + 1)
                    end
                    if test (count $argv) -lt 3
                        echo "Error: 'provider update' requires a provider name" >&2
                        echo "Usage: claude-switch provider update <name> [--auth-token <token>] [--base-url <url>]" >&2
                        return 1
                    end
                    set -l provider_name "$argv[3]"
                    set -l auth_token ""
                    set -l base_url ""
                    # Parse flags
                    set -l i 4
                    while test $i -le (count $argv)
                        switch "$argv[$i]"
                            case --auth-token
                                set i (math $i + 1)
                                if test $i -le (count $argv)
                                    set auth_token "$argv[$i]"
                                end
                            case --base-url
                                set i (math $i + 1)
                                if test $i -le (count $argv)
                                    set base_url "$argv[$i]"
                                end
                        end
                        set i (math $i + 1)
                    end
                    _claude-switch_provider_update "$models_file" "$provider_name" "$auth_token" "$base_url"
                    return $status

                case disable
                    if test (count $argv) -lt 3
                        echo "Error: 'provider disable' requires a provider name" >&2
                        echo "Usage: claude-switch provider disable <name>" >&2
                        return 1
                    end
                    set -l provider_name "$argv[3]"
                    _claude-switch_provider_disable "$models_file" "$provider_name"
                    return $status

                case enable
                    if test (count $argv) -lt 3
                        echo "Error: 'provider enable' requires a provider name" >&2
                        echo "Usage: claude-switch provider enable <name>" >&2
                        return 1
                    end
                    set -l provider_name "$argv[3]"
                    _claude-switch_provider_enable "$models_file" "$provider_name"
                    return $status

                case '*'
                    echo "Error: Unknown provider subcommand '$provider_cmd'" >&2
                    echo "Available subcommands: add, list, remove, update, disable, enable" >&2
                    return 1
            end

        case model
            # Check for help flag
            if test (count $argv) -ge 2
                if test "$argv[2]" = "-h"; or test "$argv[2]" = "--help"
                    _claude-switch_help_model
                    return 0
                end
            end
            if test (count $argv) -lt 2
                echo "Error: 'model' requires a subcommand (add, list, remove, update, disable, enable)" >&2
                echo "Use 'claude-switch model --help' for more information" >&2
                return 1
            end
            set -l model_cmd "$argv[2]"
            switch "$model_cmd"
                case add
                    # Check for help flag
                    if test (count $argv) -ge 3
                        if test "$argv[3]" = "-h"; or test "$argv[3]" = "--help"
                            _claude-switch_help_model
                            return 0
                        end
                    end
                    if test (count $argv) -ge 4
                        if test "$argv[4]" = "-h"; or test "$argv[4]" = "--help"
                            _claude-switch_help_model
                            return 0
                        end
                    end
                    if test (count $argv) -lt 4
                        echo "Error: 'model add' requires provider and model name" >&2
                        echo "Usage: claude-switch model add <provider> <model> [--description <desc>] [--default-opus <model>] [--default-sonnet <model>] [--default-haiku <model>] [--small-fast-model <model>]" >&2
                        return 1
                    end
                    set -l provider_name "$argv[3]"
                    set -l model_name "$argv[4]"
                    set -l description ""
                    set -l default_opus ""
                    set -l default_sonnet ""
                    set -l default_haiku ""
                    set -l small_fast_model ""
                    set -l has_description 0
                    set -l has_default_opus 0
                    set -l has_default_sonnet 0
                    set -l has_default_haiku 0
                    set -l has_small_fast_model 0
                    set -l disable_flag ""
                    set -l has_disable_flag 0
                    # Parse flags
                    set -l i 5
                    while test $i -le (count $argv)
                        if test "$argv[$i]" = "-h"; or test "$argv[$i]" = "--help"
                            _claude-switch_help_model
                            return 0
                        end
                        switch "$argv[$i]"
                            case --description
                                set i (math $i + 1)
                                if test $i -le (count $argv)
                                    set description "$argv[$i]"
                                    set has_description 1
                                end
                            case --default-opus
                                set i (math $i + 1)
                                if test $i -le (count $argv)
                                    set default_opus "$argv[$i]"
                                    set has_default_opus 1
                                end
                            case --default-sonnet
                                set i (math $i + 1)
                                if test $i -le (count $argv)
                                    set default_sonnet "$argv[$i]"
                                    set has_default_sonnet 1
                                end
                            case --default-haiku
                                set i (math $i + 1)
                                if test $i -le (count $argv)
                                    set default_haiku "$argv[$i]"
                                    set has_default_haiku 1
                                end
                            case --small-fast-model
                                set i (math $i + 1)
                                if test $i -le (count $argv)
                                    set small_fast_model "$argv[$i]"
                                    set has_small_fast_model 1
                                end
                            case --disable-flag
                                set i (math $i + 1)
                                if test $i -le (count $argv)
                                    set disable_flag "$argv[$i]"
                                    set has_disable_flag 1
                                end
                        end
                        set i (math $i + 1)
                    end
                    _claude-switch_model_add "$models_file" "$provider_name" "$model_name" "$description" "$default_opus" "$default_sonnet" "$default_haiku" "$small_fast_model" "$disable_flag" "$has_description" "$has_default_opus" "$has_default_sonnet" "$has_default_haiku" "$has_small_fast_model" "$has_disable_flag"
                    return $status

                case list
                    set -l provider_name ""
                    set -l show_all 0
                    set -l i 3
                    while test $i -le (count $argv)
                        if test "$argv[$i]" = "--all"
                            set show_all 1
                        else
                            set provider_name "$argv[$i]"
                        end
                        set i (math $i + 1)
                    end
                    _claude-switch_model_list "$models_file" "$provider_name" "$show_all"
                    return 0

                case remove
                    if test (count $argv) -lt 4
                        echo "Error: 'model remove' requires provider and model name" >&2
                        echo "Usage: claude-switch model remove <provider> <model>" >&2
                        return 1
                    end
                    set -l provider_name "$argv[3]"
                    set -l model_name "$argv[4]"
                    _claude-switch_model_remove "$models_file" "$current_file" "$provider_name" "$model_name"
                    return $status

                case update
                    # Check for help flag
                    if test (count $argv) -ge 3
                        if test "$argv[3]" = "-h"; or test "$argv[3]" = "--help"
                            _claude-switch_help_model
                            return 0
                        end
                    end
                    if test (count $argv) -ge 4
                        if test "$argv[4]" = "-h"; or test "$argv[4]" = "--help"
                            _claude-switch_help_model
                            return 0
                        end
                    end
                    if test (count $argv) -lt 4
                        echo "Error: 'model update' requires provider and model name" >&2
                        echo "Usage: claude-switch model update <provider> <model> [--description <desc>] [--default-opus <model>] [--default-sonnet <model>] [--default-haiku <model>] [--small-fast-model <model>]" >&2
                        return 1
                    end
                    set -l provider_name "$argv[3]"
                    set -l model_name "$argv[4]"
                    set -l description ""
                    set -l default_opus ""
                    set -l default_sonnet ""
                    set -l default_haiku ""
                    set -l small_fast_model ""
                    set -l has_description 0
                    set -l has_default_opus 0
                    set -l has_default_sonnet 0
                    set -l has_default_haiku 0
                    set -l has_small_fast_model 0
                    set -l disable_flag ""
                    set -l has_disable_flag 0
                    # Parse flags
                    set -l i 5
                    while test $i -le (count $argv)
                        if test "$argv[$i]" = "-h"; or test "$argv[$i]" = "--help"
                            _claude-switch_help_model
                            return 0
                        end
                        switch "$argv[$i]"
                            case --description
                                set i (math $i + 1)
                                if test $i -le (count $argv)
                                    set description "$argv[$i]"
                                    set has_description 1
                                end
                            case --default-opus
                                set i (math $i + 1)
                                if test $i -le (count $argv)
                                    set default_opus "$argv[$i]"
                                    set has_default_opus 1
                                end
                            case --default-sonnet
                                set i (math $i + 1)
                                if test $i -le (count $argv)
                                    set default_sonnet "$argv[$i]"
                                    set has_default_sonnet 1
                                end
                            case --default-haiku
                                set i (math $i + 1)
                                if test $i -le (count $argv)
                                    set default_haiku "$argv[$i]"
                                    set has_default_haiku 1
                                end
                            case --small-fast-model
                                set i (math $i + 1)
                                if test $i -le (count $argv)
                                    set small_fast_model "$argv[$i]"
                                    set has_small_fast_model 1
                                end
                            case --disable-flag
                                set i (math $i + 1)
                                if test $i -le (count $argv)
                                    set disable_flag "$argv[$i]"
                                    set has_disable_flag 1
                                end
                        end
                        set i (math $i + 1)
                    end
                    _claude-switch_model_update "$models_file" "$provider_name" "$model_name" "$description" "$default_opus" "$default_sonnet" "$default_haiku" "$small_fast_model" "$disable_flag" "$has_description" "$has_default_opus" "$has_default_sonnet" "$has_default_haiku" "$has_small_fast_model" "$has_disable_flag"
                    return $status

                case disable
                    if test (count $argv) -lt 4
                        echo "Error: 'model disable' requires provider and model name" >&2
                        echo "Usage: claude-switch model disable <provider> <model>" >&2
                        return 1
                    end
                    set -l provider_name "$argv[3]"
                    set -l model_name "$argv[4]"
                    _claude-switch_model_disable "$models_file" "$provider_name" "$model_name"
                    return $status

                case enable
                    if test (count $argv) -lt 4
                        echo "Error: 'model enable' requires provider and model name" >&2
                        echo "Usage: claude-switch model enable <provider> <model>" >&2
                        return 1
                    end
                    set -l provider_name "$argv[3]"
                    set -l model_name "$argv[4]"
                    _claude-switch_model_enable "$models_file" "$provider_name" "$model_name"
                    return $status

                case '*'
                    echo "Error: Unknown model subcommand '$model_cmd'" >&2
                    echo "Available subcommands: add, list, remove, update, disable, enable" >&2
                    return 1
            end

        case ""
            # No subcommand - show current configuration (backward compatibility)
            _claude-switch_show_current
            return 0

        case '*'
            # Unknown subcommand
            echo "Error: Unknown subcommand '$subcommand'" >&2
            echo "" >&2
            _claude-switch_help
            return 1
    end
end

# Interactive input helpers
function _claude-switch_prompt_string -a prompt default_value
    if test -n "$default_value"
        read -P "$prompt [$default_value]: " value
        if test $status -ne 0
            # User pressed Ctrl-C
            return 130
        end
        if test -z "$value"
            echo "$default_value"
        else
            echo "$value"
        end
    else
        read -P "$prompt: " value
        if test $status -ne 0
            # User pressed Ctrl-C
            return 130
        end
        echo "$value"
    end
end

function _claude-switch_prompt_optional -a prompt
    read -P "$prompt (optional, press Enter to skip): " value
    if test $status -ne 0
        # User pressed Ctrl-C
        return 130
    end
    echo "$value"
end

# Provider CRUD functions
function _claude-switch_provider_add -a models_file provider_name auth_token base_url
    # Check if provider already exists
    set -l exists (jq -r ".providers | has(\"$provider_name\")" "$models_file" 2>/dev/null)
    if test "$exists" = "true"
        echo "Error: Provider '$provider_name' already exists" >&2
        return 1
    end

    # Interactive mode if parameters are missing
    if test -z "$auth_token"
        set auth_token (_claude-switch_prompt_string "Enter auth token" "")
        if test $status -eq 130
            echo "" >&2
            echo "Cancelled." >&2
            return 130
        end
        if test -z "$auth_token"
            echo "Error: Auth token is required" >&2
            return 1
        end
    end

    if test -z "$base_url"
        set base_url (_claude-switch_prompt_string "Enter base URL" "")
        if test $status -eq 130
            echo "" >&2
            echo "Cancelled." >&2
            return 130
        end
        if test -z "$base_url"
            echo "Error: Base URL is required" >&2
            return 1
        end
    end

    # Add provider with empty models array
    jq ".providers.\"$provider_name\" = {
        \"auth_token\": \"$auth_token\",
        \"base_url\": \"$base_url\",
        \"models\": []
    }" "$models_file" > "$models_file.tmp" && mv "$models_file.tmp" "$models_file"

    if test $status -eq 0
        echo "✓ Added provider '$provider_name'"
        return 0
    else
        echo "Error: Failed to add provider" >&2
        return 1
    end
end

function _claude-switch_provider_list -a models_file show_all
    echo "Available Providers:"
    echo ""

    set -l providers (jq -r '.providers | keys[]' "$models_file" 2>/dev/null)
    if test (count $providers) -eq 0
        echo "  No providers configured."
        return 0
    end

    set -l shown_count 0
    for provider in $providers
        set -l disabled (jq -r ".providers.\"$provider\".disabled // false" "$models_file")

        # Skip disabled providers unless show_all is true
        if test "$disabled" = "true" -a "$show_all" != "1"
            continue
        end

        set -l shown_count (math $shown_count + 1)
        set -l status_mark ""
        if test "$disabled" = "true"
            set status_mark " [DISABLED]"
        end
        echo "Provider: $provider$status_mark"
        set -l auth_token (jq -r ".providers.\"$provider\".auth_token" "$models_file")
        set -l base_url (jq -r ".providers.\"$provider\".base_url" "$models_file")
        set -l model_count (jq -r ".providers.\"$provider\".models | length" "$models_file")
        echo "  Auth token: $auth_token"
        echo "  Base URL: $base_url"
        echo "  Models: $model_count"
        echo ""
    end

    if test "$shown_count" -eq 0
        echo "  No providers to display."
        if test "$show_all" = "1"
            echo "  (all providers are disabled)"
        end
        echo ""
    end
end

function _claude-switch_provider_remove -a models_file provider_name
    # Check if provider exists
    set -l exists (jq -r ".providers | has(\"$provider_name\")" "$models_file" 2>/dev/null)
    if test "$exists" != "true"
        echo "Error: Provider '$provider_name' not found" >&2
        return 1
    end

    # Check if provider has models
    set -l model_count (jq -r ".providers.\"$provider_name\".models | length" "$models_file" 2>/dev/null)
    if test "$model_count" -gt 0
        echo "Warning: Provider '$provider_name' has $model_count model(s)." >&2
        read -P "Are you sure you want to delete this provider? (y/N): " confirm
        if test $status -ne 0
            echo "" >&2
            echo "Cancelled." >&2
            return 130
        end
        if not string match -qi "y*" "$confirm"
            echo "Cancelled."
            return 0
        end
    end

    # Remove provider
    jq "del(.providers.\"$provider_name\")" "$models_file" > "$models_file.tmp" && mv "$models_file.tmp" "$models_file"

    if test $status -eq 0
        echo "✓ Removed provider '$provider_name'"
        return 0
    else
        echo "Error: Failed to remove provider" >&2
        return 1
    end
end

function _claude-switch_provider_update -a models_file provider_name auth_token base_url
    # Check if provider exists
    set -l exists (jq -r ".providers | has(\"$provider_name\")" "$models_file" 2>/dev/null)
    if test "$exists" != "true"
        echo "Error: Provider '$provider_name' not found" >&2
        return 1
    end

    # Get current values
    set -l current_auth_token (jq -r ".providers.\"$provider_name\".auth_token" "$models_file")
    set -l current_base_url (jq -r ".providers.\"$provider_name\".base_url" "$models_file")

    # Use current values if not provided
    if test -z "$auth_token"
        set auth_token "$current_auth_token"
    end
    if test -z "$base_url"
        set base_url "$current_base_url"
    end

    # Update provider
    jq ".providers.\"$provider_name\" |= . + {
        \"auth_token\": \"$auth_token\",
        \"base_url\": \"$base_url\"
    }" "$models_file" > "$models_file.tmp" && mv "$models_file.tmp" "$models_file"

    if test $status -eq 0
        echo "✓ Updated provider '$provider_name'"
        return 0
    else
        echo "Error: Failed to update provider" >&2
        return 1
    end
end

function _claude-switch_provider_disable -a models_file provider_name
    # Check if provider exists
    set -l exists (jq -r ".providers | has(\"$provider_name\")" "$models_file" 2>/dev/null)
    if test "$exists" != "true"
        echo "Error: Provider '$provider_name' not found" >&2
        return 1
    end

    # Check if already disabled
    set -l disabled (jq -r ".providers.\"$provider_name\".disabled // false" "$models_file")
    if test "$disabled" = "true"
        echo "Provider '$provider_name' is already disabled"
        return 0
    end

    # Disable provider
    jq ".providers.\"$provider_name\".disabled = true" "$models_file" > "$models_file.tmp" && mv "$models_file.tmp" "$models_file"

    if test $status -eq 0
        echo "✓ Disabled provider '$provider_name'"
        return 0
    else
        echo "Error: Failed to disable provider" >&2
        return 1
    end
end

function _claude-switch_provider_enable -a models_file provider_name
    # Check if provider exists
    set -l exists (jq -r ".providers | has(\"$provider_name\")" "$models_file" 2>/dev/null)
    if test "$exists" != "true"
        echo "Error: Provider '$provider_name' not found" >&2
        return 1
    end

    # Check if already enabled
    set -l disabled (jq -r ".providers.\"$provider_name\".disabled // false" "$models_file")
    if test "$disabled" != "true"
        echo "Provider '$provider_name' is already enabled"
        return 0
    end

    # Enable provider
    jq ".providers.\"$provider_name\".disabled = false" "$models_file" > "$models_file.tmp" && mv "$models_file.tmp" "$models_file"

    if test $status -eq 0
        echo "✓ Enabled provider '$provider_name'"
        return 0
    else
        echo "Error: Failed to enable provider" >&2
        return 1
    end
end

# Model CRUD functions
function _claude-switch_model_add -a models_file provider_name model_name description default_opus default_sonnet default_haiku small_fast_model disable_flag has_description has_default_opus has_default_sonnet has_default_haiku has_small_fast_model has_disable_flag
    # Check if provider exists
    set -l exists (jq -r ".providers | has(\"$provider_name\")" "$models_file" 2>/dev/null)
    if test "$exists" != "true"
        echo "Error: Provider '$provider_name' not found" >&2
        return 1
    end

    # Check if model already exists
    set -l model_exists (jq -r ".providers.\"$provider_name\".models[] | select(.model == \"$model_name\") | .model" "$models_file" 2>/dev/null)
    if test -n "$model_exists"
        echo "Error: Model '$model_name' already exists in provider '$provider_name'" >&2
        return 1
    end

    # Interactive mode if description is missing (not provided via command line)
    if test "$has_description" -eq 0
        set description (_claude-switch_prompt_optional "Enter description")
        if test $status -eq 130
            echo "" >&2
            echo "Cancelled." >&2
            return 130
        end
    end

    # Interactive mode for default model fields if missing (not provided via command line)
    if test "$has_default_opus" -eq 0
        set default_opus (_claude-switch_prompt_optional "Enter default opus model")
        if test $status -eq 130
            echo "" >&2
            echo "Cancelled." >&2
            return 130
        end
    end

    if test "$has_default_sonnet" -eq 0
        set default_sonnet (_claude-switch_prompt_optional "Enter default sonnet model")
        if test $status -eq 130
            echo "" >&2
            echo "Cancelled." >&2
            return 130
        end
    end

    if test "$has_default_haiku" -eq 0
        set default_haiku (_claude-switch_prompt_optional "Enter default haiku model")
        if test $status -eq 130
            echo "" >&2
            echo "Cancelled." >&2
            return 130
        end
    end

    if test "$has_small_fast_model" -eq 0
        set small_fast_model (_claude-switch_prompt_optional "Enter small fast model")
        if test $status -eq 130
            echo "" >&2
            echo "Cancelled." >&2
            return 130
        end
    end

    if test "$has_disable_flag" -eq 0
        set disable_flag (_claude-switch_prompt_optional "Enter disable flag")
        if test $status -eq 130
            echo "" >&2
            echo "Cancelled." >&2
            return 130
        end
    end

    # Build model object using jq with --arg
    set -l jq_args --arg model "$model_name"
    if test -n "$description"
        set jq_args $jq_args --arg desc "$description"
    end
    if test -n "$default_opus"
        set jq_args $jq_args --arg opus "$default_opus"
    end
    if test -n "$default_sonnet"
        set jq_args $jq_args --arg sonnet "$default_sonnet"
    end
    if test -n "$default_haiku"
        set jq_args $jq_args --arg haiku "$default_haiku"
    end
    if test -n "$small_fast_model"
        set jq_args $jq_args --arg small_fast "$small_fast_model"
    end
    if test -n "$disable_flag"
        set jq_args $jq_args --arg disable_flag "$disable_flag"
    end

    # Build the model object JSON
    set -l model_obj_expr '{model: $model'
    if test -n "$description"
        set model_obj_expr "$model_obj_expr, description: \$desc"
    end
    if test -n "$default_opus"
        set model_obj_expr "$model_obj_expr, default_opus_model: \$opus"
    end
    if test -n "$default_sonnet"
        set model_obj_expr "$model_obj_expr, default_sonnet_model: \$sonnet"
    end
    if test -n "$default_haiku"
        set model_obj_expr "$model_obj_expr, default_haiku_model: \$haiku"
    end
    if test -n "$small_fast_model"
        set model_obj_expr "$model_obj_expr, small_fast_model: \$small_fast"
    end
    if test -n "$disable_flag"
        set model_obj_expr "$model_obj_expr, disable_flag: \$disable_flag"
    end
    set model_obj_expr "$model_obj_expr}"

    # Add model to provider
    # Build jq command with arguments
    set -l jq_cmd jq
    for arg in $jq_args
        set jq_cmd $jq_cmd $arg
    end
    set jq_cmd $jq_cmd ".providers.\"$provider_name\".models += [$model_obj_expr]" "$models_file"
    $jq_cmd > "$models_file.tmp" && mv "$models_file.tmp" "$models_file"

    if test $status -eq 0
        echo "✓ Added model '$model_name' to provider '$provider_name'"
        return 0
    else
        echo "Error: Failed to add model" >&2
        return 1
    end
end

function _claude-switch_model_list -a models_file provider_name show_all
    if test -n "$provider_name"
        # List models for specific provider
        set -l exists (jq -r ".providers | has(\"$provider_name\")" "$models_file" 2>/dev/null)
        if test "$exists" != "true"
            echo "Error: Provider '$provider_name' not found" >&2
            return 1
        end

        echo "Models for provider '$provider_name':"
        echo ""

        set -l provider_disabled (jq -r ".providers.\"$provider_name\".disabled // false" "$models_file")
        if test "$provider_disabled" = "true"
            echo "  [Provider is disabled]"
            echo ""
        end

        set -l model_count 0
        set -l models (jq -r ".providers.\"$provider_name\".models[] | \"\\(.model)|\\(.description // \"\")|\\(.disabled // false)\"" "$models_file")
        for model in $models
            set -l parts (string split '|' "$model")
            set -l model_name "$parts[1]"
            set -l model_desc "$parts[2]"
            set -l model_disabled "$parts[3]"

            # Skip disabled models unless show_all is true
            if test "$model_disabled" = "true" -a "$show_all" != "1"
                continue
            end

            set -l model_count (math $model_count + 1)
            set -l status_mark ""
            if test "$model_disabled" = "true"
                set status_mark " [DISABLED]"
            end
            echo "  - $model_name$status_mark: $model_desc"
        end

        if test $model_count -eq 0
            if test "$show_all" = "1"
                echo "  No models configured."
            else
                echo "  No enabled models. Use --all to show disabled models."
            end
        end
    else
        # List all models (use existing function)
        _claude-switch_list_models "$models_file" "$show_all"
    end
end

function _claude-switch_model_remove -a models_file current_file provider_name model_name
    # Check if provider exists
    set -l exists (jq -r ".providers | has(\"$provider_name\")" "$models_file" 2>/dev/null)
    if test "$exists" != "true"
        echo "Error: Provider '$provider_name' not found" >&2
        return 1
    end

    # Check if model exists
    set -l model_exists (jq -r ".providers.\"$provider_name\".models[] | select(.model == \"$model_name\") | .model" "$models_file" 2>/dev/null)
    if test -z "$model_exists"
        echo "Error: Model '$model_name' not found in provider '$provider_name'" >&2
        return 1
    end

    # Check if this is the current model
    if test -f "$current_file"
        set -l current_provider (jq -r '.provider' "$current_file" 2>/dev/null)
        set -l current_model (jq -r '.model' "$current_file" 2>/dev/null)
        if test "$current_provider" = "$provider_name" -a "$current_model" = "$model_name"
            echo "Warning: This model is currently active." >&2
            read -P "Are you sure you want to delete it? (y/N): " confirm
            if test $status -ne 0
                echo "" >&2
                echo "Cancelled." >&2
                return 130
            end
            if not string match -qi "y*" "$confirm"
                echo "Cancelled."
                return 0
            end
        end
    end

    # Remove model
    jq ".providers.\"$provider_name\".models |= map(select(.model != \"$model_name\"))" "$models_file" > "$models_file.tmp" && mv "$models_file.tmp" "$models_file"

    if test $status -eq 0
        echo "✓ Removed model '$model_name' from provider '$provider_name'"
        return 0
    else
        echo "Error: Failed to remove model" >&2
        return 1
    end
end

function _claude-switch_model_update -a models_file provider_name model_name description default_opus default_sonnet default_haiku small_fast_model disable_flag has_description has_default_opus has_default_sonnet has_default_haiku has_small_fast_model has_disable_flag
    # Check if provider exists
    set -l exists (jq -r ".providers | has(\"$provider_name\")" "$models_file" 2>/dev/null)
    if test "$exists" != "true"
        echo "Error: Provider '$provider_name' not found" >&2
        return 1
    end

    # Check if model exists
    set -l model_exists (jq -r ".providers.\"$provider_name\".models[] | select(.model == \"$model_name\") | .model" "$models_file" 2>/dev/null)
    if test -z "$model_exists"
        echo "Error: Model '$model_name' not found in provider '$provider_name'" >&2
        return 1
    end

    # Get current model data for default values
    set -l current_model (jq -r ".providers.\"$provider_name\".models[] | select(.model == \"$model_name\")" "$models_file")
    set -l current_description (echo "$current_model" | jq -r '.description // ""')
    set -l current_default_opus (echo "$current_model" | jq -r '.default_opus_model // ""')
    set -l current_default_sonnet (echo "$current_model" | jq -r '.default_sonnet_model // ""')
    set -l current_default_haiku (echo "$current_model" | jq -r '.default_haiku_model // ""')
    set -l current_small_fast_model (echo "$current_model" | jq -r '.small_fast_model // ""')
    set -l current_disable_flag (echo "$current_model" | jq -r '.disable_flag // ""')

    # Track which fields should be updated (1 = update, 0 = keep current)
    set -l update_description 0
    set -l update_default_opus 0
    set -l update_default_sonnet 0
    set -l update_default_haiku 0
    set -l update_small_fast_model 0
    set -l update_disable_flag 0

    # Interactive mode if parameters are missing (use current values as defaults)
    if test "$has_description" -eq 0
        # Interactive mode: prompt with current value as default
        set description (_claude-switch_prompt_string "Enter description" "$current_description")
        if test $status -eq 130
            echo "" >&2
            echo "Cancelled." >&2
            return 130
        end
        # If user entered something different from current, mark for update
        # Note: _claude-switch_prompt_string returns default if user presses Enter
        if test "$description" != "$current_description"
            set update_description 1
        else
            # User pressed Enter, keep current value (don't update)
            set update_description 0
        end
    else
        # Parameter was provided via command line, always update
        set update_description 1
    end

    if test "$has_default_opus" -eq 0
        set default_opus (_claude-switch_prompt_string "Enter default opus model" "$current_default_opus")
        if test $status -eq 130
            echo "" >&2
            echo "Cancelled." >&2
            return 130
        end
        if test "$default_opus" != "$current_default_opus"
            set update_default_opus 1
        else
            set update_default_opus 0
        end
    else
        set update_default_opus 1
    end

    if test "$has_default_sonnet" -eq 0
        set default_sonnet (_claude-switch_prompt_string "Enter default sonnet model" "$current_default_sonnet")
        if test $status -eq 130
            echo "" >&2
            echo "Cancelled." >&2
            return 130
        end
        if test "$default_sonnet" != "$current_default_sonnet"
            set update_default_sonnet 1
        else
            set update_default_sonnet 0
        end
    else
        set update_default_sonnet 1
    end

    if test "$has_default_haiku" -eq 0
        set default_haiku (_claude-switch_prompt_string "Enter default haiku model" "$current_default_haiku")
        if test $status -eq 130
            echo "" >&2
            echo "Cancelled." >&2
            return 130
        end
        if test "$default_haiku" != "$current_default_haiku"
            set update_default_haiku 1
        else
            set update_default_haiku 0
        end
    else
        set update_default_haiku 1
    end

    if test "$has_small_fast_model" -eq 0
        set small_fast_model (_claude-switch_prompt_string "Enter small fast model" "$current_small_fast_model")
        if test $status -eq 130
            echo "" >&2
            echo "Cancelled." >&2
            return 130
        end
        if test "$small_fast_model" != "$current_small_fast_model"
            set update_small_fast_model 1
        else
            set update_small_fast_model 0
        end
    else
        set update_small_fast_model 1
    end

    if test "$has_disable_flag" -eq 0
        set disable_flag (_claude-switch_prompt_string "Enter disable flag" "$current_disable_flag")
        if test $status -eq 130
            echo "" >&2
            echo "Cancelled." >&2
            return 130
        end
        if test "$disable_flag" != "$current_disable_flag"
            set update_disable_flag 1
        else
            set update_disable_flag 0
        end
    else
        set update_disable_flag 1
    end

    # Build update object using jq with --arg (only update fields that were changed)
    set -l jq_args --arg model "$model_name"
    set -l update_expr ".providers.\"$provider_name\".models |= map(if .model == \$model then ."

    if test $update_description -eq 1
        set jq_args $jq_args --arg desc "$description"
        set update_expr "$update_expr + {description: \$desc}"
    end
    if test $update_default_opus -eq 1
        set jq_args $jq_args --arg opus "$default_opus"
        set update_expr "$update_expr + {default_opus_model: \$opus}"
    end
    if test $update_default_sonnet -eq 1
        set jq_args $jq_args --arg sonnet "$default_sonnet"
        set update_expr "$update_expr + {default_sonnet_model: \$sonnet}"
    end
    if test $update_default_haiku -eq 1
        set jq_args $jq_args --arg haiku "$default_haiku"
        set update_expr "$update_expr + {default_haiku_model: \$haiku}"
    end
    if test $update_small_fast_model -eq 1
        set jq_args $jq_args --arg small_fast "$small_fast_model"
        set update_expr "$update_expr + {small_fast_model: \$small_fast}"
    end
    if test $update_disable_flag -eq 1
        set jq_args $jq_args --arg disable_flag "$disable_flag"
        set update_expr "$update_expr + {disable_flag: \$disable_flag}"
    end

    set update_expr "$update_expr else . end)"

    # Update model in array
    # Build jq command with arguments
    set -l jq_cmd jq
    for arg in $jq_args
        set jq_cmd $jq_cmd $arg
    end
    set jq_cmd $jq_cmd "$update_expr" "$models_file"
    $jq_cmd > "$models_file.tmp" && mv "$models_file.tmp" "$models_file"

    if test $status -eq 0
        echo "✓ Updated model '$model_name' in provider '$provider_name'"
        return 0
    else
        echo "Error: Failed to update model" >&2
        return 1
    end
end

function _claude-switch_model_disable -a models_file provider_name model_name
    # Check if provider exists
    set -l exists (jq -r ".providers | has(\"$provider_name\")" "$models_file" 2>/dev/null)
    if test "$exists" != "true"
        echo "Error: Provider '$provider_name' not found" >&2
        return 1
    end

    # Check if model exists
    set -l model_exists (jq -r ".providers.\"$provider_name\".models[] | select(.model == \"$model_name\") | .model" "$models_file" 2>/dev/null)
    if test -z "$model_exists"
        echo "Error: Model '$model_name' not found in provider '$provider_name'" >&2
        return 1
    end

    # Check if already disabled
    set -l disabled (jq -r ".providers.\"$provider_name\".models[] | select(.model == \"$model_name\") | .disabled // false" "$models_file")
    if test "$disabled" = "true"
        echo "Model '$model_name' in provider '$provider_name' is already disabled"
        return 0
    end

    # Disable model
    jq ".providers.\"$provider_name\".models |= map(if .model == \"$model_name\" then . + {disabled: true} else . end)" "$models_file" > "$models_file.tmp" && mv "$models_file.tmp" "$models_file"

    if test $status -eq 0
        echo "✓ Disabled model '$model_name' in provider '$provider_name'"
        return 0
    else
        echo "Error: Failed to disable model" >&2
        return 1
    end
end

function _claude-switch_model_enable -a models_file provider_name model_name
    # Check if provider exists
    set -l exists (jq -r ".providers | has(\"$provider_name\")" "$models_file" 2>/dev/null)
    if test "$exists" != "true"
        echo "Error: Provider '$provider_name' not found" >&2
        return 1
    end

    # Check if model exists
    set -l model_exists (jq -r ".providers.\"$provider_name\".models[] | select(.model == \"$model_name\") | .model" "$models_file" 2>/dev/null)
    if test -z "$model_exists"
        echo "Error: Model '$model_name' not found in provider '$provider_name'" >&2
        return 1
    end

    # Check if already enabled
    set -l disabled (jq -r ".providers.\"$provider_name\".models[] | select(.model == \"$model_name\") | .disabled // false" "$models_file")
    if test "$disabled" != "true"
        echo "Model '$model_name' in provider '$provider_name' is already enabled"
        return 0
    end

    # Enable model
    jq ".providers.\"$provider_name\".models |= map(if .model == \"$model_name\" then . + {disabled: false} else . end)" "$models_file" > "$models_file.tmp" && mv "$models_file.tmp" "$models_file"

    if test $status -eq 0
        echo "✓ Enabled model '$model_name' in provider '$provider_name'"
        return 0
    else
        echo "Error: Failed to enable model" >&2
        return 1
    end
end

function _claude-switch_create_default_config -a models_file
    mkdir -p (dirname "$models_file")
    echo '{
  "providers": {}
}' >"$models_file"
end

function _claude-switch_edit_config -a models_file
    set -l editor "$EDITOR"
    if test -z "$editor"
        if command -q vim
            set editor vim
        else if command -q vi
            set editor vi
        else if command -q nano
            set editor nano
        else
            echo "Error: No editor found. Set \$EDITOR or install vim/vi/nano." >&2
            return 1
        end
    end

    echo "Editing config file: $models_file"
    echo "Using editor: $editor"
    echo ""

    $editor "$models_file"

    if jq empty "$models_file" 2>/dev/null
        echo ""
        echo "Config file updated successfully."
        return 0
    else
        echo ""
        echo "Warning: Config file contains invalid JSON." >&2
        echo "Please fix the JSON syntax before using claude-switch." >&2
        return 1
    end
end

function _claude-switch_list_models -a models_file show_all
    echo "Available Claude Models:"
    echo ""

    # Get all providers
    set -l providers (jq -r '.providers | keys[]' "$models_file" 2>/dev/null)

    for provider in $providers
        set -l provider_disabled (jq -r ".providers.\"$provider\".disabled // false" "$models_file")

        # Skip disabled providers unless show_all is true
        if test "$provider_disabled" = "true" -a "$show_all" != "1"
            continue
        end

        set -l status_mark ""
        if test "$provider_disabled" = "true"
            set status_mark " [DISABLED]"
        end
        echo "Provider: $provider$status_mark"
        set -l auth_token (jq -r ".providers.\"$provider\".auth_token" "$models_file")
        set -l base_url (jq -r ".providers.\"$provider\".base_url" "$models_file")
        echo "  Auth token: $auth_token"
        echo "  Base URL: $base_url"
        echo "  Models:"

        set -l model_count 0
        set -l models (jq -r ".providers.\"$provider\".models[] | \"\\(.model)|\\(.description)|\\(.disabled // false)\"" "$models_file")
        for model in $models
            set -l parts (string split '|' "$model")
            set -l model_name "$parts[1]"
            set -l model_desc "$parts[2]"
            set -l model_disabled "$parts[3]"

            # Skip disabled models unless show_all is true
            if test "$model_disabled" = "true" -a "$show_all" != "1"
                continue
            end

            set -l model_status ""
            if test "$model_disabled" = "true"
                set model_status " [DISABLED]"
            end
            echo "    - $model_name$model_status: $model_desc"
            set -l model_count (math $model_count + 1)
        end

        if test $model_count -eq 0
            echo "    No models to display."
        end
        echo ""
    end
end

function _claude-switch_unexport_env
    # Clear environment variables
    set -ge ANTHROPIC_AUTH_TOKEN
    set -ge ANTHROPIC_BASE_URL
    set -ge ANTHROPIC_MODEL
    set -ge ANTHROPIC_DEFAULT_HAIKU_MODEL
    set -ge ANTHROPIC_DEFAULT_OPUS_MODEL
    set -ge ANTHROPIC_DEFAULT_SONNET_MODEL
    set -ge ANTHROPIC_SMALL_FAST_MODEL
    set -ge ANTHROPIC_DISABLE_FLAG

    echo "✓ Unloaded all ANTHROPIC environment variables"
end

function _claude-switch_export_env -a current_file models_file
    # Check if current.json exists and is not empty
    if not test -f "$current_file"
        # No current model set, return success silently
        return 0
    end

    # Validate JSON
    if not jq empty "$current_file" 2>/dev/null
        echo "Warning: current.json contains invalid JSON, skipping export" >&2
        return 1
    end

    # Get current provider and model
    set -l provider (jq -r '.provider' "$current_file" 2>/dev/null)
    set -l model_name (jq -r '.model' "$current_file" 2>/dev/null)

    # If current.json is empty or missing required fields, return silently
    if test -z "$provider" -o -z "$model_name" -o "$provider" = null -o "$model_name" = null
        return 0
    end

    # Check if models.json exists
    if not test -f "$models_file"
        echo "Error: Models file not found at $models_file" >&2
        return 1
    end

    # Validate models.json
    if not jq empty "$models_file" 2>/dev/null
        echo "Error: models.json contains invalid JSON" >&2
        return 1
    end

    # Get provider data from models.json
    set -l provider_data (jq -r ".providers.\"$provider\"" "$models_file")
    if test -z "$provider_data" -o "$provider_data" = null
        echo "Error: Provider '$provider' not found in models.json" >&2
        return 1
    end

    # Get model details
    set -l model_info (echo "$provider_data" | jq -r ".models[] | select(.model == \"$model_name\")")
    if test -z "$model_info" -o "$model_info" = null
        echo "Error: Model '$model_name' not found in provider '$provider'" >&2
        return 1
    end

    # Extract values
    set -l auth_token (echo "$provider_data" | jq -r '.auth_token')
    set -l base_url (echo "$provider_data" | jq -r '.base_url')
    set -l model (echo "$model_info" | jq -r '.model')
    set -l default_haiku (echo "$model_info" | jq -r '.default_haiku_model // ""')
    set -l default_opus (echo "$model_info" | jq -r '.default_opus_model // ""')
    set -l default_sonnet (echo "$model_info" | jq -r '.default_sonnet_model // ""')
    set -l small_fast_model (echo "$model_info" | jq -r '.small_fast_model // ""')
    set -l disable_flag (echo "$model_info" | jq -r '.disable_flag // ""')

    # First, unexport any existing environment variables
    _claude-switch_unexport_env >/dev/null 2>&1

    # Set environment variables
    set -gx ANTHROPIC_AUTH_TOKEN "$auth_token"
    set -gx ANTHROPIC_BASE_URL "$base_url"
    set -gx ANTHROPIC_MODEL "$model"
    if test -n "$default_haiku"
        set -gx ANTHROPIC_DEFAULT_HAIKU_MODEL "$default_haiku"
    end
    if test -n "$default_opus"
        set -gx ANTHROPIC_DEFAULT_OPUS_MODEL "$default_opus"
    end
    if test -n "$default_sonnet"
        set -gx ANTHROPIC_DEFAULT_SONNET_MODEL "$default_sonnet"
    end
    if test -n "$small_fast_model"
        set -gx ANTHROPIC_SMALL_FAST_MODEL "$small_fast_model"
    end
    if test -n "$disable_flag"
        set -gx ANTHROPIC_DISABLE_FLAG "$disable_flag"
    end

    echo "✓ Loaded model: $provider/$model_name"
end

function _claude-switch_show_current
    set -l current_file "$HOME/.config/claude/claude-switch/current.json"
    set -l models_file "$HOME/.config/claude/claude-switch/models.json"

    echo "Current Claude Configuration:"
    echo ""

    # Check if current.json exists
    if not test -f "$current_file"
        echo "  No model is currently set. It will use the official model."
        echo ""
        echo "To set a model, run: claude-switch switch <provider>/<model>"
        echo "To list available models, run: claude-switch model list"
        return 0
    end

    # Read current provider and model
    set -l provider (jq -r '.provider' "$current_file" 2>/dev/null)
    set -l model_name (jq -r '.model' "$current_file" 2>/dev/null)

    if test -z "$provider" -o -z "$model_name"
        echo "  Invalid current.json file"
        return 1
    end

    echo "  Provider: $provider"
    echo "  Model: $model_name"

    # Get full details from models.json if available
    if test -f "$models_file"
        set -l description (jq -r ".providers.\"$provider\".models[] | select(.model == \"$model_name\") | .description" "$models_file" 2>/dev/null)
        if test -n "$description" -a "$description" != null
            echo "  Description: $description"
        end

        set -l base_url (jq -r ".providers.\"$provider\".base_url" "$models_file" 2>/dev/null)
        if test -n "$base_url" -a "$base_url" != null
            echo "  Base URL: $base_url"
        end
    end

    echo ""
end

function _claude-switch_set_model -a models_file current_file provider model
    # Check if provider exists
    set -l provider_exists (jq -r ".providers | has(\"$provider\")" "$models_file" 2>/dev/null)
    if test "$provider_exists" != "true"
        echo "✗ Failed: Provider '$provider' not found in config." >&2
        echo "" >&2
        echo "Available providers:" >&2
        jq -r '.providers | keys[]' "$models_file" 2>/dev/null | while read -l p
            echo "  - $p"
        end
        return 1
    end

    # Get provider data
    set -l provider_data (jq -r ".providers.\"$provider\"" "$models_file" 2>/dev/null)

    # Check if provider is disabled
    set -l provider_disabled (echo "$provider_data" | jq -r '.disabled // false')
    if test "$provider_disabled" = "true"
        echo "✗ Failed: Provider '$provider' is disabled." >&2
        echo "" >&2
        echo "To enable, run: claude-switch provider enable $provider" >&2
        return 1
    end

    # Get model details
    set -l model_info (echo "$provider_data" | jq -r ".models[] | select(.model == \"$model\")")
    if test -z "$model_info" -o "$model_info" = null
        echo "✗ Failed: Model '$model' not found in provider '$provider'." >&2
        echo "" >&2
        echo "Available models in '$provider':" >&2
        echo "$provider_data" | jq -r '.models[] | "  - \(.model): \(.description // "No description")"' 2>/dev/null
        return 1
    end

    # Check if model is disabled
    set -l model_disabled (echo "$model_info" | jq -r '.disabled // false')
    if test "$model_disabled" = "true"
        echo "✗ Failed: Model '$model' in provider '$provider' is disabled." >&2
        echo "" >&2
        echo "To enable, run: claude-switch model enable $provider $model" >&2
        return 1
    end

    # Get provider-level auth_token and base_url
    set -l auth_token (echo "$provider_data" | jq -r '.auth_token')
    set -l base_url (echo "$provider_data" | jq -r '.base_url')

    # Get model-level details
    set -l description (echo "$model_info" | jq -r '.description')
    set -l model_value (echo "$model_info" | jq -r '.model')
    set -l default_haiku (echo "$model_info" | jq -r '.default_haiku_model // ""')
    set -l default_opus (echo "$model_info" | jq -r '.default_opus_model // ""')
    set -l default_sonnet (echo "$model_info" | jq -r '.default_sonnet_model // ""')

    # Create config directory if it doesn't exist
    set -l config_dir (dirname "$current_file")
    if not test -d "$config_dir"
        mkdir -p "$config_dir"
    end

    # Write provider and model to current.json (store the model identifier, not the full model value)
    echo "{\"provider\": \"$provider\", \"model\": \"$model\"}" >"$current_file"

    # Display success message
    echo "✓ Success: Switched to '$provider/$model'"
    echo "  Provider: $provider"
    echo "  Model: $model"
    echo "  Description: $description"
    echo ""
    echo "  Config saved to: $current_file"
    echo ""
    echo "  Run 'claude-switch export' to load environment variables"
end

function _claude-switch_clear -a current_file
    # Clear environment variables
    _claude-switch_unexport_env >/dev/null 2>&1

    # Clear the current.json file
    if test -f "$current_file"
        rm -f "$current_file"
        echo "Cleared model configuration file: $current_file"
    else
        echo "No model configuration file found to clear."
    end

    echo ""
    echo "All ANTHROPIC environment variables have been cleared."
    echo "You can set a new model with: claude-switch switch <provider>/<model>"
end

function _claude-switch_help
    printf 'claude-switch: Switch between different Claude code provider APIs
Usage: claude-switch [subcommand] [options]

Main Subcommands:
  edit                    Edit the configuration file
  switch <provider/model> Switch to a model
  clear                   Clear current model configuration
  export                  Export environment variables from current model
  unexport                Unload all ANTHROPIC environment variables

Provider Management:
  provider add            Add a new provider
  provider list           List all providers
  provider remove         Remove a provider
  provider update         Update provider settings
  provider disable        Disable a provider
  provider enable         Enable a disabled provider

Model Management:
  model add               Add a new model
  model list              List models
  model remove            Remove a model
  model update            Update model settings
  model disable           Disable a model
  model enable            Enable a disabled model

For detailed help on a specific subcommand, use:
  claude-switch <subcommand> --help

Examples:
  claude-switch switch --help      Show detailed help for switch command
  claude-switch provider --help    Show detailed help for provider commands
  claude-switch model --help       Show detailed help for model commands
'
end

function _claude-switch_help_switch
    printf 'claude-switch switch: Switch to a model

Usage: claude-switch switch <provider/model>

Description:
  Switch to a specific model from a provider. The model must be specified
  in the format "provider/model" (e.g., "Xiaomi/mimo-v2-flash").

Arguments:
  <provider/model>        Provider name and model name separated by "/"

Examples:
  claude-switch switch Xiaomi/mimo-v2-flash
  claude-switch switch MyProvider/my-model

After switching, run "claude-switch export" to load environment variables,
or use the "claude" wrapper command which automatically exports them.

Note:
  - The provider and model must exist in the configuration
  - Disabled providers or models cannot be switched to
  - Use "claude-switch model list" to see available models
'
end

function _claude-switch_help_edit
    printf 'claude-switch edit: Edit the configuration file

Usage: claude-switch edit

Description:
  Opens the configuration file in your default editor ($EDITOR).
  If $EDITOR is not set, it will try vim, vi, or nano in that order.

Configuration File:
  ~/.config/claude/claude-switch/models.json

After editing, the JSON syntax will be validated. If invalid, you will
need to fix it before using claude-switch commands.

Note:
  - Make sure the JSON is valid before saving
  - The file structure must match the expected schema
'
end

function _claude-switch_help_clear
    printf 'claude-switch clear: Clear current model configuration

Usage: claude-switch clear

Description:
  Clears the current model configuration and removes all ANTHROPIC
  environment variables. This resets claude-switch to its default state.

What it does:
  - Removes the current.json file
  - Unloads all ANTHROPIC_* environment variables

After clearing, you can set a new model with:
  claude-switch switch <provider/model>
'
end

function _claude-switch_help_export
    printf 'claude-switch export: Export environment variables from current model

Usage: claude-switch export

Description:
  Exports environment variables based on the currently selected model.
  These variables are set using "set -gx" and will be available in the
  current shell session.

Environment Variables Set:
  ANTHROPIC_AUTH_TOKEN              Authentication token from provider
  ANTHROPIC_BASE_URL                Base URL from provider
  ANTHROPIC_MODEL                   Model name
  ANTHROPIC_DEFAULT_HAIKU_MODEL      Optional: Default haiku model
  ANTHROPIC_DEFAULT_OPUS_MODEL       Optional: Default opus model
  ANTHROPIC_DEFAULT_SONNET_MODEL    Optional: Default sonnet model
  ANTHROPIC_SMALL_FAST_MODEL         Optional: Small fast model

Note:
  - Requires a current model to be set (via "claude-switch switch")
  - The "claude" wrapper command automatically calls export before running
  - Use "claude-switch unexport" to remove these variables
'
end

function _claude-switch_help_unexport
    printf 'claude-switch unexport: Unload all ANTHROPIC environment variables

Usage: claude-switch unexport

Description:
  Removes all ANTHROPIC_* environment variables from the current shell session.
  This does not affect the current model configuration (current.json).

Environment Variables Removed:
  ANTHROPIC_AUTH_TOKEN
  ANTHROPIC_BASE_URL
  ANTHROPIC_MODEL
  ANTHROPIC_DEFAULT_HAIKU_MODEL
  ANTHROPIC_DEFAULT_OPUS_MODEL
  ANTHROPIC_DEFAULT_SONNET_MODEL
  ANTHROPIC_SMALL_FAST_MODEL

Note:
  - This only affects the current shell session
  - The current model configuration remains unchanged
  - Use "claude-switch export" to reload variables
'
end

function _claude-switch_help_provider
    printf 'claude-switch provider: Manage Claude API providers

Usage: claude-switch provider <subcommand> [options]

Subcommands:
  add <name> [--auth-token <token>] [--base-url <url>]
    Add a new provider. If auth-token or base-url are omitted, you will
    be prompted interactively.

  list [--all]
    List all providers. Use --all to include disabled providers.

  remove <name>
    Remove a provider. If the provider has models, you will be prompted
    for confirmation.

  update <name> [--auth-token <token>] [--base-url <url>]
    Update provider settings. Only provided fields will be updated.
    Omitted fields keep their current values.

  disable <name>
    Disable a provider. Disabled providers are hidden from normal listings
    and cannot be switched to.

  enable <name>
    Enable a previously disabled provider.

Examples:
  claude-switch provider add MyProvider --auth-token token123 --base-url https://api.example.com
  claude-switch provider list
  claude-switch provider list --all
  claude-switch provider update MyProvider --base-url https://new-url.com
  claude-switch provider disable MyProvider
  claude-switch provider enable MyProvider
  claude-switch provider remove MyProvider

Configuration:
  Providers are stored in ~/.config/claude/claude-switch/models.json
'
end

function _claude-switch_help_model
    printf 'claude-switch model: Manage Claude models

Usage: claude-switch model <subcommand> [options]

Subcommands:
  add <provider> <model> [--description <desc>] [--default-opus <model>]
        [--default-sonnet <model>] [--default-haiku <model>] [--small-fast-model <model>]
    Add a new model to a provider. If description or other optional fields
    are omitted, you will be prompted interactively.

  list [provider] [--all]
    List models. If provider is specified, lists only that provider'\''s models.
    Use --all to include disabled models.

  remove <provider> <model>
    Remove a model from a provider. If the model is currently active,
    you will be prompted for confirmation.

  update <provider> <model> [--description <desc>] [--default-opus <model>]
        [--default-sonnet <model>] [--default-haiku <model>] [--small-fast-model <model>]
    Update model settings. Only provided fields will be updated.
    Omitted fields keep their current values.

  disable <provider> <model>
    Disable a model. Disabled models are hidden from normal listings
    and cannot be switched to.

  enable <provider> <model>
    Enable a previously disabled model.

Examples:
  claude-switch model add MyProvider my-model --description "My Model"
  claude-switch model list
  claude-switch model list MyProvider
  claude-switch model list --all
  claude-switch model update MyProvider my-model --description "Updated Description"
  claude-switch model disable MyProvider my-model
  claude-switch model enable MyProvider my-model
  claude-switch model remove MyProvider my-model

Configuration:
  Models are stored in ~/.config/claude/claude-switch/models.json
'
end
