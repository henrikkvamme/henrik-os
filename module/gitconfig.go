package module

import (
	"fmt"
	"io"
	"path/filepath"

	"github.com/henrikkvamme/henrik-os/configs"
)

func init() {
	Register(&GitConfig{})
}

type GitConfig struct{}

func (g *GitConfig) Name() string         { return "Git Config" }
func (g *GitConfig) ID() string           { return "git" }
func (g *GitConfig) Description() string  { return "Configure Git global settings" }
func (g *GitConfig) Dependencies() []string { return nil }

func (g *GitConfig) Install(w io.Writer) error {
	home := HomeDir()

	if err := WriteEmbedded(w, &configs.FS, "git/.gitconfig",
		filepath.Join(home, ".gitconfig"), 0o644); err != nil {
		return err
	}

	if err := WriteEmbedded(w, &configs.FS, "git/.gitignore_global",
		filepath.Join(home, ".gitignore_global"), 0o644); err != nil {
		return err
	}

	fmt.Fprintln(w, "  Git configured")
	return nil
}
