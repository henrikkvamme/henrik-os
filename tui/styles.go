package tui

import "github.com/charmbracelet/lipgloss"

var (
	purple    = lipgloss.Color("#9f31e2")
	dimPurple = lipgloss.Color("#6b21a8")
	green     = lipgloss.Color("#4ade80")
	red       = lipgloss.Color("#ef4444")
	yellow    = lipgloss.Color("#facc15")
	dim       = lipgloss.Color("#6b7280")

	titleStyle = lipgloss.NewStyle().
			Foreground(purple).
			Bold(true)

	selectedStyle = lipgloss.NewStyle().
			Foreground(purple)

	checkStyle = lipgloss.NewStyle().
			Foreground(green)

	crossStyle = lipgloss.NewStyle().
			Foreground(red)

	spinnerStyle = lipgloss.NewStyle().
			Foreground(yellow)

	dimStyle = lipgloss.NewStyle().
			Foreground(dim)

	depHintStyle = lipgloss.NewStyle().
			Foreground(dimPurple)
)

const banner = `
██╗  ██╗███████╗███╗   ██╗██████╗ ██╗██╗  ██╗     ██████╗ ███████╗
██║  ██║██╔════╝████╗  ██║██╔══██╗██║██║ ██╔╝    ██╔═══██╗██╔════╝
███████║█████╗  ██╔██╗ ██║██████╔╝██║█████╔╝     ██║   ██║███████╗
██╔══██║██╔══╝  ██║╚██╗██║██╔══██╗██║██╔═██╗     ██║   ██║╚════██║
██║  ██║███████╗██║ ╚████║██║  ██║██║██║  ██╗    ╚██████╔╝███████║
╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝     ╚═════╝ ╚══════╝`
