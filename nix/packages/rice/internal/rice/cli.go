package rice

import (
	"strings"
)

// Command represents a parsed CLI command.
type Command struct {
	Tag     string // "system", "home", "nixos", "darwin", "nix", "flake"
	Subcmd  string // e.g., "build", "switch", "boot", "check", "fmt", "update"
	User    string // for home commands
	Host    string // for home commands
	HasHost bool   // true if host was explicitly provided
	Name    string // for flake update
}

// ParseResult is the output of Parse.
// Kind is "success", "help", or "error".
type ParseResult struct {
	Kind    string // result kind: "success", "help", or "error"
	CLI     Command
	Text    string // help/usage text for help and error results
	Message string // error message for error results
}

// Help texts — verbatim from cli.ts.
const topLevelHelp = `NixOS/Darwin configuration management

Usage: rice <COMMAND>

Commands:
  system  System configuration
  home    Home Manager
  nixos   NixOS commands
  darwin  Darwin commands
  nix     Nix maintenance
  flake   Flake management

Options:
  -h, --help  Print help`

const systemHelp = `System configuration

Usage: rice system <COMMAND>

Commands:
  build   Build system configuration
  switch  Build and switch immediately

Options:
  -h, --help  Print help`

const homeHelp = `Home Manager

Usage: rice home <COMMAND> [USER] [HOST]

Commands:
  build   Build home-manager configuration
  switch  Build and activate home-manager configuration

Options:
  -h, --help  Print help`

const nixosHelp = `NixOS commands

Usage: rice nixos <COMMAND>

Commands:
  build   Build NixOS configuration
  boot    Build and activate on next boot
  switch  Build and switch immediately

Options:
  -h, --help  Print help`

const darwinHelp = `Darwin commands

Usage: rice darwin <COMMAND>

Commands:
  build   Build Darwin configuration
  switch  Build and switch immediately

Options:
  -h, --help  Print help`

const nixHelp = `Nix maintenance

Usage: rice nix <COMMAND>

Commands:
  optimise  Optimize nix store
  repair    Repair nix store
  clean     Clean nix cache and run cleanup

Options:
  -h, --help  Print help`

const flakeHelp = `Flake management

Usage: rice flake <COMMAND>

Commands:
  check   Check flake validity
  fmt     Format and check code
  update  Update flake inputs (use "all" to update all)

Options:
  -h, --help  Print help`

func isHelp(s string) bool {
	return s == "-h" || s == "--help"
}

func successResult(cli Command) ParseResult {
	return ParseResult{Kind: "success", CLI: cli}
}

func helpResult(text string) ParseResult {
	return ParseResult{Kind: "help", Text: text}
}

func errorResult(message, text string) ParseResult {
	return ParseResult{Kind: "error", Message: message, Text: text}
}

// parseNoArgs returns success if tail is empty, or an error listing unexpected arguments.
func parseNoArgs(tag, subcmd, usage string, tail []string) ParseResult {
	if len(tail) > 0 {
		return errorResult("unexpected arguments: "+strings.Join(tail, " "), usage)
	}
	return successResult(Command{Tag: tag, Subcmd: subcmd})
}

// Parse parses os.Args[1:] into a ParseResult.
// It dispatches on the first argument to the appropriate sub-parser.
func Parse(args []string) ParseResult {
	if len(args) == 0 || isHelp(args[0]) {
		return helpResult(topLevelHelp)
	}

	cmd := args[0]
	rest := args[1:]

	switch cmd {
	case "system":
		return parseSystem(rest)
	case "home":
		return parseHome(rest)
	case "nixos":
		return parseNixos(rest)
	case "darwin":
		return parseDarwin(rest)
	case "nix":
		return parseNix(rest)
	case "flake":
		return parseFlake(rest)
	default:
		return errorResult("unknown command: "+cmd, topLevelHelp)
	}
}

