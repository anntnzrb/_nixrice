package rice

// Platform represents the target operating system for a task.
type Platform string

const (
	PlatformAny    Platform = ""
	PlatformLinux  Platform = "linux"
	PlatformDarwin Platform = "darwin"
)

// Task defines a single idempotent Nix management operation.
type Task struct {
	Info     string
	Cmd      []string
	Ok       string
	Sudo     bool
	Platform Platform
}

// Fixed task definitions. {host} tokens are substituted at execution time.
var (
	DarwinBuild = Task{
		Info:     "Building Darwin for {host}...",
		Cmd:      []string{"nix", "build", ".#darwinConfigurations.{host}.system"},
		Ok:       "Darwin build complete",
		Sudo:     false,
		Platform: PlatformDarwin,
	}
	DarwinSwitch = Task{
		Info:     "Switching...",
		Cmd:      []string{"./result/sw/bin/darwin-rebuild", "switch", "--flake", ".#{host}"},
		Ok:       "Darwin switch complete",
		Sudo:     true,
		Platform: PlatformDarwin,
	}
	NixOSBuild = Task{
		Info:     "Building NixOS...",
		Cmd:      []string{"nixos-rebuild", "build", "--flake", ".#"},
		Ok:       "NixOS build complete",
		Sudo:     false,
		Platform: PlatformLinux,
	}
	NixOSBoot = Task{
		Info:     "Setting boot...",
		Cmd:      []string{"nixos-rebuild", "boot", "--sudo", "--flake", ".#"},
		Ok:       "Boot set",
		Sudo:     false,
		Platform: PlatformLinux,
	}
	NixOSSwitch = Task{
		Info:     "Switching...",
		Cmd:      []string{"nixos-rebuild", "switch", "--sudo", "--flake", ".#"},
		Ok:       "NixOS switch complete",
		Sudo:     false,
		Platform: PlatformLinux,
	}
	FlakeCheck = Task{
		Info: "Checking flake...",
		Cmd:  []string{"nix", "flake", "check", "."},
		Ok:   "Flake check passed",
		Sudo: false,
	}
	FlakeFmt = Task{
		Info: "Formatting...",
		Cmd:  []string{"pre-commit", "run", "--all-files"},
		Ok:   "Format complete",
		Sudo: false,
	}
	NixOptimise = Task{
		Info: "Optimizing nix store...",
		Cmd:  []string{"nix", "store", "optimise"},
		Ok:   "Nix store optimized",
		Sudo: true,
	}
	NixRepair = Task{
		Info: "Repairing nix store...",
		Cmd:  []string{"nix-store", "--verify", "--check-contents", "--repair"},
		Ok:   "Nix store repaired",
		Sudo: true,
	}
)
