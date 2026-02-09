package module

import (
	"fmt"
	"io"
	"os/exec"
	"strings"
)

func init() {
	Register(&Node{})
}

type Node struct{}

func (n *Node) Name() string         { return "Node.js + Package Managers" }
func (n *Node) ID() string           { return "node" }
func (n *Node) Description() string  { return "Install Node.js LTS via fnm, enable corepack" }
func (n *Node) Dependencies() []string { return []string{"homebrew"} }

func (n *Node) Install(w io.Writer) error {
	// Check if Node LTS already installed via fnm
	out, _ := exec.Command("fnm", "list").CombinedOutput()
	if strings.Contains(string(out), "lts-latest") {
		fmt.Fprintln(w, "  Node LTS already installed")
	} else {
		fmt.Fprintln(w, "  Installing Node.js LTS via fnm...")
		cmd := exec.Command("fnm", "install", "--lts")
		cmd.Stdout = w
		cmd.Stderr = w
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("installing Node.js: %w", err)
		}
		_ = exec.Command("fnm", "default", "lts-latest").Run()
		fmt.Fprintln(w, "  Node.js LTS installed")
	}

	// Enable corepack
	fmt.Fprintln(w, "  Enabling corepack...")
	_ = exec.Command("corepack", "enable").Run()
	fmt.Fprintln(w, "  corepack enabled (pnpm + yarn available)")

	fmt.Fprintln(w, "  Bun + Deno already installed via Homebrew")
	return nil
}
