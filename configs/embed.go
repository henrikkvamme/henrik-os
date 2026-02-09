package configs

import "embed"

//go:embed all:fish ghostty/* starship/* nvim/* git/* vscode/* ssh/* macos/* claude/*
var FS embed.FS
