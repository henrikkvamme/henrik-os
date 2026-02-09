# Henrik OS

Mac development environment setup as a single Go binary with interactive module selection.

## Install

```bash
brew install henrikkvamme/tap/henrik-os
```

Or on a fresh machine:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && brew install henrikkvamme/tap/henrik-os && henrik-os install
```

## Usage

```bash
henrik-os install                # Interactive TUI multiselect
henrik-os install --all          # Headless, everything
henrik-os install fish git       # Headless, specific modules (auto-resolves deps)
henrik-os install claude-config  # Just sync Claude Code config
```

## Modules

| Module | ID | Dependencies |
|--------|----|-------------|
| Xcode CLI Tools | `xcode` | - |
| Homebrew + Packages | `homebrew` | xcode |
| SSH Key Generation | `ssh` | - |
| Fish Shell | `fish` | homebrew |
| Ghostty | `ghostty` | - |
| Starship Prompt | `starship` | homebrew |
| Neovim + LazyVim | `neovim` | homebrew |
| Git Config | `git` | - |
| Node.js + Package Managers | `node` | homebrew |
| VS Code | `vscode` | homebrew |
| Claude Code | `claude` | node |
| Claude Code Config | `claude-config` | - |
| macOS Defaults | `macos` | - |

Dependencies are resolved automatically. Running `henrik-os install fish` will also install xcode and homebrew.

## What it sets up

- **Fish shell** with vi bindings, Oh My Fish + git plugin
- **fnm** for Node version management, **corepack** for pnpm/yarn
- **Starship** prompt with custom purple Aura palette
- **Neovim** with LazyVim (TypeScript, JSON, Rust extras)
- **VS Code** with Aura Dark theme, Neovim integration, WhichKey bindings
- **Ghostty** terminal with Aura theme
- **Claude Code** with hooks, MCP servers, and custom statusline
- **Caps Lock mapped to Escape** via `hidutil` + LaunchAgent
- **macOS defaults**: fast key repeat, auto-hide Dock, Finder tweaks

## Config override behavior

Modules always write configs, overwriting existing files. Before overwriting, the existing file is backed up to `<path>.bak`. This lets you re-run any module to reset a config to the canonical version.

Exceptions: SSH keys are never overwritten. Homebrew packages are skipped if already installed.

## Development

```bash
go build -o henrik-os .
go run . install ghostty    # Test a single module
```

## Release

Tag a version to trigger GoReleaser via GitHub Actions:

```bash
git tag v0.1.0 && git push --tags
```

Requires `HOMEBREW_TAP_GITHUB_TOKEN` secret in the repo for publishing to the Homebrew tap.
