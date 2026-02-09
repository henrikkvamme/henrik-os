package configs

import "embed"

//go:embed fish/* ghostty/* starship/* nvim/* git/* vscode/* ssh/* macos/* claude/*
var FS embed.FS
