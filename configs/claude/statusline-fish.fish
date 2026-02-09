#!/usr/bin/env fish

# Read JSON input from stdin
set input (cat)

# Extract values using jq
set current_dir (echo $input | jq -r '.workspace.current_dir')
set model (echo $input | jq -r '.model.display_name')
set output_style (echo $input | jq -r '.output_style.name')

# Context window information - show FREE tokens remaining
set context_usage (echo $input | jq '.context_window.current_usage')
if test "$context_usage" != "null"
    set current_tokens (echo $input | jq '.context_window.current_usage | .input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    set total_tokens (echo $input | jq -r '.context_window.context_window_size')
    # Calculate free tokens remaining
    set free_tokens (math "$total_tokens - $current_tokens")
    # Format free tokens in K (thousands)
    set free_k (math "round($free_tokens / 1000)")
    # Calculate percentage free
    set free_pct (math "round(100 * $free_tokens / $total_tokens)")
    set context_info "$free_k"K" free ("$free_pct"%)"
else
    set context_info "0K free"
end

# Color codes matching your Starship purple/orange theme
set SEPARATOR (printf '\033[38;2;53;49;44m')
set DIRECTORY (printf '\033[38;2;159;49;226m')
set DURATION (printf '\033[38;2;226;111;49m')
set RESET (printf '\033[0m')

# Print formatted status line inspired by your Starship prompt
# Format: ╭─  <directory> ─  <model> ─  <style> ─  <context>
printf "%s╭─  %s%s %s─  %s%s %s─  %s%s %s─  %s%s%s\n" \
  $SEPARATOR \
  $DIRECTORY \
  $current_dir \
  $SEPARATOR \
  $DURATION \
  $model \
  $SEPARATOR \
  $DURATION \
  $output_style \
  $SEPARATOR \
  $DURATION \
  $context_info \
  $RESET
