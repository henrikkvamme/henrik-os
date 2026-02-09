package module

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/henrikkvamme/henrik-os/configs"
)

func init() {
	Register(&SSH{})
}

type SSH struct{}

func (s *SSH) Name() string         { return "SSH Key Generation" }
func (s *SSH) ID() string           { return "ssh" }
func (s *SSH) Description() string  { return "Generate SSH key and configure SSH" }
func (s *SSH) Dependencies() []string { return nil }

func (s *SSH) Install(w io.Writer) error {
	sshDir := filepath.Join(HomeDir(), ".ssh")
	if err := os.MkdirAll(sshDir, 0o700); err != nil {
		return fmt.Errorf("creating .ssh directory: %w", err)
	}

	keyPath := filepath.Join(sshDir, "id_ed25519")
	if _, err := os.Stat(keyPath); err == nil {
		fmt.Fprintln(w, "  SSH key already exists (skipping key generation)")
	} else {
		fmt.Fprintln(w, "  Generating SSH key...")
		cmd := exec.Command("ssh-keygen", "-t", "ed25519",
			"-C", "henrik.halvorsen.kvamme@gmail.com",
			"-f", keyPath, "-N", "")
		cmd.Stdout = w
		cmd.Stderr = w
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("generating SSH key: %w", err)
		}
	}

	// Write SSH config (always overwrite)
	configPath := filepath.Join(sshDir, "config")
	if err := WriteEmbedded(w, &configs.FS, "ssh/config", configPath, 0o600); err != nil {
		return err
	}

	// Add to keychain
	_ = exec.Command("ssh-add", "--apple-use-keychain", keyPath).Run()
	fmt.Fprintln(w, "  SSH configured")
	return nil
}
