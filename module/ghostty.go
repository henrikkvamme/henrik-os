package module

import (
	"fmt"
	"io"
	"path/filepath"

	"github.com/henrikkvamme/henrik-os/configs"
)

func init() {
	Register(&Ghostty{})
}

type Ghostty struct{}

func (g *Ghostty) Name() string         { return "Ghostty" }
func (g *Ghostty) ID() string           { return "ghostty" }
func (g *Ghostty) Description() string  { return "Configure Ghostty terminal" }
func (g *Ghostty) Dependencies() []string { return nil }

func (g *Ghostty) Install(w io.Writer) error {
	configDir := filepath.Join(HomeDir(), ".config/ghostty")
	files := []string{"config"}
	for _, f := range files {
		dest := filepath.Join(configDir, f)
		if err := WriteEmbedded(w, &configs.FS, "ghostty/"+f, dest, 0o644); err != nil {
			return err
		}
	}
	fmt.Fprintln(w, "  Ghostty configured")
	return nil
}
