package rice

import (
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

// --- helpers ---

// stripPID removes the PID (first element) from each recorded call.
// fakeExec records $$ as the first line of every invocation.
func stripPID(calls [][]string) [][]string {
	out := make([][]string, len(calls))
	for i, call := range calls {
		if len(call) > 0 {
			out[i] = call[1:]
		} else {
			out[i] = call
		}
	}
	return out
}

// makeRecordingFake creates a fake executable in binDir that records its
// arguments to callsFile (one arg per line, blank-line separated) and exits 0,
// using the same script template as fakeExec.  Returns the calls file path.
func makeRecordingFake(t *testing.T, binDir, name string) string {
	t.Helper()
	callsFile := filepath.Join(binDir, name+".calls")
	script := fmt.Sprintf(`#!/bin/sh
count_file="%s/count"
echo $$ >> "%s"
for arg in "$@"; do
  echo "$arg" >> "%s"
done
echo "" >> "%s"

if [ -n "${RICE_FAKE_FAIL_AT:-}" ]; then
  n=$(cat "$count_file" 2>/dev/null || echo 0)
  n=$((n + 1))
  echo "$n" > "$count_file"
  if [ "$n" -eq "${RICE_FAKE_FAIL_AT}" ]; then
    exit "${RICE_FAKE_STATUS:-1}"
  fi
fi
exit 0
`, binDir, callsFile, callsFile, callsFile)
	path := filepath.Join(binDir, name)
	if err := os.WriteFile(path, []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}
	return callsFile
}

// makePassthroughSudo creates a fake "sudo" in binDir that execs its
// arguments (passthrough), preserving argv recording in the inner tool.
func makePassthroughSudo(t *testing.T, binDir string) {
	t.Helper()
	script := "#!/bin/sh\nexec \"$@\"\n"
	path := filepath.Join(binDir, "sudo")
	if err := os.WriteFile(path, []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}
}

// assertCalls fails the test if stripped calls don't match want.
func assertCalls(t *testing.T, calls [][]string, want [][]string) {
	t.Helper()
	if !reflect.DeepEqual(calls, want) {
		t.Errorf("calls = %v, want %v", calls, want)
	}
}

// assertCallCount fails the test if the number of calls doesn't match.
func assertCallCount(t *testing.T, calls [][]string, want int) {
	t.Helper()
	if len(calls) != want {
		t.Errorf("got %d calls, want %d: %v", len(calls), want, calls)
	}
}

// assertError fails if err is nil, or if err's message doesn't contain want.
func assertError(t *testing.T, err error, want string) {
	t.Helper()
	if err == nil {
		t.Fatal("expected error, got nil")
	}
	if !strings.Contains(err.Error(), want) {
		t.Errorf("error %q does not contain %q", err.Error(), want)
	}
}

// --- CurrentPlatform ---

func TestCurrentPlatform(t *testing.T) {
	p := CurrentPlatform()
	if p == PlatformAny {
		t.Errorf("CurrentPlatform() = %q, must not be PlatformAny", p)
	}
	if p != PlatformDarwin && p != PlatformLinux {
		t.Errorf("CurrentPlatform() = %q, want PlatformDarwin or PlatformLinux", p)
	}
}

// --- RunCLI: command routing ---

func TestRunCLI_SystemBuild_Linux(t *testing.T) {
	_, callsFile := fakeExec(t, "nixos-rebuild")
	cmd := Command{Tag: "system", Subcmd: "build"}
	err := RunCLI(cmd, "zadar", PlatformLinux)
	if err != nil {
		t.Fatal(err)
	}
	calls := stripPID(readCalls(t, callsFile))
	assertCallCount(t, calls, 1)
	assertCalls(t, calls, [][]string{{"build", "--flake", ".#"}})
}

func TestRunCLI_SystemBuild_Darwin(t *testing.T) {
	_, callsFile := fakeExec(t, "nix")
	cmd := Command{Tag: "system", Subcmd: "build"}
	err := RunCLI(cmd, "beirut", PlatformDarwin)
	if err != nil {
		t.Fatal(err)
	}
	calls := stripPID(readCalls(t, callsFile))
	assertCallCount(t, calls, 1)
	assertCalls(t, calls, [][]string{{"build", ".#darwinConfigurations.beirut.system"}})
}

func TestRunCLI_SystemSwitch_Linux(t *testing.T) {
	_, callsFile := fakeExec(t, "nixos-rebuild")
	cmd := Command{Tag: "system", Subcmd: "switch"}
	err := RunCLI(cmd, "zadar", PlatformLinux)
	if err != nil {
		t.Fatal(err)
	}
	calls := stripPID(readCalls(t, callsFile))
	assertCallCount(t, calls, 2)
	assertCalls(t, calls, [][]string{
		{"build", "--flake", ".#"},
		{"switch", "--sudo", "--flake", ".#"},
	})
}

func TestRunCLI_SystemSwitch_Darwin(t *testing.T) {
	td := t.TempDir()

	binDir := filepath.Join(td, "bin")
	if err := os.MkdirAll(binDir, 0o755); err != nil {
		t.Fatal(err)
	}
	nixCalls := makeRecordingFake(t, binDir, "nix")
	makePassthroughSudo(t, binDir)

	// darwin-rebuild is a relative path; create it under ./result/sw/bin/
	rebuildDir := filepath.Join(td, "result", "sw", "bin")
	if err := os.MkdirAll(rebuildDir, 0o755); err != nil {
		t.Fatal(err)
	}
	rebuildCalls := makeRecordingFake(t, rebuildDir, "darwin-rebuild")

	// chdir to the temp dir so ./result/sw/bin/darwin-rebuild resolves
	origDir, _ := os.Getwd()
	if err := os.Chdir(td); err != nil {
		t.Fatal(err)
	}
	defer os.Chdir(origDir) //nolint:errcheck

	t.Setenv("PATH", binDir+":"+os.Getenv("PATH"))

	cmd := Command{Tag: "system", Subcmd: "switch"}
	err := RunCLI(cmd, "beirut", PlatformDarwin)
	if err != nil {
		t.Fatal(err)
	}

	nixCallsStripped := stripPID(readCalls(t, nixCalls))
	assertCallCount(t, nixCallsStripped, 1)
	assertCalls(t, nixCallsStripped, [][]string{{"build", ".#darwinConfigurations.beirut.system"}})

	rebuildStripped := stripPID(readCalls(t, rebuildCalls))
	assertCallCount(t, rebuildStripped, 1)
	assertCalls(t, rebuildStripped, [][]string{{"switch", "--flake", ".#beirut"}})
}

func TestRunCLI_NixOSBuild(t *testing.T) {
	_, callsFile := fakeExec(t, "nixos-rebuild")
	cmd := Command{Tag: "nixos", Subcmd: "build"}
	err := RunCLI(cmd, "zadar", PlatformLinux)
	if err != nil {
		t.Fatal(err)
	}
	calls := stripPID(readCalls(t, callsFile))
	assertCallCount(t, calls, 1)
	assertCalls(t, calls, [][]string{{"build", "--flake", ".#"}})
}

func TestRunCLI_NixOSBoot(t *testing.T) {
	_, callsFile := fakeExec(t, "nixos-rebuild")
	cmd := Command{Tag: "nixos", Subcmd: "boot"}
	err := RunCLI(cmd, "zadar", PlatformLinux)
	if err != nil {
		t.Fatal(err)
	}
	calls := stripPID(readCalls(t, callsFile))
	assertCallCount(t, calls, 1)
	assertCalls(t, calls, [][]string{{"boot", "--sudo", "--flake", ".#"}})
}

func TestRunCLI_NixOSSwitch(t *testing.T) {
	_, callsFile := fakeExec(t, "nixos-rebuild")
	cmd := Command{Tag: "nixos", Subcmd: "switch"}
	err := RunCLI(cmd, "zadar", PlatformLinux)
	if err != nil {
		t.Fatal(err)
	}
	calls := stripPID(readCalls(t, callsFile))
	assertCallCount(t, calls, 1)
	assertCalls(t, calls, [][]string{{"switch", "--sudo", "--flake", ".#"}})
}

func TestRunCLI_DarwinBuild(t *testing.T) {
	_, callsFile := fakeExec(t, "nix")
	cmd := Command{Tag: "darwin", Subcmd: "build"}
	err := RunCLI(cmd, "beirut", PlatformDarwin)
	if err != nil {
		t.Fatal(err)
	}
	calls := stripPID(readCalls(t, callsFile))
	assertCallCount(t, calls, 1)
	assertCalls(t, calls, [][]string{{"build", ".#darwinConfigurations.beirut.system"}})
}

func TestRunCLI_DarwinSwitch(t *testing.T) {
	td := t.TempDir()

	binDir := filepath.Join(td, "bin")
	if err := os.MkdirAll(binDir, 0o755); err != nil {
		t.Fatal(err)
	}
	makePassthroughSudo(t, binDir)

	rebuildDir := filepath.Join(td, "result", "sw", "bin")
	if err := os.MkdirAll(rebuildDir, 0o755); err != nil {
		t.Fatal(err)
	}
	rebuildCalls := makeRecordingFake(t, rebuildDir, "darwin-rebuild")

	origDir, _ := os.Getwd()
	if err := os.Chdir(td); err != nil {
		t.Fatal(err)
	}
	defer os.Chdir(origDir) //nolint:errcheck

	t.Setenv("PATH", binDir+":"+os.Getenv("PATH"))

	cmd := Command{Tag: "darwin", Subcmd: "switch"}
	err := RunCLI(cmd, "beirut", PlatformDarwin)
	if err != nil {
		t.Fatal(err)
	}

	rebuildStripped := stripPID(readCalls(t, rebuildCalls))
	assertCallCount(t, rebuildStripped, 1)
	assertCalls(t, rebuildStripped, [][]string{{"switch", "--flake", ".#beirut"}})
}

func TestRunCLI_NixOptimise(t *testing.T) {
	td := t.TempDir()
	binDir := filepath.Join(td, "bin")
	if err := os.MkdirAll(binDir, 0o755); err != nil {
		t.Fatal(err)
	}
	nixCalls := makeRecordingFake(t, binDir, "nix")
	makePassthroughSudo(t, binDir)
	t.Setenv("PATH", binDir+":"+os.Getenv("PATH"))

	cmd := Command{Tag: "nix", Subcmd: "optimise"}
	err := RunCLI(cmd, "ignored", PlatformLinux)
	if err != nil {
		t.Fatal(err)
	}

	calls := stripPID(readCalls(t, nixCalls))
	assertCallCount(t, calls, 1)
	assertCalls(t, calls, [][]string{{"store", "optimise"}})
}

func TestRunCLI_NixRepair(t *testing.T) {
	td := t.TempDir()
	binDir := filepath.Join(td, "bin")
	if err := os.MkdirAll(binDir, 0o755); err != nil {
		t.Fatal(err)
	}
	callsFile := makeRecordingFake(t, binDir, "nix-store")
	makePassthroughSudo(t, binDir)
	t.Setenv("PATH", binDir+":"+os.Getenv("PATH"))

	cmd := Command{Tag: "nix", Subcmd: "repair"}
	err := RunCLI(cmd, "ignored", PlatformLinux)
	if err != nil {
		t.Fatal(err)
	}

	calls := stripPID(readCalls(t, callsFile))
	assertCallCount(t, calls, 1)
	assertCalls(t, calls, [][]string{{"--verify", "--check-contents", "--repair"}})
}

func TestRunCLI_NixClean(t *testing.T) {
	_, callsFile := fakeExec(t, "nh")
	cmd := Command{Tag: "nix", Subcmd: "clean"}
	err := RunCLI(cmd, "ignored", PlatformLinux)
	if err != nil {
		t.Fatal(err)
	}

	calls := stripPID(readCalls(t, callsFile))
	assertCallCount(t, calls, 2)
	assertCalls(t, calls, [][]string{
		{"clean", "all"},
		{"clean", "user"},
	})
}

func TestRunCLI_FlakeCheck(t *testing.T) {
	_, callsFile := fakeExec(t, "nix")
	cmd := Command{Tag: "flake", Subcmd: "check"}
	err := RunCLI(cmd, "ignored", PlatformLinux)
	if err != nil {
		t.Fatal(err)
	}

	calls := stripPID(readCalls(t, callsFile))
	assertCallCount(t, calls, 1)
	assertCalls(t, calls, [][]string{{"flake", "check", "."}})
}

func TestRunCLI_FlakeFmt(t *testing.T) {
	_, callsFile := fakeExec(t, "pre-commit")
	cmd := Command{Tag: "flake", Subcmd: "fmt"}
	err := RunCLI(cmd, "ignored", PlatformLinux)
	if err != nil {
		t.Fatal(err)
	}

	calls := stripPID(readCalls(t, callsFile))
	assertCallCount(t, calls, 1)
	assertCalls(t, calls, [][]string{{"run", "--all-files"}})
}

func TestRunCLI_FlakeUpdateAll(t *testing.T) {
	_, callsFile := fakeExec(t, "nix")
	cmd := Command{Tag: "flake", Subcmd: "update", Name: "all"}
	err := RunCLI(cmd, "ignored", PlatformLinux)
	if err != nil {
		t.Fatal(err)
	}

	calls := stripPID(readCalls(t, callsFile))
	assertCallCount(t, calls, 1)

	// The args must contain "--commit-lock-file".
	found := false
	for _, arg := range calls[0] {
		if arg == "--commit-lock-file" {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("args do not contain --commit-lock-file: %v", calls[0])
	}
}

func TestRunCLI_FlakeUpdateNamed(t *testing.T) {
	td := t.TempDir()
	binDir := filepath.Join(td, "bin")
	if err := os.MkdirAll(binDir, 0o755); err != nil {
		t.Fatal(err)
	}
	nixCalls := makeRecordingFake(t, binDir, "nix")
	gitCalls := makeRecordingFake(t, binDir, "git")
	t.Setenv("PATH", binDir+":"+os.Getenv("PATH"))

	cmd := Command{Tag: "flake", Subcmd: "update", Name: "fenix"}
	err := RunCLI(cmd, "ignored", PlatformLinux)
	if err != nil {
		t.Fatal(err)
	}

	nixStripped := stripPID(readCalls(t, nixCalls))
	assertCallCount(t, nixStripped, 1)
	assertCalls(t, nixStripped, [][]string{{"flake", "update", "fenix"}})

	gitStripped := stripPID(readCalls(t, gitCalls))
	assertCallCount(t, gitStripped, 2)
	assertCalls(t, gitStripped, [][]string{
		{"add", "flake.lock"},
		{"commit", "-m", "chore(flake): update input (fenix)"},
	})
}

// --- platform rejection ---

func TestRunCLI_DarwinBuildOnLinux(t *testing.T) {
	// Create a fake nix — it should never be called.
	_, callsFile := fakeExec(t, "nix")
	cmd := Command{Tag: "darwin", Subcmd: "build"}
	err := RunCLI(cmd, "zadar", PlatformLinux)
	assertError(t, err, "Requires macOS")

	calls := readCalls(t, callsFile)
	assertCallCount(t, calls, 0)
}

func TestRunCLI_NixOSBuildOnDarwin(t *testing.T) {
	_, callsFile := fakeExec(t, "nixos-rebuild")
	cmd := Command{Tag: "nixos", Subcmd: "build"}
	err := RunCLI(cmd, "beirut", PlatformDarwin)
	assertError(t, err, "Requires Linux")

	calls := readCalls(t, callsFile)
	assertCallCount(t, calls, 0)
}

// --- home host defaulting ---

func TestRunCLI_HomeBuildDefaultHost(t *testing.T) {
	_, callsFile := fakeExec(t, "nix")
	cmd := Command{Tag: "home", Subcmd: "build", User: "alice", HasHost: false}
	err := RunCLI(cmd, "beirut", PlatformDarwin)
	if err != nil {
		t.Fatal(err)
	}

	calls := stripPID(readCalls(t, callsFile))
	assertCallCount(t, calls, 1)
	if len(calls[0]) < 2 || !strings.Contains(calls[0][1], "alice@beirut") {
		t.Errorf("expected home build with host 'beirut', got %v", calls[0])
	}
}

func TestRunCLI_HomeBuildExplicitHost(t *testing.T) {
	_, callsFile := fakeExec(t, "nix")
	cmd := Command{Tag: "home", Subcmd: "build", User: "alice", Host: "mbp", HasHost: true}
	err := RunCLI(cmd, "beirut", PlatformDarwin)
	if err != nil {
		t.Fatal(err)
	}

	calls := stripPID(readCalls(t, callsFile))
	assertCallCount(t, calls, 1)
	if len(calls[0]) < 2 || !strings.Contains(calls[0][1], "alice@mbp") {
		t.Errorf("expected home build with host 'mbp', got %v", calls[0])
	}
}

// --- system switch short-circuit on first-step failure ---

func TestRunCLI_SystemSwitch_Darwin_ShortCircuit(t *testing.T) {
	td := t.TempDir()
	binDir := filepath.Join(td, "bin")
	if err := os.MkdirAll(binDir, 0o755); err != nil {
		t.Fatal(err)
	}
	nixCalls := makeRecordingFake(t, binDir, "nix")
	makePassthroughSudo(t, binDir)
	t.Setenv("PATH", binDir+":"+os.Getenv("PATH"))
	t.Setenv("RICE_FAKE_FAIL_AT", "1")

	cmd := Command{Tag: "system", Subcmd: "switch"}
	err := RunCLI(cmd, "beirut", PlatformDarwin)
	assertError(t, err, "command failed")

	calls := stripPID(readCalls(t, nixCalls))
	assertCallCount(t, calls, 1)
	// Only the build step ran; no switch step.
}

func TestRunCLI_SystemSwitch_Linux_ShortCircuit(t *testing.T) {
	_, callsFile := fakeExec(t, "nixos-rebuild")
	t.Setenv("RICE_FAKE_FAIL_AT", "1")

	cmd := Command{Tag: "system", Subcmd: "switch"}
	err := RunCLI(cmd, "zadar", PlatformLinux)
	assertError(t, err, "command failed")

	calls := stripPID(readCalls(t, callsFile))
	assertCallCount(t, calls, 1)
}
