package module

import (
	"fmt"
	"io"
	"os/exec"
	"path/filepath"

	"github.com/henrikkvamme/henrik-os/configs"
)

func init() {
	Register(&MacOS{})
}

type MacOS struct{}

func (m *MacOS) Name() string         { return "macOS Defaults" }
func (m *MacOS) ID() string           { return "macos" }
func (m *MacOS) Description() string  { return "Configure macOS keyboard, Finder, Dock, and system preferences" }
func (m *MacOS) Dependencies() []string { return nil }

func (m *MacOS) Install(w io.Writer) error {
	fmt.Fprintln(w, "  Configuring macOS defaults...")

	// Keyboard
	defaults := [][]string{
		{"write", "NSGlobalDomain", "KeyRepeat", "-int", "2"},
		{"write", "NSGlobalDomain", "InitialKeyRepeat", "-int", "15"},
		{"write", "NSGlobalDomain", "ApplePressAndHoldEnabled", "-bool", "false"},
		// Finder
		{"write", "NSGlobalDomain", "AppleShowAllExtensions", "-bool", "true"},
		{"write", "com.apple.finder", "AppleShowAllFiles", "-bool", "true"},
		{"write", "com.apple.finder", "ShowPathbar", "-bool", "true"},
		{"write", "com.apple.finder", "ShowStatusBar", "-bool", "true"},
		// Dock
		{"write", "com.apple.dock", "autohide", "-bool", "true"},
		{"write", "com.apple.dock", "show-recents", "-bool", "false"},
		{"write", "com.apple.dock", "autohide-delay", "-float", "0"},
		{"write", "com.apple.dock", "tilesize", "-int", "48"},
		// Screenshots
		{"write", "com.apple.screencapture", "location", "-string", filepath.Join(HomeDir(), "Downloads")},
		// No .DS_Store on network/USB
		{"write", "com.apple.desktopservices", "DSDontWriteNetworkStores", "-bool", "true"},
		{"write", "com.apple.desktopservices", "DSDontWriteUSBStores", "-bool", "true"},
	}

	for _, args := range defaults {
		_ = exec.Command("defaults", args...).Run()
	}

	// Caps Lock → Escape
	fmt.Fprintln(w, "  Mapping Caps Lock to Escape...")
	_ = exec.Command("hidutil", "property", "--set",
		`{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}`).Run()

	// Persist with LaunchAgent
	plistDest := filepath.Join(HomeDir(), "Library/LaunchAgents/com.henrikkvamme.capslock-escape.plist")
	if err := WriteEmbedded(w, &configs.FS, "macos/com.henrikkvamme.capslock-escape.plist", plistDest, 0o644); err != nil {
		return err
	}

	// Touch ID for sudo
	fmt.Fprintln(w, "  Enabling Touch ID for sudo...")
	cmd := exec.Command("sudo", "sh", "-c",
		`grep -q pam_tid.so /etc/pam.d/sudo_local 2>/dev/null || echo 'auth       sufficient     pam_tid.so' > /etc/pam.d/sudo_local`)
	cmd.Stdout = w
	cmd.Stderr = w
	_ = cmd.Run()

	// Restart affected apps
	_ = exec.Command("killall", "Finder").Run()
	_ = exec.Command("killall", "Dock").Run()

	fmt.Fprintln(w, "  macOS defaults configured")
	return nil
}
