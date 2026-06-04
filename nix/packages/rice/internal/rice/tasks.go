package rice

// Platform represents a target operating system for task execution.
type Platform string

const (
	// PlatformAny matches any platform.
	PlatformAny Platform = ""
	// PlatformLinux targets Linux systems.
	PlatformLinux Platform = "linux"
	// PlatformDarwin targets macOS systems.
	PlatformDarwin Platform = "darwin"
)

// Task defines a single idempotent Nix management operation.
//
// Info is the human-readable description printed before execution.
// Info and Ok may contain "{host}" tokens which are substituted at runtime.
//
// Cmd is the command and arguments to execute.
//
// Ok is the success message printed after execution.
//
// Platform restricts execution to a specific OS, or PlatformAny for all.
type Task struct {
	Info     string
	Cmd      []string
	Ok       string
	Platform Platform
}

// Fixed task definitions. {host} tokens are substituted at execution time.
var (
	// DarwinBuild compiles the Darwin system configuration for {host}.
	DarwinBuild = Task{
		Info:     "Building Darwin for {host}...",
		Cmd:      []string{"nix", "build", ".#darwinConfigurations.{host}.system"},
		Ok:       "Darwin build complete",
		Platform: PlatformDarwin,
	}
	// DarwinSwitch activates a previously built Darwin system configuration.
	DarwinSwitch = Task{
		Info:     "Switching...",
		Cmd:      []string{"sudo", "./result/sw/bin/darwin-rebuild", "switch", "--flake", ".#{host}"},
		Ok:       "Darwin switch complete",
		Platform: PlatformDarwin,
	}
	// NixOSBuild compiles the NixOS system configuration.
	NixOSBuild = Task{
		Info:     "Building NixOS...",
		Cmd:      []string{"nixos-rebuild", "build", "--flake", ".#"},
		Ok:       "NixOS build complete",
		Platform: PlatformLinux,
	}
	// NixOSBoot sets the NixOS boot entry without switching.
	NixOSBoot = Task{
		Info:     "Setting boot...",
		Cmd:      []string{"nixos-rebuild", "boot", "--sudo", "--flake", ".#"},
		Ok:       "Boot set",
		Platform: PlatformLinux,
	}
	// NixOSSwitch builds and activates the NixOS system configuration.
	NixOSSwitch = Task{
		Info:     "Switching...",
		Cmd:      []string{"nixos-rebuild", "switch", "--sudo", "--flake", ".#"},
		Ok:       "NixOS switch complete",
		Platform: PlatformLinux,
	}
	// FlakeCheck runs nix flake check on the current flake.
	FlakeCheck = Task{
		Info: "Checking flake...",
		Cmd:  []string{"nix", "flake", "check", "."},
		Ok:   "Flake check passed",
	}
	// FlakeFmt runs pre-commit formatting checks on all files.
	FlakeFmt = Task{
		Info: "Formatting...",
		Cmd:  []string{"pre-commit", "run", "--all-files"},
		Ok:   "Format complete",
	}
	// NixOptimise runs nix store optimise to hard-link identical files.
	NixOptimise = Task{
		Info: "Optimizing nix store...",
		Cmd:  []string{"sudo", "nix", "store", "optimise"},
		Ok:   "Nix store optimized",
	}
	// NixRepair verifies and repairs the Nix store contents.
	NixRepair = Task{
		Info: "Repairing nix store...",
		Cmd:  []string{"sudo", "nix-store", "--verify", "--check-contents", "--repair"},
		Ok:   "Nix store repaired",
	}
)
