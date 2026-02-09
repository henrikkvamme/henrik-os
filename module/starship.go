package module

import (
	"fmt"
	"io"
	"path/filepath"

	"github.com/henrikkvamme/henrik-os/configs"
)

func init() {
	Register(&Starship{})
}

type Starship struct{}

func (s *Starship) Name() string         { return "Starship Prompt" }
func (s *Starship) ID() string           { return "starship" }
func (s *Starship) Description() string  { return "Configure Starship prompt" }
func (s *Starship) Dependencies() []string { return []string{"homebrew"} }

func (s *Starship) Install(w io.Writer) error {
	dest := filepath.Join(HomeDir(), ".config/starship.toml")
	if err := WriteEmbedded(w, &configs.FS, "starship/starship.toml", dest, 0o644); err != nil {
		return err
	}
	fmt.Fprintln(w, "  Starship configured")
	return nil
}
