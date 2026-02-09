package module

import (
	"fmt"
	"io"
	"path/filepath"

	"github.com/henrikkvamme/henrik-os/configs"
)

func init() {
	Register(&ClaudeConfig{})
}

type ClaudeConfig struct{}

func (c *ClaudeConfig) Name() string         { return "Claude Code Config" }
func (c *ClaudeConfig) ID() string           { return "claude-config" }
func (c *ClaudeConfig) Description() string  { return "Sync Claude Code config (CLAUDE.md, settings, hooks, MCP, statusline)" }
func (c *ClaudeConfig) Dependencies() []string { return nil }

func (c *ClaudeConfig) Install(w io.Writer) error {
	claudeDir := filepath.Join(HomeDir(), ".claude")

	// Config files to sync
	files := []struct{ src, rel string }{
		{"claude/CLAUDE.md", "CLAUDE.md"},
		{"claude/settings.json", "settings.json"},
		{"claude/.mcp.json", ".mcp.json"},
		{"claude/statusline-command.sh", "statusline-command.sh"},
		{"claude/statusline-fish.fish", "statusline-fish.fish"},
	}

	for _, f := range files {
		dest := filepath.Join(claudeDir, f.rel)
		if err := WriteEmbedded(w, &configs.FS, f.src, dest, 0o644); err != nil {
			return err
		}
	}

	// Hooks (need executable permission)
	hooks := []string{
		"ts_typecheck.py",
		"play_audio.py",
		"macos_notification.py",
	}

	for _, h := range hooks {
		dest := filepath.Join(claudeDir, "hooks", h)
		if err := WriteEmbedded(w, &configs.FS, "claude/hooks/"+h, dest, 0o755); err != nil {
			return err
		}
	}

	fmt.Fprintln(w, "  Claude Code config synced")
	return nil
}
