#!/usr/bin/env bash
# Henrik OS - Mac Development Environment Setup
# Usage: curl -fsSL https://raw.githubusercontent.com/henrik392/henrik-os/main/setup.sh | bash
set -euo pipefail

# Wrap everything in a block for pipe safety
{

# ─────────────────────────────────────────────────────────────
# 0. Bootstrap
# ─────────────────────────────────────────────────────────────

START_TIME=$(date +%s)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Logging helpers
info()    { printf "${CYAN}[INFO]${RESET}    %s\n" "$1"; }
success() { printf "${GREEN}[OK]${RESET}      %s\n" "$1"; }
warn()    { printf "${YELLOW}[WARN]${RESET}    %s\n" "$1"; }
error()   { printf "${RED}[ERROR]${RESET}   %s\n" "$1"; }
section() { printf "\n${PURPLE}${BOLD}══════════════════════════════════════════${RESET}\n"; printf "${PURPLE}${BOLD}  %s${RESET}\n" "$1"; printf "${PURPLE}${BOLD}══════════════════════════════════════════${RESET}\n\n"; }

# Section tracking
declare -a SUCCEEDED=()
declare -a WARNED=()
declare -a FAILED=()

run_section() {
  local name="$1"
  local func="$2"
  section "$name"
  if "$func"; then
    SUCCEEDED+=("$name")
  else
    FAILED+=("$name")
    warn "Section '$name' had errors (non-fatal, continuing)"
  fi
}

# Sudo keepalive
sudo -v
while true; do sudo -n true; sleep 60; done 2>/dev/null &
SUDO_PID=$!
trap 'kill $SUDO_PID 2>/dev/null' EXIT

# ─────────────────────────────────────────────────────────────
# 1. ASCII Animation
# ─────────────────────────────────────────────────────────────

show_banner() {
  local lines=(
    "██╗  ██╗███████╗███╗   ██╗██████╗ ██╗██╗  ██╗     ██████╗ ███████╗"
    "██║  ██║██╔════╝████╗  ██║██╔══██╗██║██║ ██╔╝    ██╔═══██╗██╔════╝"
    "███████║█████╗  ██╔██╗ ██║██████╔╝██║█████╔╝     ██║   ██║███████╗"
    "██╔══██║██╔══╝  ██║╚██╗██║██╔══██╗██║██╔═██╗     ██║   ██║╚════██║"
    "██║  ██║███████╗██║ ╚████║██║  ██║██║██║  ██╗    ╚██████╔╝███████║"
    "╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝     ╚═════╝ ╚══════╝"
  )

  printf "\n"
  for line in "${lines[@]}"; do
    printf "${PURPLE}${BOLD}"
    for (( i=0; i<${#line}; i++ )); do
      printf "%s" "${line:$i:1}"
    done
    printf "${RESET}\n"
    sleep 0.05
  done
  printf "\n${DIM}  Setting up your development environment...${RESET}\n\n"
  sleep 0.5
}

show_banner

# ─────────────────────────────────────────────────────────────
# 2. Xcode CLI Tools
# ─────────────────────────────────────────────────────────────

setup_xcode() {
  if xcode-select -p &>/dev/null; then
    success "Xcode CLI tools already installed"
    return 0
  fi

  info "Installing Xcode Command Line Tools..."
  info "Click 'Install' in the dialog that appears"
  xcode-select --install 2>/dev/null || true

  # Poll until installed
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  success "Xcode CLI tools installed"
}

run_section "Xcode CLI Tools" setup_xcode

# ─────────────────────────────────────────────────────────────
# 3. Homebrew + Packages
# ─────────────────────────────────────────────────────────────

setup_homebrew() {
  # Install Homebrew
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    success "Homebrew already installed"
  fi

  # Formulae
  local formulae=(
    fish neovim starship git gh
    eza zoxide fzf fd bat btop
    direnv fnm thefuck yazi tmux
    jq ripgrep imagemagick ffmpeg
    deno bun
  )

  info "Installing formulae..."
  for pkg in "${formulae[@]}"; do
    if brew list "$pkg" &>/dev/null; then
      printf "  ${DIM}%-20s already installed${RESET}\n" "$pkg"
    else
      if brew install "$pkg" 2>/dev/null; then
        printf "  ${GREEN}%-20s installed${RESET}\n" "$pkg"
      else
        printf "  ${YELLOW}%-20s failed (non-fatal)${RESET}\n" "$pkg"
        WARNED+=("brew: $pkg")
      fi
    fi
  done

  # Casks
  local casks=(
    ghostty visual-studio-code raycast alt-tab
    slack discord figma google-chrome zen-browser
    obsidian spotify docker claude
  )

  info "Installing casks..."
  for cask in "${casks[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
      printf "  ${DIM}%-20s already installed${RESET}\n" "$cask"
    else
      if brew install --cask "$cask" 2>/dev/null; then
        printf "  ${GREEN}%-20s installed${RESET}\n" "$cask"
      else
        printf "  ${YELLOW}%-20s failed (non-fatal)${RESET}\n" "$cask"
        WARNED+=("cask: $cask")
      fi
    fi
  done

  # Fonts
  local fonts=(
    font-jetbrains-mono-nerd-font
    font-symbols-only-nerd-font
  )

  info "Installing fonts..."
  for font in "${fonts[@]}"; do
    if brew list --cask "$font" &>/dev/null; then
      printf "  ${DIM}%-20s already installed${RESET}\n" "$font"
    else
      if brew install --cask "$font" 2>/dev/null; then
        printf "  ${GREEN}%-20s installed${RESET}\n" "$font"
      else
        printf "  ${YELLOW}%-20s failed (non-fatal)${RESET}\n" "$font"
        WARNED+=("font: $font")
      fi
    fi
  done
}

run_section "Homebrew + Packages" setup_homebrew

# ─────────────────────────────────────────────────────────────
# 4. SSH Key Generation
# ─────────────────────────────────────────────────────────────

setup_ssh() {
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh

  if [[ -f ~/.ssh/id_ed25519 ]]; then
    success "SSH key already exists"
  else
    info "Generating SSH key..."
    ssh-keygen -t ed25519 -C "henrik.halvorsen.kvamme@gmail.com" -f ~/.ssh/id_ed25519 -N ""
    success "SSH key generated"
  fi

  # Write SSH config
  cat > ~/.ssh/config << 'EOF'
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
EOF
  chmod 600 ~/.ssh/config

  # Add to keychain
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519 2>/dev/null || true
  success "SSH configured"
}

run_section "SSH Key Generation" setup_ssh

# ─────────────────────────────────────────────────────────────
# 5. Fish Shell
# ─────────────────────────────────────────────────────────────

setup_fish() {
  local fish_path
  fish_path="$(which fish 2>/dev/null || echo /opt/homebrew/bin/fish)"

  # Add to /etc/shells
  if ! grep -qF "$fish_path" /etc/shells; then
    info "Adding fish to /etc/shells..."
    echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
  fi

  # Set as default shell
  if [[ "$SHELL" != "$fish_path" ]]; then
    info "Setting fish as default shell..."
    chsh -s "$fish_path"
  fi
  success "Fish is default shell"

  # Remove Oh My Fish conf.d file if present
  rm -f ~/.config/fish/conf.d/omf.fish

  # Remove duplicate aliases function file
  rm -f ~/.config/fish/functions/aliases.fish

  # Write config.fish
  mkdir -p ~/.config/fish
  cat > ~/.config/fish/config.fish << 'FISHEOF'
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
FISHEOF

  # Write fish functions
  mkdir -p ~/.config/fish/functions

  # y.fish - yazi with cd on exit
  cat > ~/.config/fish/functions/y.fish << 'FISHEOF'
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (cat -- "$tmp" 2>/dev/null); and test -n "$cwd"; and test "$cwd" != "$PWD"
        cd -- "$cwd"
    end
    rm -f -- "$tmp"
end
FISHEOF

  # b.fish - bun wrapper
  cat > ~/.config/fish/functions/b.fish << 'FISHEOF'
function b --wraps=bun --description 'alias b=bun'
    bun $argv
end
FISHEOF

  # fuck.fish - thefuck lazy init
  cat > ~/.config/fish/functions/fuck.fish << 'FISHEOF'
function fuck
    if not functions -q __fuck_init
        thefuck --alias | source
        function __fuck_init
        end
    end
    __fuck_alias $argv
end
FISHEOF

  # FZF completions
  cat > ~/.config/fish/functions/_fzf_compgen_path.fish << 'FISHEOF'
function _fzf_compgen_path
    fd --hidden --exclude .git . $argv[1]
end
FISHEOF

  cat > ~/.config/fish/functions/_fzf_compgen_dir.fish << 'FISHEOF'
function _fzf_compgen_dir
    fd --type=d --hidden --exclude .git . $argv[1]
end
FISHEOF

  success "Fish shell configured"
}

run_section "Fish Shell" setup_fish

# ─────────────────────────────────────────────────────────────
# 6. Ghostty Config
# ─────────────────────────────────────────────────────────────

setup_ghostty() {
  mkdir -p ~/.config/ghostty
  cat > ~/.config/ghostty/config << 'EOF'
theme = Aura

keybind = shift+enter=text:\x1b\r
EOF
  success "Ghostty configured"
}

run_section "Ghostty" setup_ghostty

# ─────────────────────────────────────────────────────────────
# 7. Starship Prompt
# ─────────────────────────────────────────────────────────────

setup_starship() {
  mkdir -p ~/.config
  cat > ~/.config/starship.toml << 'EOF'
# starship.toml

add_newline = false
palette = "default"

format = """
[╭](fg:separator)\
$status\
$directory\
$cmd_duration\
$line_break\
[╰](fg:separator)\
$character\
"""

###########################################

[palettes.default]
prompt_ok  = "#8047c1"
prompt_err = "#e23140"
icon       = "#161514"
separator  = "#35312c"
background = "#35312c"

directory  = "#9f31e2"
duration   = "#e26f31"
status     = "#e23140"

###########################################

[character]
success_symbol = "[❯](fg:prompt_ok)"
error_symbol = "[❯](fg:prompt_err)"

[directory]
format = "[─](fg:separator)[](fg:directory)[](fg:icon bg:directory)[](fg:directory bg:background)[ $path](bg:background)[](fg:background)"
truncate_to_repo = false
truncation_length = 0

[status]
format = "[─](fg:separator)[](fg:status)[](fg:icon bg:status)[](fg:status bg:background)[ $status](bg:background)[](fg:background)"
pipestatus = true
pipestatus_separator = "-"
pipestatus_segment_format = "$status"
pipestatus_format = "[─](fg:separator)[](fg:status)[](fg:icon bg:status)[](fg:status bg:background)[ $pipestatus](bg:background)[](fg:background)"
disabled = false

[cmd_duration]
format = "[─](fg:separator)[](fg:duration)[󱐋](fg:icon bg:duration)[](fg:duration bg:background)[ $duration](bg:background)[](fg:background)"
min_time = 1000

[time]
format = "[](fg:duration)[󰥔](fg:icon bg:duration)[](fg:duration bg:background)[ $time](bg:background)[](fg:background)"
disabled = false
EOF
  success "Starship configured"
}

run_section "Starship Prompt" setup_starship

# ─────────────────────────────────────────────────────────────
# 8. Neovim + LazyVim
# ─────────────────────────────────────────────────────────────

setup_neovim() {
  local nvim_dir="$HOME/.config/nvim"

  # Back up existing config
  if [[ -d "$nvim_dir" ]] && [[ ! -d "${nvim_dir}.bak" ]]; then
    info "Backing up existing Neovim config..."
    cp -r "$nvim_dir" "${nvim_dir}.bak"
  fi

  mkdir -p "$nvim_dir/lua/config"
  mkdir -p "$nvim_dir/lua/plugins"

  # init.lua
  cat > "$nvim_dir/init.lua" << 'EOF'
-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
EOF

  # lazy.lua
  cat > "$nvim_dir/lua/config/lazy.lua" << 'EOF'
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.rust" },
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true,
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
EOF

  # options.lua
  cat > "$nvim_dir/lua/config/options.lua" << 'EOF'
-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
EOF

  # keymaps.lua
  cat > "$nvim_dir/lua/config/keymaps.lua" << 'EOF'
-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
EOF

  # autocmds.lua
  cat > "$nvim_dir/lua/config/autocmds.lua" << 'EOF'
-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
EOF

  # plugins/init.lua
  cat > "$nvim_dir/lua/plugins/init.lua" << 'EOF'
return {}
EOF

  # stylua.toml
  cat > "$nvim_dir/stylua.toml" << 'EOF'
indent_type = "Spaces"
indent_width = 2
column_width = 120
EOF

  # .neoconf.json
  cat > "$nvim_dir/.neoconf.json" << 'EOF'
{
  "neodev": {
    "library": {
      "enabled": true,
      "plugins": true
    }
  },
  "neoconf": {
    "plugins": {
      "lua_ls": {
        "enabled": true
      }
    }
  }
}
EOF

  success "Neovim + LazyVim configured"
}

run_section "Neovim + LazyVim" setup_neovim

# ─────────────────────────────────────────────────────────────
# 9. Git Config
# ─────────────────────────────────────────────────────────────

setup_git() {
  cat > ~/.gitconfig << 'EOF'
[core]
	excludesFile = ~/.gitignore_global
	autocrlf = input
[user]
	email = henrik.halvorsen.kvamme@gmail.com
	name = Henrik Kvamme
[rerere]
	enabled = true
[column]
	ui = auto
[branch]
	sort = -committerdate
EOF

  cat > ~/.gitignore_global << 'EOF'
# Direnv files
.direnv
.envrc

# Editor specific files and folders
.idea
.vscode

# macOS
.DS_Store
EOF

  success "Git configured"
}

run_section "Git Config" setup_git

# ─────────────────────────────────────────────────────────────
# 10. Node.js + Package Managers
# ─────────────────────────────────────────────────────────────

setup_node() {
  # Ensure fnm is available in this bash session
  eval "$(fnm env)"

  if fnm list | grep -q "lts-latest" 2>/dev/null; then
    success "Node LTS already installed"
  else
    info "Installing Node.js LTS via fnm..."
    fnm install --lts
    fnm default lts-latest
    success "Node.js LTS installed"
  fi

  # Enable corepack (activates pnpm + yarn)
  info "Enabling corepack..."
  corepack enable 2>/dev/null || true
  success "corepack enabled (pnpm + yarn available)"

  info "Bun + Deno already installed via Homebrew"
}

run_section "Node.js + Package Managers" setup_node

# ─────────────────────────────────────────────────────────────
# 11. VS Code
# ─────────────────────────────────────────────────────────────

setup_vscode() {
  # Symlink code CLI if not in PATH
  if ! command -v code &>/dev/null; then
    local code_cli="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    if [[ -f "$code_cli" ]]; then
      sudo ln -sf "$code_cli" /usr/local/bin/code
      info "Symlinked VS Code CLI"
    else
      warn "VS Code not found - skipping CLI setup"
      return 0
    fi
  fi

  # Extensions
  local extensions=(
    daltonmenezes.aura-theme
    esbenp.prettier-vscode
    dbaeumer.vscode-eslint
    eamodio.gitlens
    github.copilot
    github.copilot-chat
    bradlc.vscode-tailwindcss
    christian-kohler.path-intellisense
    anthropic.claude-code
    asvetliakov.vscode-neovim
    VSpaceCode.whichkey
    catppuccin.catppuccin-vsc-icons
  )

  info "Installing VS Code extensions..."
  for ext in "${extensions[@]}"; do
    if code --list-extensions 2>/dev/null | grep -qi "$ext"; then
      printf "  ${DIM}%-45s already installed${RESET}\n" "$ext"
    else
      if code --install-extension "$ext" --force 2>/dev/null; then
        printf "  ${GREEN}%-45s installed${RESET}\n" "$ext"
      else
        printf "  ${YELLOW}%-45s failed (non-fatal)${RESET}\n" "$ext"
      fi
    fi
  done

  # settings.json
  local settings_dir="$HOME/Library/Application Support/Code/User"
  mkdir -p "$settings_dir"
  cat > "$settings_dir/settings.json" << 'JSONEOF'
{
  "workbench.settings.editor": "json",

  // Editor
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true,
  "editor.formatOnSaveMode": "file",
  "editor.lineNumbers": "relative",
  "editor.suggestSelection": "first",
  "editor.snippetSuggestions": "top",
  "editor.inlineSuggest.enabled": true,
  "editor.fontLigatures": true,
  "editor.fontSize": 14,
  "editor.minimap.enabled": false,
  "editor.scrollbar.vertical": "auto",
  "editor.scrollbar.horizontal": "auto",
  "editor.tabSize": 2,
  "editor.linkedEditing": true,
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": true,
  "editor.cursorSurroundingLines": 8,
  "editor.tabCompletion": "on",
  "editor.inlineSuggest.edits.showCollapsed": true,

  // Font
  "editor.fontFamily": "Geist Mono",
  "scm.inputFontFamily": "Geist Mono",
  "terminal.integrated.fontFamily": "JetBrainsMono Nerd Font",
  "chat.editor.fontFamily": "Geist Mono",
  "debug.console.fontFamily": "Geist Mono",
  "editor.codeLensFontFamily": "Geist Mono",
  "notebook.output.fontFamily": "Geist Mono",
  "markdown.preview.fontFamily": "Geist Mono",
  "editor.inlayHints.fontFamily": "Geist Mono",
  "terminal.integrated.fontSize": 14,

  // UI
  "window.commandCenter": false,
  "window.titleBarStyle": "custom",
  "window.zoomLevel": 0.3,
  "workbench.statusBar.visible": true,
  "workbench.layoutControl.enabled": false,
  "workbench.activityBar.location": "bottom",
  "workbench.startupEditor": "none",
  "breadcrumbs.enabled": false,
  "breadcrumbs.filePath": "off",
  "explorer.compactFolders": false,
  "explorer.confirmDragAndDrop": false,
  "files.trimTrailingWhitespace": true,
  "files.autoSave": "afterDelay",

  // Theme
  "workbench.colorTheme": "Aura Dark",
  "workbench.iconTheme": "catppuccin-macchiato",
  "workbench.colorCustomizations": {
    "[Aura Dark]": {
      "editor.background": "#110f17",
      "terminal.background": "#110f17",
      "activityBar.background": "#110f17",
      "statusBar.background": "#110f17",
      "editorGroupHeader.tabsBackground": "#110f17",
      "tab.inactiveBackground": "#110f17"
    }
  },

  // Terminal
  "terminal.explorerKind": "external",

  // Language overrides
  "[markdown]": {
    "files.trimTrailingWhitespace": false
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.tabSize": 2,
    "editor.insertSpaces": true
  },
  "[typescriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.tabSize": 2,
    "editor.insertSpaces": true
  },
  "[json]": {
    "editor.defaultFormatter": "vscode.json-language-features"
  },

  // Git
  "git.autofetch": true,
  "git.confirmSync": false,
  "git.ignoreRebaseWarning": true,
  "git.openRepositoryInParentFolders": "always",

  // Copilot
  "github.copilot.enable": { "*": true },
  "github.copilot.nextEditSuggestions.enabled": true,
  "github.copilot.chat.completionContext.typescript.mode": "on",
  "github.copilot.chat.editor.temporalContext.enabled": true,
  "github.copilot.chat.agent.thinkingTool": true,
  "github.copilot.chat.codesearch.enabled": true,
  "chat.agent.enabled": true,

  // Neovim
  "vscode-neovim.neovimExecutablePaths.darwin": "/opt/homebrew/bin/nvim",
  "vscode-neovim.neovimInitVimPaths.darwin": "$HOME/.config/nvim-vscode/init.vim",
  "extensions.experimental.affinity": {
    "asvetliakov.vscode-neovim": 1
  },

  // WhichKey
  "whichkey.sortOrder": "alphabetically",
  "whichkey.delay": 0,
  "whichkey.bindings": [
    {
      "key": "w",
      "name": "Save file",
      "type": "command",
      "command": "workbench.action.files.save"
    },
    {
      "key": "q",
      "name": "Close file",
      "type": "command",
      "command": "workbench.action.closeActiveEditor"
    },
    {
      "key": ";",
      "name": "commands",
      "type": "command",
      "command": "workbench.action.showCommands"
    },
    {
      "key": "/",
      "name": "comment",
      "type": "command",
      "command": "vscode-neovim.send",
      "args": "<C-/>"
    },
    {
      "key": "?",
      "name": "View All References",
      "type": "command",
      "command": "references-view.find",
      "when": "editorHasReferenceProvider"
    },
    {
      "key": "b",
      "name": "Buffers/Editors...",
      "type": "bindings",
      "bindings": [
        { "key": "b", "name": "Show all buffers/editors", "type": "command", "command": "workbench.action.showAllEditors" },
        { "key": "d", "name": "Close active editor", "type": "command", "command": "workbench.action.closeActiveEditor" },
        { "key": "h", "name": "Move editor into left group", "type": "command", "command": "workbench.action.moveEditorToLeftGroup" },
        { "key": "j", "name": "Move editor into below group", "type": "command", "command": "workbench.action.moveEditorToBelowGroup" },
        { "key": "k", "name": "Move editor into above group", "type": "command", "command": "workbench.action.moveEditorToAboveGroup" },
        { "key": "l", "name": "Move editor into right group", "type": "command", "command": "workbench.action.moveEditorToRightGroup" },
        { "key": "m", "name": "Close other editors", "type": "command", "command": "workbench.action.closeOtherEditors" },
        { "key": "n", "name": "Next editor", "type": "command", "command": "workbench.action.nextEditor" },
        { "key": "p", "name": "Previous editor", "type": "command", "command": "workbench.action.previousEditor" },
        { "key": "N", "name": "New untitled editor", "type": "command", "command": "workbench.action.files.newUntitledFile" },
        { "key": "u", "name": "Reopen closed editor", "type": "command", "command": "workbench.action.reopenClosedEditor" },
        { "key": "y", "name": "Copy buffer to clipboard", "type": "commands", "commands": ["editor.action.selectAll", "editor.action.clipboardCopyAction", "cancelSelection"] }
      ]
    },
    {
      "key": "d",
      "name": "Debug...",
      "type": "bindings",
      "bindings": [
        { "key": "d", "name": "Start debug", "type": "command", "command": "workbench.action.debug.start" },
        { "key": "S", "name": "Stop debug", "type": "command", "command": "workbench.action.debug.stop" },
        { "key": "c", "name": "Continue debug", "type": "command", "command": "workbench.action.debug.continue" },
        { "key": "p", "name": "Pause debug", "type": "command", "command": "workbench.action.debug.pause" },
        { "key": "r", "name": "Run without debugging", "type": "command", "command": "workbench.action.debug.run" },
        { "key": "R", "name": "Restart debug", "type": "command", "command": "workbench.action.debug.restart" },
        { "key": "i", "name": "Step into", "type": "command", "command": "workbench.action.debug.stepInto" },
        { "key": "s", "name": "Step over", "type": "command", "command": "workbench.action.debug.stepOver" },
        { "key": "o", "name": "Step out", "type": "command", "command": "workbench.action.debug.stepOut" },
        { "key": "b", "name": "Toggle breakpoint", "type": "command", "command": "editor.debug.action.toggleBreakpoint" },
        { "key": "B", "name": "Toggle inline breakpoint", "type": "command", "command": "editor.debug.action.toggleInlineBreakpoint" },
        { "key": "j", "name": "Jump to cursor", "type": "command", "command": "debug.jumpToCursor" },
        { "key": "v", "name": "REPL", "type": "command", "command": "workbench.debug.action.toggleRepl" },
        { "key": "w", "name": "Focus on watch window", "type": "command", "command": "workbench.debug.action.focusWatchView" },
        { "key": "W", "name": "Add to watch", "type": "command", "command": "editor.debug.action.selectionToWatch" }
      ]
    },
    {
      "key": "e",
      "name": "Toggle Explorer",
      "type": "command",
      "command": "workbench.action.toggleSidebarVisibility"
    },
    {
      "key": "f",
      "name": "Find & Replace...",
      "type": "bindings",
      "bindings": [
        { "key": "f", "name": "File", "type": "command", "command": "editor.action.startFindReplaceAction" },
        { "key": "s", "name": "Symbol", "type": "command", "command": "editor.action.rename", "when": "editorHasRenameProvider && editorTextFocus && !editorReadonly" },
        { "key": "p", "name": "Project", "type": "command", "command": "workbench.action.replaceInFiles" }
      ]
    },
    {
      "key": "g",
      "name": "Git...",
      "type": "bindings",
      "bindings": [
        { "key": "/", "name": "Search Commits", "command": "gitlens.showCommitSearch", "type": "command", "when": "gitlens:enabled && config.gitlens.keymap == 'alternate'" },
        { "key": "a", "name": "Stage", "type": "command", "command": "git.stage" },
        { "key": "b", "name": "Checkout", "type": "command", "command": "git.checkout" },
        { "key": "B", "name": "Browse", "type": "command", "command": "gitlens.openFileInRemote" },
        { "key": "c", "name": "Commit", "type": "command", "command": "git.commit" },
        { "key": "C", "name": "Cherry Pick", "type": "command", "command": "gitlens.views.cherryPick" },
        { "key": "d", "name": "Delete Branch", "type": "command", "command": "git.deleteBranch" },
        { "key": "f", "name": "Fetch", "type": "command", "command": "git.fetch" },
        { "key": "F", "name": "Pull From", "type": "command", "command": "git.pullFrom" },
        { "key": "g", "name": "Graph", "type": "command", "command": "git-graph.view" },
        { "key": "h", "name": "Heatmap", "type": "command", "command": "gitlens.toggleFileHeatmap" },
        { "key": "H", "name": "History", "type": "command", "command": "git.viewFileHistory" },
        { "key": "i", "name": "Init", "type": "command", "command": "git.init" },
        { "key": "j", "name": "Next Change", "type": "command", "command": "workbench.action.editor.nextChange" },
        { "key": "k", "name": "Previous Change", "type": "command", "command": "workbench.action.editor.previousChange" },
        { "key": "l", "name": "Toggle Line Blame", "type": "command", "command": "gitlens.toggleLineBlame", "when": "editorTextFocus && gitlens:canToggleCodeLens && gitlens:enabled && config.gitlens.keymap == 'alternate'" },
        { "key": "L", "name": "Toggle GitLens", "type": "command", "command": "gitlens.toggleCodeLens", "when": "editorTextFocus && gitlens:canToggleCodeLens && gitlens:enabled && config.gitlens.keymap == 'alternate'" },
        { "key": "m", "name": "Merge", "type": "command", "command": "git.merge" },
        { "key": "p", "name": "Push", "type": "command", "command": "git.push" },
        { "key": "P", "name": "Pull", "type": "command", "command": "git.pull" },
        { "key": "s", "name": "Stash", "type": "command", "command": "workbench.view.scm" },
        { "key": "S", "name": "Status", "type": "command", "command": "gitlens.showQuickRepoStatus", "when": "gitlens:enabled && config.gitlens.keymap == 'alternate'" },
        { "key": "t", "name": "Create Tag", "type": "command", "command": "git.createTag" },
        { "key": "T", "name": "Delete Tag", "type": "command", "command": "git.deleteTag" },
        { "key": "U", "name": "Unstage", "type": "command", "command": "git.unstage" }
      ]
    },
    { "key": "h", "name": "Split Horizontal", "type": "command", "command": "workbench.action.splitEditorDown" },
    {
      "key": "i",
      "name": "Insert...",
      "type": "bindings",
      "bindings": [
        { "key": "j", "name": "Insert line below", "type": "command", "command": "editor.action.insertLineAfter" },
        { "key": "k", "name": "Insert line above", "type": "command", "command": "editor.action.insertLineBefore" },
        { "key": "s", "name": "Insert snippet", "type": "command", "command": "editor.action.insertSnippet" }
      ]
    },
    {
      "key": "l",
      "name": "LSP...",
      "type": "bindings",
      "bindings": [
        { "key": ";", "name": "Refactor", "type": "command", "command": "editor.action.refactor", "when": "editorHasCodeActionsProvider && editorTextFocus && !editorReadonly" },
        { "key": "a", "name": "Auto Fix", "type": "command", "command": "editor.action.autoFix", "when": "editorTextFocus && !editorReadonly && supportedCodeAction =~ /(\\s|^)quickfix\\b/" },
        { "key": "d", "name": "Definition", "type": "command", "command": "editor.action.revealDefinition", "when": "editorHasDefinitionProvider && editorTextFocus && !isInEmbeddedEditor" },
        { "key": "D", "name": "Declaration", "type": "command", "command": "editor.action.revealDeclaration" },
        { "key": "e", "name": "Errors", "type": "command", "command": "workbench.actions.view.problems" },
        { "key": "f", "name": "Format", "type": "command", "command": "editor.action.formatDocument", "when": "editorHasDocumentFormattingProvider && editorTextFocus && !editorReadonly && !inCompositeEditor" },
        { "key": "i", "name": "Implementation", "type": "command", "command": "editor.action.goToImplementation", "when": "editorHasImplementationProvider && editorTextFocus && !isInEmbeddedEditor" },
        { "key": "l", "name": "Code Lens", "type": "command", "command": "codelens.showLensesInCurrentLine" },
        { "key": "n", "name": "Next Problem", "type": "command", "command": "editor.action.marker.next", "when": "editorFocus" },
        { "key": "N", "name": "Next Problem (Proj)", "type": "command", "command": "editor.action.marker.nextInFiles", "when": "editorFocus" },
        { "key": "o", "name": "Outline", "type": "command", "command": "outline.focus" },
        { "key": "p", "name": "Prev Problem", "type": "command", "command": "editor.action.marker.prevInFiles", "when": "editorFocus" },
        { "key": "P", "name": "Prev Problem (Proj)", "type": "command", "command": "editor.action.marker.prev", "when": "editorFocus" },
        { "key": "q", "name": "Quick Fix", "type": "command", "command": "editor.action.quickFix", "when": "editorHasCodeActionsProvider && editorTextFocus && !editorReadonly" },
        { "key": "r", "name": "References", "type": "command", "command": "editor.action.goToReferences", "when": "editorHasReferenceProvider && editorTextFocus && !inReferenceSearchEditor && !isInEmbeddedEditor" },
        { "key": "R", "name": "Rename", "type": "command", "command": "editor.action.rename", "when": "editorHasRenameProvider && editorTextFocus && !editorReadonly" },
        { "key": "v", "name": "View All References", "type": "command", "command": "references-view.find", "when": "editorHasReferenceProvider" },
        { "key": "s", "name": "Go To Symbol", "type": "command", "command": "workbench.action.gotoSymbol" },
        { "key": "S", "name": "Show All Symbols", "type": "command", "command": "workbench.action.showAllSymbols" }
      ]
    },
    {
      "key": "m",
      "name": "Mark...",
      "type": "bindings",
      "bindings": [
        { "key": "c", "name": "Clear Bookmarks", "type": "command", "command": "bookmarks.clear" },
        { "key": "j", "name": "Next Bookmark", "type": "command", "command": "bookmarks.jumpToNext", "when": "editorTextFocus" },
        { "key": "k", "name": "Previous Bookmark", "type": "command", "command": "bookmarks.jumpToPrevious", "when": "editorTextFocus" },
        { "key": "l", "name": "List Bookmarks", "type": "command", "command": "bookmarks.listFromAllFiles", "when": "editorTextFocus" },
        { "key": "r", "name": "Refresh Bookmarks", "type": "command", "command": "bookmarks.refresh" },
        { "key": "t", "name": "Toggle Bookmark", "type": "command", "command": "bookmarks.toggle", "when": "editorTextFocus" },
        { "key": "s", "name": "Show Bookmarks", "type": "command", "command": "workbench.view.extension.bookmarks" }
      ]
    },
    { "key": "M", "name": "Minimap", "type": "command", "command": "editor.action.toggleMinimap" },
    { "key": "n", "name": "No Highlight", "type": "command", "command": "vscode-neovim.send", "args": ":noh<CR>" },
    {
      "key": "o",
      "name": "Open...",
      "type": "bindings",
      "bindings": [
        { "key": "d", "name": "Directory", "type": "command", "command": "workbench.action.files.openFolder" },
        { "key": "r", "name": "Recent", "type": "command", "command": "workbench.action.openRecent" },
        { "key": "f", "name": "File", "type": "command", "command": "workbench.action.files.openFile" }
      ]
    },
    {
      "key": "p",
      "name": "Peek...",
      "type": "bindings",
      "bindings": [
        { "key": "d", "name": "Definition", "type": "command", "command": "editor.action.peekDefinition", "when": "editorHasDefinitionProvider && editorTextFocus && !inReferenceSearchEditor && !isInEmbeddedEditor" },
        { "key": "D", "name": "Declaration", "type": "command", "command": "editor.action.peekDeclaration" },
        { "key": "i", "name": "Implementation", "type": "command", "command": "editor.action.peekImplementation", "when": "editorHasImplementationProvider && editorTextFocus && !inReferenceSearchEditor && !isInEmbeddedEditor" },
        { "key": "p", "name": "Toggle Focus", "type": "command", "command": "togglePeekWidgetFocus", "when": "inReferenceSearchEditor || referenceSearchVisible" },
        { "key": "r", "name": "References", "type": "command", "command": "editor.action.referenceSearch.trigger" },
        { "key": "t", "name": "Type Definition", "type": "command", "command": "editor.action.peekTypeDefinition" }
      ]
    },
    {
      "key": "s",
      "name": "Search...",
      "type": "bindings",
      "bindings": [
        { "key": "f", "name": "Files", "type": "command", "command": "workbench.action.quickOpen" },
        { "key": "t", "name": "Text", "type": "command", "command": "workbench.action.findInFiles" }
      ]
    },
    {
      "key": "S",
      "name": "Show...",
      "type": "bindings",
      "bindings": [
        { "key": "e", "name": "Show explorer", "type": "command", "command": "workbench.view.explorer" },
        { "key": "s", "name": "Show search", "type": "command", "command": "workbench.view.search" },
        { "key": "g", "name": "Show source control", "type": "command", "command": "workbench.view.scm" },
        { "key": "t", "name": "Show test", "type": "command", "command": "workbench.view.extension.test" },
        { "key": "r", "name": "Show remote explorer", "type": "command", "command": "workbench.view.remote" },
        { "key": "x", "name": "Show extensions", "type": "command", "command": "workbench.view.extensions" },
        { "key": "p", "name": "Show problem", "type": "command", "command": "workbench.actions.view.problems" },
        { "key": "o", "name": "Show output", "type": "command", "command": "workbench.action.output.toggleOutput" },
        { "key": "d", "name": "Show debug console", "type": "command", "command": "workbench.debug.action.toggleRepl" }
      ]
    },
    {
      "key": "t",
      "name": "Terminal...",
      "type": "bindings",
      "bindings": [
        { "key": "t", "name": "Toggle Terminal", "type": "command", "command": "workbench.action.togglePanel" },
        { "key": "T", "name": "Focus Terminal", "type": "command", "command": "workbench.action.terminal.toggleTerminal", "when": "!terminalFocus" }
      ]
    },
    {
      "key": "u",
      "name": "UI toggles...",
      "type": "bindings",
      "bindings": [
        { "key": "a", "name": "Toggle tool/activity bar visibility", "type": "command", "command": "workbench.action.toggleActivityBarVisibility" },
        { "key": "b", "name": "Toggle side bar visibility", "type": "command", "command": "workbench.action.toggleSidebarVisibility" },
        { "key": "j", "name": "Toggle panel visibility", "type": "command", "command": "workbench.action.togglePanel" },
        { "key": "F", "name": "Toggle full screen", "type": "command", "command": "workbench.action.toggleFullScreen" },
        { "key": "s", "name": "Select theme", "type": "command", "command": "workbench.action.selectTheme" },
        { "key": "m", "name": "Toggle maximized panel", "type": "command", "command": "workbench.action.toggleMaximizedPanel" },
        { "key": "T", "name": "Toggle tab visibility", "type": "command", "command": "workbench.action.toggleTabsVisibility" }
      ]
    },
    { "key": "v", "name": "Split Vertical", "type": "command", "command": "workbench.action.splitEditor" },
    {
      "key": "w",
      "name": "Window...",
      "type": "bindings",
      "bindings": [
        { "key": "W", "name": "Focus previous editor group", "type": "command", "command": "workbench.action.focusPreviousGroup" },
        { "key": "h", "name": "Move editor group left", "type": "command", "command": "workbench.action.moveActiveEditorGroupLeft" },
        { "key": "j", "name": "Move editor group down", "type": "command", "command": "workbench.action.moveActiveEditorGroupDown" },
        { "key": "k", "name": "Move editor group up", "type": "command", "command": "workbench.action.moveActiveEditorGroupUp" },
        { "key": "l", "name": "Move editor group right", "type": "command", "command": "workbench.action.moveActiveEditorGroupRight" },
        { "key": "t", "name": "Toggle editor group sizes", "type": "command", "command": "workbench.action.toggleEditorWidths" },
        { "key": "m", "name": "Maximize editor group", "type": "command", "command": "workbench.action.minimizeOtherEditors" },
        { "key": "M", "name": "Maximize editor group and hide side bar", "type": "command", "command": "workbench.action.maximizeEditor" },
        { "key": "=", "name": "Reset editor group sizes", "type": "command", "command": "workbench.action.evenEditorWidths" },
        { "key": "z", "name": "Combine all editors", "type": "command", "command": "workbench.action.joinAllGroups" },
        { "key": "d", "name": "Close editor group", "type": "command", "command": "workbench.action.closeEditorsInGroup" },
        { "key": "x", "name": "Close all editor groups", "type": "command", "command": "workbench.action.closeAllGroups" }
      ]
    },
    { "key": "x", "name": "Extensions", "type": "command", "command": "workbench.view.extensions" },
    { "key": "z", "name": "Toggle zen mode", "type": "command", "command": "workbench.action.toggleZenMode" }
  ]
}
JSONEOF

  # Write nvim-vscode init.vim
  mkdir -p ~/.config/nvim-vscode
  cat > ~/.config/nvim-vscode/init.vim << 'VIMEOF'
function! s:manageEditorSize(...)
    let count = a:1
    let to = a:2
    for i in range(1, count ? count : 1)
        call VSCodeNotify(to == 'increase' ? 'workbench.action.increaseViewSize' : 'workbench.action.decreaseViewSize')
    endfor
endfunction

function! s:vscodeCommentary(...) abort
    if !a:0
        let &operatorfunc = matchstr(expand('<sfile>'), '[^. ]*$')
        return 'g@'
    elseif a:0 > 1
        let [line1, line2] = [a:1, a:2]
    else
        let [line1, line2] = [line("'["), line("']")]
    endif

    call VSCodeCallRange("editor.action.commentLine", line1, line2, 0)
endfunction

function! s:openVSCodeCommandsInVisualMode()
    normal! gv
    let visualmode = visualmode()
    if visualmode == "V"
        let startLine = line("v")
        let endLine = line(".")
        call VSCodeNotifyRange("workbench.action.showCommands", startLine, endLine, 1)
    else
        let startPos = getpos("v")
        let endPos = getpos(".")
        call VSCodeNotifyRangePos("workbench.action.showCommands", startPos[1], endPos[1], startPos[2], endPos[2], 1)
    endif
endfunction

function! s:openWhichKeyInVisualMode()
    normal! gv
    let visualmode = visualmode()
    if visualmode == "V"
        let startLine = line("v")
        let endLine = line(".")
        call VSCodeNotifyRange("whichkey.show", startLine, endLine, 1)
    else
        let startPos = getpos("v")
        let endPos = getpos(".")
        call VSCodeNotifyRangePos("whichkey.show", startPos[1], endPos[1], startPos[2], endPos[2], 1)
    endif
endfunction

" Better Navigation
nnoremap <silent> <C-j> :call VSCodeNotify('workbench.action.navigateDown')<CR>
xnoremap <silent> <C-j> :call VSCodeNotify('workbench.action.navigateDown')<CR>
nnoremap <silent> <C-k> :call VSCodeNotify('workbench.action.navigateUp')<CR>
xnoremap <silent> <C-k> :call VSCodeNotify('workbench.action.navigateUp')<CR>
nnoremap <silent> <C-h> :call VSCodeNotify('workbench.action.navigateLeft')<CR>
xnoremap <silent> <C-h> :call VSCodeNotify('workbench.action.navigateLeft')<CR>
nnoremap <silent> <C-l> :call VSCodeNotify('workbench.action.navigateRight')<CR>
xnoremap <silent> <C-l> :call VSCodeNotify('workbench.action.navigateRight')<CR>

nnoremap gr <Cmd>call VSCodeNotify('editor.action.goToReferences')<CR>

" Bind C-/ to vscode commentary since calling from vscode produces double comments due to multiple cursors
xnoremap <expr> <C-/> <SID>vscodeCommentary()
nnoremap <expr> <C-/> <SID>vscodeCommentary() . '_'

nnoremap <silent> <C-w>_ :<C-u>call VSCodeNotify('workbench.action.toggleEditorWidths')<CR>

nnoremap <silent> <Space> :call VSCodeNotify('whichkey.show')<CR>
xnoremap <silent> <Space> :<C-u>call <SID>openWhichKeyInVisualMode()<CR>

xnoremap <silent> <C-P> :<C-u>call <SID>openVSCodeCommandsInVisualMode()<CR>

xmap gc  <Plug>VSCodeCommentary
nmap gc  <Plug>VSCodeCommentary
omap gc  <Plug>VSCodeCommentary
nmap gcc <Plug>VSCodeCommentaryLine

" Simulate same TAB behavior in VSCode
nmap <Tab> :Tabnext<CR>
nmap <S-Tab> :Tabprev<CR>
VIMEOF

  success "VS Code configured"
}

run_section "VS Code" setup_vscode

# ─────────────────────────────────────────────────────────────
# 12. Claude Code
# ─────────────────────────────────────────────────────────────

setup_claude_code() {
  # Need node in PATH for npm
  eval "$(fnm env)"

  if command -v claude &>/dev/null; then
    success "Claude Code already installed"
  else
    info "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
    success "Claude Code installed"
  fi
}

run_section "Claude Code" setup_claude_code

# ─────────────────────────────────────────────────────────────
# 13. macOS Defaults
# ─────────────────────────────────────────────────────────────

setup_macos() {
  info "Configuring macOS defaults..."

  # Keyboard
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

  # Caps Lock → Escape via hidutil
  info "Mapping Caps Lock to Escape..."
  hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}' >/dev/null

  # Persist across reboots with LaunchAgent
  local plist_dir="$HOME/Library/LaunchAgents"
  local plist_file="$plist_dir/com.henrikkvamme.capslock-escape.plist"
  mkdir -p "$plist_dir"
  cat > "$plist_file" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.henrikkvamme.capslock-escape</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/hidutil</string>
        <string>property</string>
        <string>--set</string>
        <string>{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

  # Touch ID for sudo
  local sudo_tid="/etc/pam.d/sudo_local"
  if [[ ! -f "$sudo_tid" ]] || ! grep -q "pam_tid.so" "$sudo_tid" 2>/dev/null; then
    info "Enabling Touch ID for sudo..."
    sudo bash -c 'cat > /etc/pam.d/sudo_local << PAMEOF
auth       sufficient     pam_tid.so
PAMEOF'
    success "Touch ID for sudo enabled"
  else
    success "Touch ID for sudo already enabled"
  fi

  # Finder
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true

  # Dock
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock tilesize -int 48

  # Screenshots to ~/Downloads
  defaults write com.apple.screencapture location -string "$HOME/Downloads"

  # No .DS_Store on network/USB volumes
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

  # Restart affected apps
  killall Finder 2>/dev/null || true
  killall Dock 2>/dev/null || true

  success "macOS defaults configured"
}

run_section "macOS Defaults" setup_macos

# ─────────────────────────────────────────────────────────────
# 14. Post-install Instructions
# ─────────────────────────────────────────────────────────────

printf "\n"
section "Manual Steps"

printf "${BOLD}Run these commands:${RESET}\n\n"
printf "  ${CYAN}1.${RESET} gh auth login\n"
printf "     ${DIM}Authenticate GitHub CLI (choose SSH protocol)${RESET}\n\n"
printf "  ${CYAN}2.${RESET} gh ssh-key add ~/.ssh/id_ed25519.pub -t \"Mac\"\n"
printf "     ${DIM}Add SSH key to your GitHub account${RESET}\n\n"
printf "  ${CYAN}3.${RESET} Open a new terminal to start using Fish shell\n\n"
printf "  ${CYAN}4.${RESET} nvim\n"
printf "     ${DIM}Open Neovim once to install LazyVim plugins${RESET}\n\n"

section "Secrets & Auth to Set Up"

printf "  ${YELLOW}GitHub CLI${RESET}        gh auth login (SSH protocol recommended)\n"
printf "  ${YELLOW}Anthropic API${RESET}     set -Ux ANTHROPIC_API_KEY \"sk-...\"\n"
printf "  ${YELLOW}GitHub Copilot${RESET}    Open VS Code -> sign in to Copilot\n"
printf "  ${YELLOW}Docker${RESET}            Open Docker Desktop -> sign in\n"
printf "  ${YELLOW}Raycast${RESET}           Open Raycast -> set as Spotlight replacement\n"
printf "                    ${DIM}(disable Spotlight: System Settings -> Keyboard -> Shortcuts)${RESET}\n"
printf "  ${YELLOW}Slack/Discord${RESET}     Sign in to each app\n"
printf "  ${YELLOW}Figma${RESET}             Sign in\n"
printf "  ${YELLOW}Claude Desktop${RESET}    Open Claude app -> sign in\n"
printf "  ${YELLOW}Git signing${RESET}       ${DIM}(optional)${RESET} git config --global commit.gpgsign true\n"

# ─────────────────────────────────────────────────────────────
# 15. Summary
# ─────────────────────────────────────────────────────────────

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
MINUTES=$(( ELAPSED / 60 ))
SECONDS_LEFT=$(( ELAPSED % 60 ))

printf "\n"
section "Summary"

if [[ ${#SUCCEEDED[@]} -gt 0 ]]; then
  for s in "${SUCCEEDED[@]}"; do
    printf "  ${GREEN}✓${RESET} %s\n" "$s"
  done
fi

if [[ ${#WARNED[@]} -gt 0 ]]; then
  printf "\n"
  for w in "${WARNED[@]}"; do
    printf "  ${YELLOW}⚠${RESET} %s\n" "$w"
  done
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
  printf "\n"
  for f in "${FAILED[@]}"; do
    printf "  ${RED}✗${RESET} %s\n" "$f"
  done
fi

printf "\n  ${DIM}Completed in ${MINUTES}m ${SECONDS_LEFT}s${RESET}\n\n"

} # End pipe-safety block
