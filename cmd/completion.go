package cmd

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
)

var installFlag bool

func init() {
	completionCmd.PersistentFlags().BoolVar(&installFlag, "install", false, "Install completion to shell config directory")
	rootCmd.AddCommand(completionCmd)
}

var completionCmd = &cobra.Command{
	Use:   "completion [shell]",
	Short: "Generate shell completions",
	Long: `Generate shell completion scripts for henrik-os.

Without --install, prints the completion script to stdout.
With --install, writes the script to the appropriate shell config directory.`,
}

func init() {
	completionCmd.AddCommand(fishCompletionCmd)
	completionCmd.AddCommand(bashCompletionCmd)
	completionCmd.AddCommand(zshCompletionCmd)
	completionCmd.AddCommand(powershellCompletionCmd)
}

var fishCompletionCmd = &cobra.Command{
	Use:   "fish",
	Short: "Generate fish shell completions",
	RunE: func(cmd *cobra.Command, args []string) error {
		if !installFlag {
			return rootCmd.GenFishCompletion(os.Stdout, true)
		}
		home, err := os.UserHomeDir()
		if err != nil {
			return err
		}
		path := filepath.Join(home, ".config", "fish", "completions", "henrik-os.fish")
		return writeCompletion(path, func(f *os.File) error {
			return rootCmd.GenFishCompletion(f, true)
		})
	},
}

var bashCompletionCmd = &cobra.Command{
	Use:   "bash",
	Short: "Generate bash shell completions",
	RunE: func(cmd *cobra.Command, args []string) error {
		if !installFlag {
			return rootCmd.GenBashCompletionV2(os.Stdout, true)
		}
		home, err := os.UserHomeDir()
		if err != nil {
			return err
		}
		path := filepath.Join(home, ".local", "share", "bash-completion", "completions", "henrik-os")
		return writeCompletion(path, func(f *os.File) error {
			return rootCmd.GenBashCompletionV2(f, true)
		})
	},
}

var zshCompletionCmd = &cobra.Command{
	Use:   "zsh",
	Short: "Generate zsh shell completions",
	RunE: func(cmd *cobra.Command, args []string) error {
		if !installFlag {
			return rootCmd.GenZshCompletion(os.Stdout)
		}
		home, err := os.UserHomeDir()
		if err != nil {
			return err
		}
		path := filepath.Join(home, ".zsh", "completions", "_henrik-os")
		if err := writeCompletion(path, func(f *os.File) error {
			return rootCmd.GenZshCompletion(f)
		}); err != nil {
			return err
		}
		fmt.Fprintf(os.Stderr, "\nEnsure %s is in your fpath. Add this to ~/.zshrc:\n", filepath.Dir(path))
		fmt.Fprintf(os.Stderr, "  fpath=(~/.zsh/completions $fpath)\n  autoload -Uz compinit && compinit\n")
		return nil
	},
}

var powershellCompletionCmd = &cobra.Command{
	Use:   "powershell",
	Short: "Generate PowerShell completions",
	Long:  "Generate PowerShell completions. Only outputs to stdout (no --install support).",
	RunE: func(cmd *cobra.Command, args []string) error {
		if installFlag {
			return fmt.Errorf("--install is not supported for PowerShell; pipe stdout to your profile instead")
		}
		return rootCmd.GenPowerShellCompletionWithDesc(os.Stdout)
	},
}

func writeCompletion(path string, generate func(*os.File) error) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	if err := generate(f); err != nil {
		return err
	}
	fmt.Fprintf(os.Stderr, "Completion installed to %s\n", path)
	return nil
}
