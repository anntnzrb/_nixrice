package rice

import (
	"strings"
	"testing"
)

func TestParse(t *testing.T) {
	cases := []struct {
		name     string
		args     []string
		wantKind string
		// success
		wantTag     string
		wantSubcmd  string
		wantUser    string
		wantHost    string
		wantHasHost bool
		wantName    string
		// help/error
		wantTextContains []string
		wantMsgExact     string
		wantMsgContains  string
	}{
		// ── Top-level help ──
		{
			name:             "no args",
			args:             nil,
			wantKind:         "help",
			wantTextContains: []string{"Usage: rice <COMMAND>"},
		},
		{
			name:     "rice --help",
			args:     []string{"rice", "--help"},
			wantKind: "help",
		},
		{
			name:     "--help",
			args:     []string{"--help"},
			wantKind: "help",
		},
		{
			name:     "-h",
			args:     []string{"-h"},
			wantKind: "help",
		},

		// ── Successful command parsing ──
		{
			name:       "system build",
			args:       []string{"rice", "system", "build"},
			wantKind:   "success",
			wantTag:    "system",
			wantSubcmd: "build",
		},
		{
			name:       "system switch",
			args:       []string{"rice", "system", "switch"},
			wantKind:   "success",
			wantTag:    "system",
			wantSubcmd: "switch",
		},
		{
			name:       "nixos boot",
			args:       []string{"rice", "nixos", "boot"},
			wantKind:   "success",
			wantTag:    "nixos",
			wantSubcmd: "boot",
		},
		{
			name:       "darwin build",
			args:       []string{"rice", "darwin", "build"},
			wantKind:   "success",
			wantTag:    "darwin",
			wantSubcmd: "build",
		},
		{
			name:       "nix optimise",
			args:       []string{"rice", "nix", "optimise"},
			wantKind:   "success",
			wantTag:    "nix",
			wantSubcmd: "optimise",
		},
		{
			name:       "nix repair",
			args:       []string{"rice", "nix", "repair"},
			wantKind:   "success",
			wantTag:    "nix",
			wantSubcmd: "repair",
		},
		{
			name:       "nix clean",
			args:       []string{"rice", "nix", "clean"},
			wantKind:   "success",
			wantTag:    "nix",
			wantSubcmd: "clean",
		},
		{
			name:       "flake check",
			args:       []string{"rice", "flake", "check"},
			wantKind:   "success",
			wantTag:    "flake",
			wantSubcmd: "check",
		},
		{
			name:       "flake fmt",
			args:       []string{"rice", "flake", "fmt"},
			wantKind:   "success",
			wantTag:    "flake",
			wantSubcmd: "fmt",
		},
		{
			name:       "flake update all",
			args:       []string{"rice", "flake", "update", "all"},
			wantKind:   "success",
			wantTag:    "flake",
			wantSubcmd: "update",
			wantName:   "all",
		},
		{
			name:       "flake update nixpkgs",
			args:       []string{"rice", "flake", "update", "nixpkgs"},
			wantKind:   "success",
			wantTag:    "flake",
			wantSubcmd: "update",
			wantName:   "nixpkgs",
		},
		{
			name:        "home build default",
			args:        []string{"rice", "home", "build"},
			wantKind:    "success",
			wantTag:     "home",
			wantSubcmd:  "build",
			wantUser:    "annt",
			wantHasHost: false,
		},
		{
			name:        "home build user",
			args:        []string{"rice", "home", "build", "alice"},
			wantKind:    "success",
			wantTag:     "home",
			wantSubcmd:  "build",
			wantUser:    "alice",
			wantHasHost: false,
		},
		{
			name:        "home build user host",
			args:        []string{"rice", "home", "build", "alice", "mbp"},
			wantKind:    "success",
			wantTag:     "home",
			wantSubcmd:  "build",
			wantUser:    "alice",
			wantHost:    "mbp",
			wantHasHost: true,
		},
		{
			name:        "home switch default",
			args:        []string{"rice", "home", "switch"},
			wantKind:    "success",
			wantTag:     "home",
			wantSubcmd:  "switch",
			wantUser:    "annt",
			wantHasHost: false,
		},
		{
			name:        "home switch user host",
			args:        []string{"rice", "home", "switch", "bob", "nixbox"},
			wantKind:    "success",
			wantTag:     "home",
			wantSubcmd:  "switch",
			wantUser:    "bob",
			wantHost:    "nixbox",
			wantHasHost: true,
		},

		// ── Group help ──
		{
			name:             "system group help",
			args:             []string{"rice", "system"},
			wantKind:         "help",
			wantTextContains: []string{"Usage: rice system"},
		},
		{
			name:     "system --help",
			args:     []string{"rice", "system", "--help"},
			wantKind: "help",
		},
		{
			name:     "nixos group help",
			args:     []string{"rice", "nixos"},
			wantKind: "help",
		},
		{
			name:     "nixos -h",
			args:     []string{"rice", "nixos", "-h"},
			wantKind: "help",
		},
		{
			name:     "darwin group help",
			args:     []string{"rice", "darwin"},
			wantKind: "help",
		},
		{
			name:     "nix group help",
			args:     []string{"rice", "nix"},
			wantKind: "help",
		},
		{
			name:     "home group help",
			args:     []string{"rice", "home"},
			wantKind: "help",
		},
		{
			name:     "flake group help",
			args:     []string{"rice", "flake"},
			wantKind: "help",
		},
		{
			name:     "flake --help",
			args:     []string{"rice", "flake", "--help"},
			wantKind: "help",
		},

		// ── Special help cases (preserve TS oddities) ──
		{
			name:     "home build --help",
			args:     []string{"rice", "home", "build", "--help"},
			wantKind: "help",
		},
		{
			name:            "flake update --help",
			args:            []string{"rice", "flake", "update", "--help"},
			wantKind:        "error",
			wantMsgContains: "missing flake input name",
		},

		// ── Error cases ──
		{
			name:             "unknown top-level",
			args:             []string{"rice", "wat"},
			wantKind:         "error",
			wantMsgExact:     "unknown command: wat",
			wantTextContains: []string{"Usage: rice <COMMAND>"},
		},
		{
			name:         "unknown system subcmd",
			args:         []string{"rice", "system", "wat"},
			wantKind:     "error",
			wantMsgExact: "unknown system subcommand: wat",
		},
		{
			name:         "unknown home subcmd",
			args:         []string{"rice", "home", "wat"},
			wantKind:     "error",
			wantMsgExact: "unknown home subcommand: wat",
		},
		{
			name:         "unknown nixos subcmd",
			args:         []string{"rice", "nixos", "wat"},
			wantKind:     "error",
			wantMsgExact: "unknown nixos subcommand: wat",
		},
		{
			name:         "unknown darwin subcmd",
			args:         []string{"rice", "darwin", "wat"},
			wantKind:     "error",
			wantMsgExact: "unknown darwin subcommand: wat",
		},
		{
			name:         "unknown nix subcmd",
			args:         []string{"rice", "nix", "wat"},
			wantKind:     "error",
			wantMsgExact: "unknown nix subcommand: wat",
		},
		{
			name:         "unknown flake subcmd",
			args:         []string{"rice", "flake", "wat"},
			wantKind:     "error",
			wantMsgExact: "unknown flake subcommand: wat",
		},
		{
			name:         "system build extra",
			args:         []string{"rice", "system", "build", "extra"},
			wantKind:     "error",
			wantMsgExact: "unexpected arguments: extra",
		},
		{
			name:     "nixos switch extra",
			args:     []string{"rice", "nixos", "switch", "x", "y"},
			wantKind: "error",
		},
		{
			name:     "home build three extra",
			args:     []string{"rice", "home", "build", "a", "b", "c"},
			wantKind: "error",
		},
		{
			name:            "flake update missing",
			args:            []string{"rice", "flake", "update"},
			wantKind:        "error",
			wantMsgContains: "missing flake input name",
		},

		// ── Leading-hyphen name hardening ──
		{
			name:            "flake update -bad",
			args:            []string{"rice", "flake", "update", "-bad"},
			wantKind:        "error",
			wantMsgContains: "invalid flake input name",
		},
		{
			name:            "flake update empty",
			args:            []string{"rice", "flake", "update", ""},
			wantKind:        "error",
			wantMsgContains: "invalid flake input name",
		},

		// ── Accepts argv without rice prefix ──
		{
			name:       "system build no prefix",
			args:       []string{"system", "build"},
			wantKind:   "success",
			wantTag:    "system",
			wantSubcmd: "build",
		},
		{
			name:       "home build no prefix",
			args:       []string{"home", "build"},
			wantKind:   "success",
			wantTag:    "home",
			wantSubcmd: "build",
		},
	}

	for _, tt := range cases {
		t.Run(tt.name, func(t *testing.T) {
			got := Parse(tt.args)

			if got.Kind != tt.wantKind {
				t.Errorf("Kind = %q, want %q", got.Kind, tt.wantKind)
			}

			if tt.wantKind == "success" {
				if got.CLI.Tag != tt.wantTag {
					t.Errorf("CLI.Tag = %q, want %q", got.CLI.Tag, tt.wantTag)
				}
				if got.CLI.Subcmd != tt.wantSubcmd {
					t.Errorf("CLI.Subcmd = %q, want %q", got.CLI.Subcmd, tt.wantSubcmd)
				}
				if tt.wantUser != "" || tt.wantHasHost {
					if got.CLI.User != tt.wantUser {
						t.Errorf("CLI.User = %q, want %q", got.CLI.User, tt.wantUser)
					}
				}
				if tt.wantHost != "" || tt.wantHasHost {
					if got.CLI.Host != tt.wantHost {
						t.Errorf("CLI.Host = %q, want %q", got.CLI.Host, tt.wantHost)
					}
					if got.CLI.HasHost != tt.wantHasHost {
						t.Errorf("CLI.HasHost = %v, want %v", got.CLI.HasHost, tt.wantHasHost)
					}
				}
				if tt.wantName != "" {
					if got.CLI.Name != tt.wantName {
						t.Errorf("CLI.Name = %q, want %q", got.CLI.Name, tt.wantName)
					}
				}
			}

			for _, sub := range tt.wantTextContains {
				if !strings.Contains(got.Text, sub) {
					t.Errorf("Text missing %q, got: %s", sub, got.Text)
				}
			}

			if tt.wantMsgExact != "" {
				if got.Message != tt.wantMsgExact {
					t.Errorf("Message = %q, want %q", got.Message, tt.wantMsgExact)
				}
			}
			if tt.wantMsgContains != "" {
				if !strings.Contains(got.Message, tt.wantMsgContains) {
					t.Errorf("Message missing %q, got: %s", tt.wantMsgContains, got.Message)
				}
			}
		})
	}
}
