package rice

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// subHostCmd replaces every "{host}" token in each element of cmd.
func subHostCmd(cmd []string, host string) []string {
	out := make([]string, len(cmd))
	for i, s := range cmd {
		out[i] = strings.ReplaceAll(s, "{host}", host)
	}
	return out
}

// ExecTask runs a Task against the given host and validates platform compatibility.
//
//nolint:staticcheck // error messages capitalized for CLI consistency
func ExecTask(task Task, host string, current Platform) error {
	if task.Platform != PlatformAny && task.Platform != current {
		if task.Platform == PlatformDarwin {
			return errors.New("Requires macOS")
		}
		return errors.New("Requires Linux")
	}

	Info(Stdout, strings.ReplaceAll(task.Info, "{host}", host))

	cmd := subHostCmd(task.Cmd, host)
	if task.Sudo {
		cmd = append([]string{"sudo"}, cmd...)
	}

	Preview(Stdout, cmd)

	if err := RunCmd(cmd); err != nil {
		return err
	}

	OK(Stdout, task.Ok)
	return nil
}

// HomeBuild builds the home-manager activation package for user@host.
func HomeBuild(user, host string) error {
	Info(Stdout, fmt.Sprintf("Building home-manager for %s@%s...", user, host))

	cmd := []string{"nix", "build", fmt.Sprintf(".#homeConfigurations.%s@%s.activationPackage", user, host)}
	Preview(Stdout, cmd)

	if err := RunCmd(cmd); err != nil {
		return err
	}

	OK(Stdout, "Home-manager build complete")
	return nil
}

// HomeSwitch builds and activates the home-manager configuration.
func HomeSwitch(user, host string) error {
	if err := HomeBuild(user, host); err != nil {
		return err
	}

	Info(Stdout, "Activating home-manager...")

	cmd := []string{"./result/activate"}
	Preview(Stdout, cmd)

	if err := RunCmd(cmd); err != nil {
		return err
	}

	OK(Stdout, "Home-manager switch complete")
	return nil
}

// NixClean removes a cached nix directory (hardened) and runs nh clean.
func NixClean() error {
	home := os.Getenv("HOME")
	if home != "" {
		cachePath := filepath.Join(home, ".cache", "nix")
		cleanedCache := filepath.Clean(cachePath)
		cleanedHome := filepath.Clean(home)

		if strings.HasPrefix(cleanedCache, cleanedHome+string(filepath.Separator)) &&
			filepath.Base(filepath.Dir(cleanedCache)) == ".cache" &&
			filepath.Base(cleanedCache) == "nix" {
			_ = os.RemoveAll(cleanedCache)
		}
	}

	Info(Stdout, "Cleaning nix cache...")

	if err := RunCmd([]string{"nh", "clean", "all"}); err != nil {
		return err
	}

	if err := RunCmd([]string{"nh", "clean", "user"}); err != nil {
		return err
	}

	OK(Stdout, "Nix cleanup complete")
	return nil
}

// FlakeUpdate updates flake.lock, either all inputs or a single named input.
func FlakeUpdate(name string) error {
	if name == "all" {
		Info(Stdout, "Updating all flake inputs...")

		cmd := []string{
			"nix", "flake", "update",
			"--commit-lock-file",
			"--option", "commit-lockfile-summary",
			"chore(flake): update lockfile",
		}
		if err := RunCmd(cmd); err != nil {
			return err
		}

		OK(Stdout, "Flake update complete")
		return nil
	}

	Info(Stdout, fmt.Sprintf("Updating flake input: %s...", name))

	if err := RunCmd([]string{"nix", "flake", "update", name}); err != nil {
		return err
	}

	if err := RunCmd([]string{"git", "add", "flake.lock"}); err != nil {
		return err
	}

	if err := RunCmd([]string{"git", "commit", "-m", fmt.Sprintf("chore(flake): update input (%s)", name)}); err != nil {
		return err
	}

	OK(Stdout, "Flake update complete")
	return nil
}

// HostShortname returns the hostname up to the first dot, or "unknown".
func HostShortname() string {
	name, err := os.Hostname()
	if err != nil {
		return "unknown"
	}
	short, _, _ := strings.Cut(name, ".")
	if short == "" {
		return "unknown"
	}
	return short
}
