package module

import (
	"fmt"
	"io"
	"os/exec"
	"strings"
)

func init() {
	Register(&Homebrew{})
}

type Homebrew struct{}

func (h *Homebrew) Name() string         { return "Homebrew + Packages" }
func (h *Homebrew) ID() string           { return "homebrew" }
func (h *Homebrew) Description() string  { return "Install Homebrew, formulae, casks, and fonts" }
func (h *Homebrew) Dependencies() []string { return []string{"xcode"} }

var formulae = []string{
	"fish", "neovim", "starship", "git", "gh",
	"eza", "zoxide", "fzf", "fd", "bat", "btop",
	"direnv", "fnm", "thefuck", "yazi", "tmux",
	"jq", "ripgrep", "imagemagick", "ffmpeg",
	"deno", "bun",
}

var casks = []string{
	"ghostty", "visual-studio-code", "raycast", "alt-tab",
	"slack", "discord", "figma", "google-chrome", "zen-browser",
	"obsidian", "spotify", "orbstack", "claude",
}

var fonts = []string{
	"font-jetbrains-mono-nerd-font",
	"font-symbols-only-nerd-font",
}

func (h *Homebrew) Install(w io.Writer) error {
	// Install Homebrew if missing
	if _, err := exec.LookPath("brew"); err != nil {
		fmt.Fprintln(w, "  Installing Homebrew...")
		cmd := exec.Command("/bin/bash", "-c",
			`$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)`)
		cmd.Stdout = w
		cmd.Stderr = w
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("installing homebrew: %w", err)
		}
	} else {
		fmt.Fprintln(w, "  Homebrew already installed")
	}

	brewInstall(w, "formulae", formulae, false)
	brewInstall(w, "casks", casks, true)
	brewInstall(w, "fonts", fonts, true)
	return nil
}

func brewInstall(w io.Writer, label string, packages []string, cask bool) {
	fmt.Fprintf(w, "  Installing %s...\n", label)
	for _, pkg := range packages {
		if brewInstalled(pkg, cask) {
			fmt.Fprintf(w, "    %-25s already installed\n", pkg)
			continue
		}
		args := []string{"install"}
		if cask {
			args = append(args, "--cask")
		}
		args = append(args, pkg)
		if err := exec.Command("brew", args...).Run(); err != nil {
			fmt.Fprintf(w, "    %-25s failed (non-fatal)\n", pkg)
		} else {
			fmt.Fprintf(w, "    %-25s installed\n", pkg)
		}
	}
}

func brewInstalled(pkg string, cask bool) bool {
	args := []string{"list"}
	if cask {
		args = append(args, "--cask")
	}
	args = append(args, pkg)
	out, err := exec.Command("brew", args...).CombinedOutput()
	if err != nil {
		return false
	}
	return len(strings.TrimSpace(string(out))) > 0
}