func parseSystem(args []string) ParseResult {
	if len(args) == 0 || isHelp(args[0]) {
		return helpResult(systemHelp)
	}
	subcmd := args[0]
	tail := args[1:]

	switch subcmd {
	case "build":
		return parseNoArgs("system", "build", systemHelp, tail)
	case "switch":
		return parseNoArgs("system", "switch", systemHelp, tail)
	default:
		return errorResult("unknown system subcommand: "+subcmd, systemHelp)
	}
}

func parseHome(args []string) ParseResult {
	if len(args) == 0 || isHelp(args[0]) {
		return helpResult(homeHelp)
	}
	subcmd := args[0]
	rest := args[1:]

	if subcmd != "build" && subcmd != "switch" {
		return errorResult("unknown home subcommand: "+subcmd, homeHelp)
	}

	// Trailing help flag after a valid subcommand returns group help.
	for _, p := range rest {
		if isHelp(p) {
			return helpResult(homeHelp)
		}
	}

	if len(rest) > 2 {
		return errorResult("unexpected arguments: "+strings.Join(rest[2:], " "), homeHelp)
	}

	user := "annt"
	if len(rest) > 0 {
		user = rest[0]
	}
	var host string
	var hasHost bool
	if len(rest) > 1 {
		host = rest[1]
		hasHost = true
	}

	return successResult(Command{
		Tag:     "home",
		Subcmd:  subcmd,
		User:    user,
		Host:    host,
		HasHost: hasHost,
	})
}

func parseNixos(args []string) ParseResult {
	if len(args) == 0 || isHelp(args[0]) {
		return helpResult(nixosHelp)
	}
	subcmd := args[0]
	tail := args[1:]

	switch subcmd {
	case "build":
		return parseNoArgs("nixos", "build", nixosHelp, tail)
	case "boot":
		return parseNoArgs("nixos", "boot", nixosHelp, tail)
	case "switch":
		return parseNoArgs("nixos", "switch", nixosHelp, tail)
	default:
		return errorResult("unknown nixos subcommand: "+subcmd, nixosHelp)
	}
}

func parseDarwin(args []string) ParseResult {
	if len(args) == 0 || isHelp(args[0]) {
		return helpResult(darwinHelp)
	}
	subcmd := args[0]
	tail := args[1:]

	switch subcmd {
	case "build":
		return parseNoArgs("darwin", "build", darwinHelp, tail)
	case "switch":
		return parseNoArgs("darwin", "switch", darwinHelp, tail)
	default:
		return errorResult("unknown darwin subcommand: "+subcmd, darwinHelp)
	}
}

func parseNix(args []string) ParseResult {
	if len(args) == 0 || isHelp(args[0]) {
		return helpResult(nixHelp)
	}
	subcmd := args[0]
	tail := args[1:]

	switch subcmd {
	case "optimise":
		return parseNoArgs("nix", "optimise", nixHelp, tail)
	case "repair":
		return parseNoArgs("nix", "repair", nixHelp, tail)
	case "clean":
		return parseNoArgs("nix", "clean", nixHelp, tail)
	default:
		return errorResult("unknown nix subcommand: "+subcmd, nixHelp)
	}
}

func parseFlake(args []string) ParseResult {
	if len(args) == 0 || isHelp(args[0]) {
		return helpResult(flakeHelp)
	}
	subcmd := args[0]
	rest := args[1:]

	switch subcmd {
	case "check":
		return parseNoArgs("flake", "check", flakeHelp, rest)
	case "fmt":
		return parseNoArgs("flake", "fmt", flakeHelp, rest)
	case "update":
		if len(rest) == 0 || isHelp(rest[0]) {
			return errorResult(`missing flake input name for "update"`, flakeHelp)
		}
		if len(rest) > 1 {
			return errorResult("unexpected arguments: "+strings.Join(rest[1:], " "), flakeHelp)
		}
		name := rest[0]
		if name == "" || (name[0] == '-' && name != "all") {
			return errorResult(`invalid flake input name: "`+name+`"`, flakeHelp)
		}
		return successResult(Command{Tag: "flake", Subcmd: "update", Name: name})
	default:
		return errorResult("unknown flake subcommand: "+subcmd, flakeHelp)
	}
}
