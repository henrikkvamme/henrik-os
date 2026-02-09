package tui

import (
	"fmt"
	"io"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/henrikkvamme/henrik-os/module"
)

// Phase tracks which phase the TUI is in.
type phase int

const (
	phaseSelect  phase = iota
	phaseInstall
	phaseDone
)

// Model is the Bubbletea model.
type Model struct {
	modules  []module.Module
	cursor   int
	selected map[int]bool
	phase    phase

	// Install phase
	installing int
	results    []installResult
	spinner    spinner.Model
	logs       []string
	startTime  time.Time
	elapsed    time.Duration
}

type installResult struct {
	err     error
	elapsed time.Duration
}

type installDoneMsg struct {
	index   int
	err     error
	elapsed time.Duration
	logs    string
}

type tickMsg time.Time

// New creates a new TUI model.
func New() Model {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = spinnerStyle

	mods := module.All()
	selected := make(map[int]bool)
	for i := range mods {
		selected[i] = true
	}

	return Model{
		modules:  mods,
		selected: selected,
		spinner:  s,
	}
}

func (m Model) Init() tea.Cmd {
	return nil
}

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch m.phase {
	case phaseSelect:
		return m.updateSelect(msg)
	case phaseInstall:
		return m.updateInstall(msg)
	case phaseDone:
		if msg, ok := msg.(tea.KeyMsg); ok {
			if msg.String() == "q" || msg.String() == "enter" || msg.String() == "ctrl+c" {
				return m, tea.Quit
			}
		}
		return m, nil
	}
	return m, nil
}

func (m Model) updateSelect(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c":
			return m, tea.Quit
		case "up", "k":
			if m.cursor > 0 {
				m.cursor--
			}
		case "down", "j":
			if m.cursor < len(m.modules)-1 {
				m.cursor++
			}
		case " ":
			m.selected[m.cursor] = !m.selected[m.cursor]
		case "a":
			allSelected := true
			for i := range m.modules {
				if !m.selected[i] {
					allSelected = false
					break
				}
			}
			for i := range m.modules {
				m.selected[i] = !allSelected
			}
		case "enter":
			return m.startInstall()
		}
	}
	return m, nil
}

func (m Model) updateInstall(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		if msg.String() == "ctrl+c" {
			return m, tea.Quit
		}
	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd
	case tickMsg:
		m.elapsed = time.Since(m.startTime)
		return m, tickCmd()
	case installDoneMsg:
		m.results[msg.index] = installResult{err: msg.err, elapsed: msg.elapsed}
		if msg.logs != "" {
			m.logs = append(m.logs, msg.logs)
		}
		next := msg.index + 1
		if next >= len(m.results) {
			m.phase = phaseDone
			m.elapsed = time.Since(m.startTime)
			return m, nil
		}
		m.installing = next
		return m, m.runInstall(next)
	}
	return m, nil
}

func (m Model) startInstall() (tea.Model, tea.Cmd) {
	// Collect selected module IDs
	var ids []string
	for i, mod := range m.modules {
		if m.selected[i] {
			ids = append(ids, mod.ID())
		}
	}
	if len(ids) == 0 {
		return m, tea.Quit
	}

	// Resolve dependencies
	resolved, err := module.Resolve(ids)
	if err != nil {
		m.logs = append(m.logs, fmt.Sprintf("Error: %v", err))
		m.phase = phaseDone
		return m, nil
	}

	m.modules = resolved
	m.results = make([]installResult, len(resolved))
	m.phase = phaseInstall
	m.startTime = time.Now()
	m.installing = 0

	return m, tea.Batch(m.spinner.Tick, tickCmd(), m.runInstall(0))
}

func (m Model) runInstall(index int) tea.Cmd {
	mod := m.modules[index]
	return func() tea.Msg {
		var buf strings.Builder
		start := time.Now()
		err := mod.Install(&buf)
		return installDoneMsg{
			index:   index,
			err:     err,
			elapsed: time.Since(start),
			logs:    buf.String(),
		}
	}
}

func tickCmd() tea.Cmd {
	return tea.Tick(time.Second, func(t time.Time) tea.Msg {
		return tickMsg(t)
	})
}

func (m Model) View() string {
	switch m.phase {
	case phaseSelect:
		return m.viewSelect()
	case phaseInstall:
		return m.viewInstall()
	case phaseDone:
		return m.viewDone()
	}
	return ""
}

func (m Model) viewSelect() string {
	var b strings.Builder
	b.WriteString(titleStyle.Render(banner))
	b.WriteString("\n\n")
	b.WriteString(dimStyle.Render("  Select modules to install (space=toggle, a=all, enter=start, q=quit)"))
	b.WriteString("\n\n")

	for i, mod := range m.modules {
		cursor := "  "
		if m.cursor == i {
			cursor = selectedStyle.Render("▸ ")
		}

		check := dimStyle.Render("○")
		if m.selected[i] {
			check = checkStyle.Render("●")
		}

		name := mod.Name()
		if m.cursor == i {
			name = selectedStyle.Render(name)
		}

		deps := ""
		if d := mod.Dependencies(); len(d) > 0 {
			deps = depHintStyle.Render(fmt.Sprintf(" (requires %s)", strings.Join(d, ", ")))
		}

		fmt.Fprintf(&b, "%s%s %s%s\n", cursor, check, name, deps)
	}

	return b.String()
}

