package rice

import (
	"fmt"
	"os"
	"runtime"
)

// CurrentPlatform returns the Platform constant matching the runtime OS.
// On unsupported operating systems it returns PlatformAny (empty string),
// which causes platform-gated tasks to reject.
func CurrentPlatform() Platform {
	switch runtime.GOOS {
	case "darwin":
		return PlatformDarwin
	case "linux":
		return PlatformLinux
	default:
		return PlatformAny
	}
}

// RunCLI dispatches a parsed Command to the appropriate handler.
func RunCLI(cli Command, host string, current Platform) error {
	switch cli.Tag {
	case "system":
		return runSystem(cli, host, current)
	case "home":
		return runHome(cli, host)
	case "nixos":
		return runNixos(cli, host, current)
	case "darwin":
		return runDarwin(cli, host, current)
	case "nix":
		return runNix(cli, host, current)
	case "flake":
		return runFlake(cli, current)
	default:
		return fmt.Errorf("unknown command: %s", cli.Tag)
	}
}

// Main is the entrypoint. It parses args, dispatches to RunCLI on success,
// and prints help/errors otherwise. Returns 0 on success, 1 on failure.
func Main(args []string) int {
	result := Parse(args)

	switch result.Kind {
	case "help":
		fmt.Fprint(os.Stdout, result.Text+"\n")
		return 0
	case "error":
		Err(Stderr, result.Message)
		if result.Text != "" {
			fmt.Fprint(os.Stderr, "\n"+result.Text+"\n")
		}
		return 1
	case "success":
		host := HostShortname()
		current := CurrentPlatform()
		if err := RunCLI(result.CLI, host, current); err != nil {
			Err(Stderr, err.Error())
			return 1
		}
		return 0
	default:
		return 1
	}
}

// runSystem dispatches system commands. On Darwin the switch subcommand builds
// before switching to ensure ./result/sw/bin/darwin-rebuild exists.
func runSystem(cli Command, host string, current Platform) error {
	switch cli.Subcmd {
	case "build":
		if current == PlatformDarwin {
			return ExecTask(DarwinBuild, host, current)
		}
		return ExecTask(NixOSBuild, host, current)
	case "switch":
		if current == PlatformDarwin {
			if err := ExecTask(DarwinBuild, host, current); err != nil {
				return err
			}
			return ExecTask(DarwinSwitch, host, current)
		}
		if err := ExecTask(NixOSBuild, host, current); err != nil {
			return err
		}
		return ExecTask(NixOSSwitch, host, current)
	default:
		return fmt.Errorf("unknown command: %s", cli.Tag)
	}
}

// runHome dispatches home-manager commands. If the CLI provides an explicit host
// it overrides the auto-detected host.
func runHome(cli Command, host string) error {
	targetHost := host
	if cli.HasHost {
		targetHost = cli.Host
	}
	switch cli.Subcmd {
	case "build":
		return HomeBuild(cli.User, targetHost)
	case "switch":
		return HomeSwitch(cli.User, targetHost)
	default:
		return fmt.Errorf("unknown command: %s", cli.Tag)
	}
}

func runNixos(cli Command, host string, current Platform) error {
	switch cli.Subcmd {
	case "build":
		return ExecTask(NixOSBuild, host, current)
	case "boot":
		return ExecTask(NixOSBoot, host, current)
	case "switch":
		return ExecTask(NixOSSwitch, host, current)
	default:
		return fmt.Errorf("unknown command: %s", cli.Tag)
	}
}

// runDarwin dispatches Darwin commands. The switch subcommand builds before
// switching, mirroring the Darwin branch of runSystem.
func runDarwin(cli Command, host string, current Platform) error {
	switch cli.Subcmd {
	case "build":
		return ExecTask(DarwinBuild, host, current)
	case "switch":
		if err := ExecTask(DarwinBuild, host, current); err != nil {
			return err
		}
		return ExecTask(DarwinSwitch, host, current)
	default:
		return fmt.Errorf("unknown command: %s", cli.Tag)
	}
}

func runNix(cli Command, host string, current Platform) error {
	switch cli.Subcmd {
	case "optimise":
		return ExecTask(NixOptimise, host, current)
	case "repair":
		return ExecTask(NixRepair, host, current)
	case "clean":
		return NixClean()
	default:
		return fmt.Errorf("unknown command: %s", cli.Tag)
	}
}

// runFlake dispatches flake management commands. Host-independent tasks
// (check, fmt) receive an empty host.
func runFlake(cli Command, current Platform) error {
	switch cli.Subcmd {
	case "check":
		return ExecTask(FlakeCheck, "", current)
	case "fmt":
		return ExecTask(FlakeFmt, "", current)
	case "update":
		return FlakeUpdate(cli.Name)
	default:
		return fmt.Errorf("unknown command: %s", cli.Tag)
	}
}
