package module

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/henrikkvamme/henrik-os/configs"
)

func init() {
	Register(&VSCode{})
}

type VSCode struct{}

func (v *VSCode) Name() string         { return "VS Code" }
func (v *VSCode) ID() string           { return "vscode" }
func (v *VSCode) Description() string  { return "Configure VS Code settings, extensions, and Neovim integration" }
func (v *VSCode) Dependencies() []string { return []string{"homebrew"} }

var extensions = []string{
	"daltonmenezes.aura-theme",
	"esbenp.prettier-vscode",
	"dbaeumer.vscode-eslint",
	"eamodio.gitlens",
	"github.copilot",
	"github.copilot-chat",
	"bradlc.vscode-tailwindcss",
	"christian-kohler.path-intellisense",
	"anthropic.claude-code",
	"asvetliakov.vscode-neovim",
	"VSpaceCode.whichkey",
	"catppuccin.catppuccin-vsc-icons",
}

func (v *VSCode) Install(w io.Writer) error {
	// Ensure code CLI is available
	if _, err := exec.LookPath("code"); err != nil {
		codeCLI := "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
		if _, err := os.Stat(codeCLI); err == nil {
			cmd := exec.Command("sudo", "ln", "-sf", codeCLI, "/usr/local/bin/code")
			cmd.Stdout = w
			cmd.Stderr = w
			_ = cmd.Run()
			fmt.Fprintln(w, "  Symlinked VS Code CLI")
		} else {
			fmt.Fprintln(w, "  VS Code not found - skipping CLI setup")
		}
	}

	// Install extensions
	fmt.Fprintln(w, "  Installing VS Code extensions...")
	installed, _ := exec.Command("code", "--list-extensions").Output()
	installedList := strings.ToLower(string(installed))
	for _, ext := range extensions {
		if strings.Contains(installedList, strings.ToLower(ext)) {
			fmt.Fprintf(w, "    %-45s already installed\n", ext)
			continue
		}
		if err := exec.Command("code", "--install-extension", ext, "--force").Run(); err != nil {
			fmt.Fprintf(w, "    %-45s failed (non-fatal)\n", ext)
		} else {
			fmt.Fprintf(w, "    %-45s installed\n", ext)
		}
	}

	// Write settings.json
	settingsDir := filepath.Join(HomeDir(), "Library/Application Support/Code/User")
	if err := WriteEmbedded(w, &configs.FS, "vscode/settings.json",
		filepath.Join(settingsDir, "settings.json"), 0o644); err != nil {
		return err
	}

	// Write nvim-vscode init.vim
	nvimVscodeDir := filepath.Join(HomeDir(), ".config/nvim-vscode")
	if err := WriteEmbedded(w, &configs.FS, "vscode/init.vim",
		filepath.Join(nvimVscodeDir, "init.vim"), 0o644); err != nil {
		return err
	}

	fmt.Fprintln(w, "  VS Code configured")
	return nil
}