func (m Model) viewInstall() string {
	var b strings.Builder
	b.WriteString(titleStyle.Render(banner))
	b.WriteString("\n\n")
	b.WriteString(fmt.Sprintf("  Installing... %s\n\n", dimStyle.Render(formatDuration(m.elapsed))))

	for i, mod := range m.modules {
		var icon string
		var detail string

		if i < m.installing {
			// Completed
			r := m.results[i]
			if r.err != nil {
				icon = crossStyle.Render("✗")
				detail = crossStyle.Render(fmt.Sprintf(" (%s)", formatDuration(r.elapsed)))
			} else {
				icon = checkStyle.Render("✓")
				detail = dimStyle.Render(fmt.Sprintf(" (%s)", formatDuration(r.elapsed)))
			}
		} else if i == m.installing {
			// In progress
			icon = m.spinner.View()
		} else {
			// Pending
			icon = dimStyle.Render("○")
		}

		fmt.Fprintf(&b, "  %s %s%s\n", icon, mod.Name(), detail)
	}

	return b.String()
}

func (m Model) viewDone() string {
	var b strings.Builder
	b.WriteString(titleStyle.Render(banner))
	b.WriteString("\n\n")

	succeeded := 0
	failed := 0
	for _, r := range m.results {
		if r.err != nil {
			failed++
		} else {
			succeeded++
		}
	}

	b.WriteString(fmt.Sprintf("  Done in %s", formatDuration(m.elapsed)))
	if failed > 0 {
		b.WriteString(fmt.Sprintf(" — %s succeeded, %s failed",
			checkStyle.Render(fmt.Sprintf("%d", succeeded)),
			crossStyle.Render(fmt.Sprintf("%d", failed))))
	}
	b.WriteString("\n\n")

	for i, mod := range m.modules {
		r := m.results[i]
		if r.err != nil {
			fmt.Fprintf(&b, "  %s %s %s\n", crossStyle.Render("✗"), mod.Name(),
				crossStyle.Render(r.err.Error()))
		} else {
			fmt.Fprintf(&b, "  %s %s %s\n", checkStyle.Render("✓"), mod.Name(),
				dimStyle.Render(formatDuration(r.elapsed)))
		}
	}

	b.WriteString("\n")
	b.WriteString(postInstallInstructions(m.modules))
	b.WriteString("\n")
	b.WriteString(dimStyle.Render("  Press q or enter to exit"))
	b.WriteString("\n")

	return b.String()
}

func formatDuration(d time.Duration) string {
	if d < time.Second {
		return fmt.Sprintf("%dms", d.Milliseconds())
	}
	m := int(d.Minutes())
	s := int(d.Seconds()) % 60
	if m > 0 {
		return fmt.Sprintf("%dm%ds", m, s)
	}
	return fmt.Sprintf("%ds", s)
}

func postInstallInstructions(modules []module.Module) string {
	ids := make(map[string]bool)
	for _, m := range modules {
		ids[m.ID()] = true
	}

	var b strings.Builder
	b.WriteString(titleStyle.Render("  Manual Steps:"))
	b.WriteString("\n\n")

	if ids["ssh"] {
		b.WriteString("  1. gh auth login\n")
		b.WriteString("  2. gh ssh-key add ~/.ssh/id_ed25519.pub -t \"Mac\"\n")
	}
	if ids["fish"] {
		b.WriteString("  3. Open a new terminal to start using Fish shell\n")
	}
	if ids["neovim"] {
		b.WriteString("  4. Run nvim once to install LazyVim plugins\n")
	}

	return b.String()
}

// SelectedIDs returns the resolved modules for headless use.
func (m Model) SelectedIDs() []string {
	var ids []string
	for i, mod := range m.modules {
		if m.selected[i] {
			ids = append(ids, mod.ID())
		}
	}
	return ids
}

// RunHeadless runs selected modules without TUI, writing output to w.
func RunHeadless(modules []module.Module, w io.Writer) error {
	start := time.Now()
	var failed []string

	for _, mod := range modules {
		fmt.Fprintf(w, "\n══ %s ══\n", mod.Name())
		mStart := time.Now()
		if err := mod.Install(w); err != nil {
			fmt.Fprintf(w, "  ✗ Failed: %v (%s)\n", err, formatDuration(time.Since(mStart)))
			failed = append(failed, mod.Name())
		} else {
			fmt.Fprintf(w, "  ✓ Done (%s)\n", formatDuration(time.Since(mStart)))
		}
	}

	fmt.Fprintf(w, "\nCompleted in %s\n", formatDuration(time.Since(start)))
	if len(failed) > 0 {
		fmt.Fprintf(w, "Failed: %s\n", strings.Join(failed, ", "))
	}
	fmt.Fprintln(w)
	fmt.Fprint(w, postInstallInstructions(modules))
	return nil
}
