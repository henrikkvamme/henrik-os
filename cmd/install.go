package cmd

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/spf13/cobra"

	"github.com/henrikkvamme/henrik-os/module"
	"github.com/henrikkvamme/henrik-os/tui"
)

var allFlag bool

func init() {
	installCmd.Flags().BoolVar(&allFlag, "all", false, "Install all modules (headless)")
	rootCmd.AddCommand(installCmd)
}

var installCmd = &cobra.Command{
	Use:   "install [modules...]",
	Short: "Install development environment modules",
	Long: `Install one or more development environment modules.

Without arguments, launches an interactive TUI for module selection.
With arguments, installs the specified modules headlessly.
Use --all to install everything without interaction.

Examples:
  henrik-os install                # Interactive TUI
  henrik-os install --all          # Everything, headless
  henrik-os install fish git       # Specific modules (auto-resolves deps)
  henrik-os install claude-config  # Just sync Claude Code config`,
	ValidArgsFunction: func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
		var comps []string
		for _, m := range module.All() {
			comps = append(comps, m.ID()+"\t"+m.Description())
		}
		return comps, cobra.ShellCompDirectiveNoFileComp
	},
	RunE: func(cmd *cobra.Command, args []string) error {
		if allFlag {
			// Headless: all modules
			modules := module.All()
			return tui.RunHeadless(modules, os.Stdout)
		}

		if len(args) > 0 {
			// Headless: specific modules
			modules, err := module.Resolve(args)
			if err != nil {
				return err
			}
			return tui.RunHeadless(modules, os.Stdout)
		}

		// Interactive TUI
		m := tui.New()
		p := tea.NewProgram(m, tea.WithAltScreen())
		if _, err := p.Run(); err != nil {
			return fmt.Errorf("TUI error: %w", err)
		}
		return nil
	},
}
