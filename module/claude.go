package module

import (
	"fmt"
	"io"
	"os/exec"
)

func init() {
	Register(&Claude{})
}

type Claude struct{}

func (c *Claude) Name() string         { return "Claude Code" }
func (c *Claude) ID() string           { return "claude" }
func (c *Claude) Description() string  { return "Install Claude Code CLI" }
func (c *Claude) Dependencies() []string { return []string{"node"} }

func (c *Claude) Install(w io.Writer) error {
	if _, err := exec.LookPath("claude"); err == nil {
		fmt.Fprintln(w, "  Claude Code already installed")
		return nil
	}

	fmt.Fprintln(w, "  Installing Claude Code...")
	cmd := exec.Command("npm", "install", "-g", "@anthropic-ai/claude-code")
	cmd.Stdout = w
	cmd.Stderr = w
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("installing Claude Code: %w", err)
	}
	fmt.Fprintln(w, "  Claude Code installed")
	return nil
}
