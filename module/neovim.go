package module

import (
	"fmt"
	"io"
	"path/filepath"

	"github.com/henrikkvamme/henrik-os/configs"
)

func init() {
	Register(&Neovim{})
}

type Neovim struct{}

func (n *Neovim) Name() string         { return "Neovim + LazyVim" }
func (n *Neovim) ID() string           { return "neovim" }
func (n *Neovim) Description() string  { return "Configure Neovim with LazyVim" }
func (n *Neovim) Dependencies() []string { return []string{"homebrew"} }

func (n *Neovim) Install(w io.Writer) error {
	nvimDir := filepath.Join(HomeDir(), ".config/nvim")

	files := []struct{ src, rel string }{
		{"nvim/init.lua", "init.lua"},
		{"nvim/stylua.toml", "stylua.toml"},
		{"nvim/.neoconf.json", ".neoconf.json"},
		{"nvim/lua/config/lazy.lua", "lua/config/lazy.lua"},
		{"nvim/lua/config/options.lua", "lua/config/options.lua"},
		{"nvim/lua/config/keymaps.lua", "lua/config/keymaps.lua"},
		{"nvim/lua/config/autocmds.lua", "lua/config/autocmds.lua"},
		{"nvim/lua/plugins/init.lua", "lua/plugins/init.lua"},
	}

	for _, f := range files {
		dest := filepath.Join(nvimDir, f.rel)
		if err := WriteEmbedded(w, &configs.FS, f.src, dest, 0o644); err != nil {
			return err
		}
	}

	fmt.Fprintln(w, "  Neovim + LazyVim configured")
	return nil
}
