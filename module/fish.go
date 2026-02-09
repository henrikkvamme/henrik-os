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
	Register(&Fish{})
}

type Fish struct{}

func (f *Fish) Name() string         { return "Fish Shell" }
func (f *Fish) ID() string           { return "fish" }
func (f *Fish) Description() string  { return "Configure Fish shell, functions, and Oh My Fish" }
func (f *Fish) Dependencies() []string { return []string{"homebrew"} }

func (f *Fish) Install(w io.Writer) error {
	fishPath := "/opt/homebrew/bin/fish"
	if p, err := exec.LookPath("fish"); err == nil {
		fishPath = p
	}

	// Add to /etc/shells if missing
	shells, _ := os.ReadFile("/etc/shells")
	if !strings.Contains(string(shells), fishPath) {
		fmt.Fprintln(w, "  Adding fish to /etc/shells...")
		cmd := exec.Command("sudo", "sh", "-c",
			fmt.Sprintf("echo '%s' >> /etc/shells", fishPath))
		cmd.Stdout = w
		cmd.Stderr = w
		_ = cmd.Run()
	}

	// Set as default shell
	if os.Getenv("SHELL") != fishPath {
		fmt.Fprintln(w, "  Setting fish as default shell...")
		cmd := exec.Command("chsh", "-s", fishPath)
		cmd.Stdout = w
		cmd.Stderr = w
		_ = cmd.Run()
	}
	fmt.Fprintln(w, "  Fish is default shell")

	// Remove legacy aliases file
	os.Remove(filepath.Join(HomeDir(), ".config/fish/functions/aliases.fish"))

	configDir := filepath.Join(HomeDir(), ".config/fish")
	funcDir := filepath.Join(configDir, "functions")

	// Write config.fish
	if err := WriteEmbedded(w, &configs.FS, "fish/config.fish",
		filepath.Join(configDir, "config.fish"), 0o644); err != nil {
		return err
	}

	// Write fish functions
	functions := []string{
		"y.fish", "b.fish", "fuck.fish",
		"_fzf_compgen_path.fish", "_fzf_compgen_dir.fish",
	}
	for _, fn := range functions {
		if err := WriteEmbedded(w, &configs.FS, "fish/functions/"+fn,
			filepath.Join(funcDir, fn), 0o644); err != nil {
			return err
		}
	}

	// Oh My Fish
	omfDir := filepath.Join(HomeDir(), ".local/share/omf")
	if _, err := os.Stat(omfDir); os.IsNotExist(err) {
		fmt.Fprintln(w, "  Installing Oh My Fish...")
		cmd := exec.Command("fish", "-c",
			"curl -sL https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish /dev/stdin --noninteractive")
		cmd.Stdout = w
		cmd.Stderr = w
		_ = cmd.Run()
	} else {
		fmt.Fprintln(w, "  Oh My Fish already installed")
	}

	// Install git plugin
	cmd := exec.Command("fish", "-c", "omf install git")
	cmd.Stdout = w
	cmd.Stderr = w
	_ = cmd.Run()

	fmt.Fprintln(w, "  Fish shell configured")
	return nil
}
