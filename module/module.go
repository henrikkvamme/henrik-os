package module

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
)

// Module defines the interface that all installation modules must implement.
type Module interface {
	Name() string
	ID() string
	Description() string
	Dependencies() []string
	Install(w io.Writer) error
}

var registry []Module

// Register adds a module to the global registry.
func Register(m Module) {
	registry = append(registry, m)
}

// All returns all registered modules in registration order.
func All() []Module {
	return registry
}

// ByID returns the module with the given ID, or nil if not found.
func ByID(id string) Module {
	for _, m := range registry {
		if m.ID() == id {
			return m
		}
	}
	return nil
}

// Resolve takes a list of module IDs and returns the full list including
// transitive dependencies, in installation order.
func Resolve(ids []string) ([]Module, error) {
	needed := make(map[string]bool)
	var addDeps func(id string) error
	addDeps = func(id string) error {
		if needed[id] {
			return nil
		}
		m := ByID(id)
		if m == nil {
			return fmt.Errorf("unknown module: %s", id)
		}
		for _, dep := range m.Dependencies() {
			if err := addDeps(dep); err != nil {
				return err
			}
		}
		needed[id] = true
		return nil
	}

	for _, id := range ids {
		if err := addDeps(id); err != nil {
			return nil, err
		}
	}

	// Return modules in registry order, filtered to those needed.
	var result []Module
	for _, m := range registry {
		if needed[m.ID()] {
			result = append(result, m)
		}
	}
	return result, nil
}

// BackupAndWrite backs up the existing file (if any) to <path>.bak, then
// writes data to path. It creates parent directories as needed.
func BackupAndWrite(w io.Writer, path string, data []byte, perm os.FileMode) error {
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return fmt.Errorf("creating directory %s: %w", dir, err)
	}

	if _, err := os.Stat(path); err == nil {
		bak := path + ".bak"
		if err := copyFile(path, bak); err != nil {
			return fmt.Errorf("backing up %s: %w", path, err)
		}
		fmt.Fprintf(w, "  Backed up %s → %s\n", path, bak)
	}

	if err := os.WriteFile(path, data, perm); err != nil {
		return fmt.Errorf("writing %s: %w", path, err)
	}
	fmt.Fprintf(w, "  Wrote %s\n", path)
	return nil
}

// WriteEmbedded reads a file from the embedded FS and writes it to dest with backup.
func WriteEmbedded(w io.Writer, fsys interface{ ReadFile(string) ([]byte, error) }, src, dest string, perm os.FileMode) error {
	data, err := fsys.ReadFile(src)
	if err != nil {
		return fmt.Errorf("reading embedded %s: %w", src, err)
	}
	return BackupAndWrite(w, dest, data, perm)
}

func copyFile(src, dst string) error {
	data, err := os.ReadFile(src)
	if err != nil {
		return err
	}
	return os.WriteFile(dst, data, 0o644)
}

// HomeDir returns the user's home directory.
func HomeDir() string {
	home, _ := os.UserHomeDir()
	return home
}

// ExpandHome expands ~ to the user's home directory.
func ExpandHome(path string) string {
	if len(path) > 0 && path[0] == '~' {
		return filepath.Join(HomeDir(), path[1:])
	}
	return path
}
