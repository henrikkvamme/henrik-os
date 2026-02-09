#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract model display name
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')

# Extract current working directory and get basename
cwd=$(echo "$input" | jq -r '.workspace.current_dir // "~"')
cwd_short=$(basename "$cwd")

# Get git branch
branch=""
if [ -d "$cwd/.git" ]; then
    branch=$(cd "$cwd" && git branch --show-current 2>/dev/null || echo "")
    if [ -n "$branch" ]; then
        branch=" [$branch]"
    fi
fi

# Extract context window information
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // null')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')

# Calculate total tokens used in session
total_tokens=$((total_input + total_output))

# Format token counts helper function
format_tokens() {
    local tokens=$1
    if [ $tokens -ge 1000000 ]; then
        echo "$tokens" | awk '{printf "%.1fM", $1/1000000}'
    elif [ $tokens -ge 1000 ]; then
        echo "$tokens" | awk '{printf "%.0fk", $1/1000}'
    else
        echo "${tokens}"
    fi
}

# Format session tokens
tokens_display=$(format_tokens $total_tokens)

# Calculate context window usage in tokens (before auto-compact)
if [ "$used_pct" != "null" ] && [ -n "$used_pct" ]; then
    ctx_used=$(echo "$used_pct $ctx_size" | awk '{printf "%.0f", ($1/100) * $2}')
else
    ctx_used=0
fi

# Format context window display (e.g., "4k/200k")
ctx_used_display=$(format_tokens $ctx_used)
ctx_size_display=$(format_tokens $ctx_size)
ctx_display="${ctx_used_display}/${ctx_size_display}"

# Build the status line
printf "%s | %s%s | tokens: %s | ctx: %s" "$model" "$cwd_short" "$branch" "$tokens_display" "$ctx_display"
