function claude --description 'Run Claude with current model configuration'
    # Check if claude command exists
    if not command -q claude
        echo "Error: 'claude' command not found." >&2
        echo "Make sure Claude CLI is installed." >&2
        return 1
    end

    claude-switch export &>/dev/null

    # Run claude with all arguments
    command claude $argv

    claude-switch unexport &>/dev/null
end
