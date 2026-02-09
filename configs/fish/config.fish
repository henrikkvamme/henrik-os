# Homebrew PATH (must be first)
fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/sbin
fish_add_path /usr/local/bin

# Additional PATH
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.bun/bin

# Environment variables
set -gx EDITOR nvim
set -gx BUN_INSTALL "$HOME/.bun"

# Aliases (always available)
alias vim="nvim"
alias pn="pnpm"

if status is-interactive
    # Vi mode
    fish_vi_key_bindings

    # Tool initializations
    starship init fish | source
    zoxide init fish | source
    direnv hook fish | source

    # Interactive aliases
    alias ls="eza --color=always --git --no-filesize --icons=always --no-time --no-user --no-permissions"
    alias cd="z"
    alias cld="claude --dangerously-skip-permissions"
end

# FZF setup
if command -q fzf
    fzf --fish | source
    set -gx FZF_DEFAULT_COMMAND "fd --hidden --strip-cwd-prefix --exclude .git"
    set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
    set -gx FZF_ALT_C_COMMAND "fd --type=d --hidden --strip-cwd-prefix --exclude .git"
end

# fnm (Node version manager) - correct fish syntax
if command -q fnm
    fnm env --use-on-cd --shell fish | source
end
