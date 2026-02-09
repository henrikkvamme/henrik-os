package module

import (
	"fmt"
	"io"
	"os/exec"
	"time"
)

func init() {
	Register(&Xcode{})
}

type Xcode struct{}

func (x *Xcode) Name() string         { return "Xcode CLI Tools" }
func (x *Xcode) ID() string           { return "xcode" }
func (x *Xcode) Description() string  { return "Install Xcode Command Line Tools" }
func (x *Xcode) Dependencies() []string { return nil }

func (x *Xcode) Install(w io.Writer) error {
	// Check if already installed
	if err := exec.Command("xcode-select", "-p").Run(); err == nil {
		fmt.Fprintln(w, "  Xcode CLI tools already installed")
		return nil
	}

	fmt.Fprintln(w, "  Installing Xcode Command Line Tools...")
	fmt.Fprintln(w, "  Click 'Install' in the dialog that appears")
	_ = exec.Command("xcode-select", "--install").Run()

	// Poll until installed
	for {
		if err := exec.Command("xcode-select", "-p").Run(); err == nil {
			break
		}
		time.Sleep(5 * time.Second)
	}
	fmt.Fprintln(w, "  Xcode CLI tools installed")
	return nil
}
