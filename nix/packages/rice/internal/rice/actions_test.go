package rice

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// fakeTwoExecs creates two fake executables (a and b) in the same bin
// directory so they share a failure counter via the count file.
// Returns the calls files for a and b. Sets PATH to include the shared binDir.
func fakeTwoExecs(t *testing.T, a, b string) (aCalls, bCalls string) {
	t.Helper()

	binDir := filepath.Join(t.TempDir(), "bin")
	if err := os.MkdirAll(binDir, 0o755); err != nil {
		t.Fatal(err)
	}

	aCalls = filepath.Join(binDir, a+".calls")
	bCalls = filepath.Join(binDir, b+".calls")

	// Shared count file.
	countFile := filepath.Join(binDir, "count")

	tmpl := `#!/bin/sh
count_file="%s"
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
`
	scriptA := fmt.Sprintf(tmpl, countFile, aCalls, aCalls, aCalls)
	scriptB := fmt.Sprintf(tmpl, countFile, bCalls, bCalls, bCalls)

	if err := os.WriteFile(filepath.Join(binDir, a), []byte(scriptA), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(binDir, b), []byte(scriptB), 0o755); err != nil {
		t.Fatal(err)
	}

	t.Setenv("PATH", binDir+":"+os.Getenv("PATH"))
	return aCalls, bCalls
}

// silenceOutput redirects Stdout to io.Discard and returns a restore function.
func silenceOutput(t *testing.T) func() {
	t.Helper()
	orig := Stdout
	Stdout = io.Discard
	return func() { Stdout = orig }
}

// stripPIDs removes the leading PID element from each recorded call slice.
// The fake scripts echo $$ (the shell PID) as the first line of each record.
func stripPIDs(calls [][]string) [][]string {
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

// assertCall checks that calls contains a record matching want.
func assertCall(t *testing.T, calls [][]string, want []string) {
	t.Helper()
	cleaned := stripPIDs(calls)
	for _, call := range cleaned {
		if slicesEqual(call, want) {
			return
		}
	}
	t.Errorf("call %v not found in %v", want, cleaned)
}

// assertCallContains checks that any record in calls contains all elements of
// want in order (as a contiguous subsequence).
func assertCallContains(t *testing.T, calls [][]string, want []string) {
	t.Helper()
	cleaned := stripPIDs(calls)
	for _, call := range cleaned {
		if containsSub(call, want) {
			return
		}
	}
	t.Errorf("no call in %v contains subsequence %v", cleaned, want)
}

func slicesEqual(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

func containsSub(haystack, needle []string) bool {
	if len(needle) > len(haystack) {
		return false
	}
	for i := 0; i <= len(haystack)-len(needle); i++ {
		match := true
		for j := range needle {
			if haystack[i+j] != needle[j] {
				match = false
				break
			}
		}
		if match {
			return true
		}
	}
	return false
}

func TestHostShortname(t *testing.T) {
	name := HostShortname()
	if len(name) == 0 {
		t.Error("HostShortname returned empty string")
	}
	if strings.Contains(name, ".") {
		t.Errorf("HostShortname contains dot: %q", name)
	}
}

func TestExecTaskPlatformCheck(t *testing.T) {
	defer silenceOutput(t)()

	tests := []struct {
		name    string
		task    Task
		host    string
		current Platform
		want    string
	}{
		{
			name:    "DarwinBuild on Linux",
			task:    DarwinBuild,
			host:    "test",
			current: PlatformLinux,
			want:    "Requires macOS",
		},
		{
			name:    "NixOSBuild on Darwin",
			task:    NixOSBuild,
			host:    "test",
			current: PlatformDarwin,
			want:    "Requires Linux",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			defer silenceOutput(t)()
			err := ExecTask(tt.task, tt.host, tt.current)
			if err == nil {
				t.Fatal("expected error, got nil")
			}
			if !strings.Contains(err.Error(), tt.want) {
				t.Errorf("error %q does not contain %q", err.Error(), tt.want)
			}
		})
	}
}

func TestExecTaskFlakeCheck(t *testing.T) {
	defer silenceOutput(t)()

	_, callsFile := fakeExec(t, "nix")
	err := ExecTask(FlakeCheck, "", PlatformAny)
	if err != nil {
		t.Fatal(err)
	}

	calls := readCalls(t, callsFile)
	assertCall(t, calls, []string{"flake", "check", "."})
}

func TestExecTaskSudoPrefix(t *testing.T) {
	defer silenceOutput(t)()

	// NixOptimise includes "sudo" directly in its Cmd slice.
	_, sudoCalls := fakeExec(t, "sudo")
	_, _ = fakeExec(t, "nix") // also available on PATH but not directly invoked

	err := ExecTask(NixOptimise, "", PlatformAny)
	if err != nil {
		t.Fatal(err)
	}

	calls := readCalls(t, sudoCalls)
	assertCall(t, calls, []string{"nix", "store", "optimise"})
}

func TestExecTaskHostSubstitution(t *testing.T) {
	defer silenceOutput(t)()

	_, callsFile := fakeExec(t, "nix")
	err := ExecTask(DarwinBuild, "beirut", PlatformDarwin)
	if err != nil {
		t.Fatal(err)
	}

	calls := readCalls(t, callsFile)
	assertCallContains(t, calls, []string{".#darwinConfigurations.beirut.system"})
}

func TestHomeBuild(t *testing.T) {
	defer silenceOutput(t)()

	_, callsFile := fakeExec(t, "nix")
	err := HomeBuild("alice", "mbp")
	if err != nil {
		t.Fatal(err)
	}

	calls := readCalls(t, callsFile)
	assertCall(t, calls, []string{"build", ".#homeConfigurations.\"alice@mbp\".activationPackage"})
}

func TestHomeBuildFailure(t *testing.T) {
	defer silenceOutput(t)()

	t.Setenv("RICE_FAKE_FAIL_AT", "1")
	_, _ = fakeExec(t, "nix")

	err := HomeBuild("alice", "mbp")
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestEscapeNixString(t *testing.T) {
	got := escapeNixString(`a\b"c${d}`)
	want := `a\\b\"c\${d}`
	if got != want {
		t.Fatalf("escapeNixString() = %q, want %q", got, want)
	}
}

func TestHomeBuildEscapesNixAttr(t *testing.T) {
	defer silenceOutput(t)()

	_, callsFile := fakeExec(t, "nix")
	err := HomeBuild(`user"x`, `host${y}`)
	if err != nil {
		t.Fatal(err)
	}

	calls := readCalls(t, callsFile)
	assertCall(t, calls, []string{"build", `.#homeConfigurations."user\"x@host\${y}".activationPackage`})
}

func TestHomeSwitch(t *testing.T) {
	defer silenceOutput(t)()

	_, nixCalls := fakeExec(t, "nix")

	tmpDir := t.TempDir()

	// Create ./result/activate in tmpDir.
	activateDir := filepath.Join(tmpDir, "result")
	if err := os.MkdirAll(activateDir, 0o755); err != nil {
		t.Fatal(err)
	}

	activateCallsFile := filepath.Join(tmpDir, "activate.calls")
	activateScript := fmt.Sprintf(`#!/bin/sh
echo $$ >> "%s"
for arg in "$@"; do
  echo "$arg" >> "%s"
done
echo "" >> "%s"
exit 0
`, activateCallsFile, activateCallsFile, activateCallsFile)
	if err := os.WriteFile(filepath.Join(activateDir, "activate"), []byte(activateScript), 0o755); err != nil {
		t.Fatal(err)
	}

	origWd, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	if err := os.Chdir(tmpDir); err != nil {
		t.Fatal(err)
	}
	defer func() {
		if err := os.Chdir(origWd); err != nil {
			t.Errorf("failed to restore working directory: %v", err)
		}
	}()

	err = HomeSwitch("alice", "mbp")
	if err != nil {
		t.Fatal(err)
	}

	// Verify nix build call.
	nixCallsData := readCalls(t, nixCalls)
	assertCall(t, nixCallsData, []string{"build", ".#homeConfigurations.\"alice@mbp\".activationPackage"})

	// Verify activate call.
	actCallsData := readCalls(t, activateCallsFile)
	if len(actCallsData) < 1 {
		t.Fatal("expected at least one activate call")
	}
}

func TestHomeSwitchActivateFailure(t *testing.T) {
	defer silenceOutput(t)()

	_, _ = fakeExec(t, "nix") // build succeeds

	tmpDir := t.TempDir()

	activateDir := filepath.Join(tmpDir, "result")
	if err := os.MkdirAll(activateDir, 0o755); err != nil {
		t.Fatal(err)
	}

	// Failing activate script.
	activateScript := "#!/bin/sh\nexit 1\n"
	if err := os.WriteFile(filepath.Join(activateDir, "activate"), []byte(activateScript), 0o755); err != nil {
		t.Fatal(err)
	}

	origWd, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	if err := os.Chdir(tmpDir); err != nil {
		t.Fatal(err)
	}
	defer func() {
		if err := os.Chdir(origWd); err != nil {
			t.Errorf("failed to restore working directory: %v", err)
		}
	}()

	err = HomeSwitch("alice", "mbp")
	if err == nil {
		t.Fatal("expected error from failing activate, got nil")
	}
}

func TestHomeSwitchBuildFailureShortCircuits(t *testing.T) {
	defer silenceOutput(t)()
	_, nixCallsFile := fakeExec(t, "nix")
	t.Setenv("RICE_FAKE_FAIL_AT", "1") // fail nix build

	err := HomeSwitch("alice", "mbp")
	if err == nil {
		t.Fatal("expected error, got nil")
	}

	calls := readCalls(t, nixCallsFile)
	if len(calls) != 1 {
		t.Fatalf("expected exactly 1 nix build call, got %d", len(calls))
	}
	assertCall(t, calls, []string{"build", `.#homeConfigurations."alice@mbp".activationPackage`})
}

func TestNixClean(t *testing.T) {
	defer silenceOutput(t)()

	homeDir := filepath.Join(t.TempDir(), "home")
	if err := os.MkdirAll(homeDir, 0o755); err != nil {
		t.Fatal(err)
	}

	// Create .cache/nix under HOME.
	cacheDir := filepath.Join(homeDir, ".cache", "nix")
	if err := os.MkdirAll(cacheDir, 0o755); err != nil {
		t.Fatal(err)
	}
	// Put a file in the cache to verify it gets removed.
	dummyFile := filepath.Join(cacheDir, "dummy")
	if err := os.WriteFile(dummyFile, []byte("data"), 0o644); err != nil {
		t.Fatal(err)
	}

	t.Setenv("HOME", homeDir)

	_, nhCalls := fakeExec(t, "nh")

	err := NixClean()
	if err != nil {
		t.Fatal(err)
	}

	// Cache directory should be removed.
	if _, err := os.Stat(cacheDir); !os.IsNotExist(err) {
		t.Error("expected .cache/nix to be removed, but it still exists")
	}

	calls := readCalls(t, nhCalls)
	assertCall(t, calls, []string{"clean", "all"})
	assertCall(t, calls, []string{"clean", "user"})

}
func TestNixCleanUnsetHome(t *testing.T) {
	defer silenceOutput(t)()
	t.Setenv("HOME", "")

	_, _ = fakeExec(t, "nh")

	// Must not panic.
	err := NixClean()
	if err != nil {
		t.Fatal(err)
	}
}

func TestNixCleanRelativeHome(t *testing.T) {
	defer silenceOutput(t)()

	tmpDir := t.TempDir()
	cacheDir := filepath.Join(tmpDir, "relative", "home", ".cache", "nix")
	if err := os.MkdirAll(cacheDir, 0o755); err != nil {
		t.Fatal(err)
	}
	sentinel := filepath.Join(cacheDir, "keep")
	if err := os.WriteFile(sentinel, []byte("keep"), 0o644); err != nil {
		t.Fatal(err)
	}

	origWd, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	if err := os.Chdir(tmpDir); err != nil {
		t.Fatal(err)
	}
	defer func() {
		if err := os.Chdir(origWd); err != nil {
			t.Errorf("failed to restore working directory: %v", err)
		}
	}()

	t.Setenv("HOME", "relative/home")
	_, _ = fakeExec(t, "nh")

	if err := NixClean(); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(sentinel); err != nil {
		t.Fatalf("relative HOME cache was removed or made inaccessible: %v", err)
	}
}

func TestNixCleanFirstNhFailure(t *testing.T) {
	defer silenceOutput(t)()

	t.Setenv("RICE_FAKE_FAIL_AT", "1")
	_, nhCalls := fakeExec(t, "nh")

	err := NixClean()
	if err == nil {
		t.Fatal("expected error, got nil")
	}

	calls := readCalls(t, nhCalls)
	if len(calls) > 1 {
		t.Error("expected only one nh call (first failed), got more")
	}
}

func TestNixCleanSecondNhFailure(t *testing.T) {
	defer silenceOutput(t)()

	t.Setenv("RICE_FAKE_FAIL_AT", "2")
	_, nhCalls := fakeExec(t, "nh")

	err := NixClean()
	if err == nil {
		t.Fatal("expected error, got nil")
	}

	calls := readCalls(t, nhCalls)
	// First nh should have run (and succeeded).
	assertCall(t, calls, []string{"clean", "all"})
	// Second nh should also have run (and failed).
	assertCall(t, calls, []string{"clean", "user"})
}

func TestNixCleanSentinelSurvives(t *testing.T) {
	defer silenceOutput(t)()

	homeDir := filepath.Join(t.TempDir(), "home")
	if err := os.MkdirAll(homeDir, 0o755); err != nil {
		t.Fatal(err)
	}

	// Place a sentinel file directly in HOME (not inside .cache/nix).
	sentinel := filepath.Join(homeDir, "keep-me.txt")
	if err := os.WriteFile(sentinel, []byte("do not delete"), 0o644); err != nil {
		t.Fatal(err)
	}

	t.Setenv("HOME", homeDir)
	_, _ = fakeExec(t, "nh")

	err := NixClean()
	if err != nil {
		t.Fatal(err)
	}

	// Sentinel must survive.
	if _, err := os.Stat(sentinel); os.IsNotExist(err) {
		t.Error("sentinel file outside .cache/nix was deleted")
	}
}

func TestFlakeUpdateAll(t *testing.T) {
	defer silenceOutput(t)()

	_, nixCalls := fakeExec(t, "nix")

	err := FlakeUpdate("all")
	if err != nil {
		t.Fatal(err)
	}

	calls := readCalls(t, nixCalls)
	assertCallContains(t, calls, []string{"--commit-lock-file"})
}

func TestFlakeUpdateNamed(t *testing.T) {
	defer silenceOutput(t)()

	_, nixCalls := fakeExec(t, "nix")
	_, gitCalls := fakeExec(t, "git")

	err := FlakeUpdate("fenix")
	if err != nil {
		t.Fatal(err)
	}

	nixCallsData := readCalls(t, nixCalls)
	assertCall(t, nixCallsData, []string{"flake", "update", "fenix"})

	gitCallsData := readCalls(t, gitCalls)
	assertCall(t, gitCallsData, []string{"add", "flake.lock"})
	assertCall(t, gitCallsData, []string{"commit", "-m", "chore(flake): update input (fenix)"})
}

func TestFlakeUpdateAllFailure(t *testing.T) {
	defer silenceOutput(t)()

	t.Setenv("RICE_FAKE_FAIL_AT", "1")
	_, _ = fakeExec(t, "nix")

	err := FlakeUpdate("all")
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestFlakeUpdateNamedFailureGitAdd(t *testing.T) {
	defer silenceOutput(t)()

	// Use shared counter: invocation 1 = nix, invocation 2 = git add.
	t.Setenv("RICE_FAKE_FAIL_AT", "2")
	nixCalls, gitCalls := fakeTwoExecs(t, "nix", "git")

	err := FlakeUpdate("fenix")
	if err == nil {
		t.Fatal("expected error, got nil")
	}

	// nix should have succeeded (invocation 1 != 2).
	nixCallsData := readCalls(t, nixCalls)
	assertCall(t, nixCallsData, []string{"flake", "update", "fenix"})

	// git add should have failed (invocation 2 == 2).
	gitCallsData := readCalls(t, gitCalls)
	// Only one git call (add), commit should not have been reached.
	if len(stripPIDs(gitCallsData)) > 1 {
		t.Error("expected at most one git call, git commit should not have been called")
	}
}

func TestFlakeUpdateNamedFailureGitCommit(t *testing.T) {
	defer silenceOutput(t)()

	// Use shared counter: invocation 1 = nix, 2 = git add, 3 = git commit.
	t.Setenv("RICE_FAKE_FAIL_AT", "3")
	nixCalls, gitCalls := fakeTwoExecs(t, "nix", "git")

	err := FlakeUpdate("fenix")
	if err == nil {
		t.Fatal("expected error, got nil")
	}

	// All three commands should have run.
	nixCallsData := readCalls(t, nixCalls)
	assertCall(t, nixCallsData, []string{"flake", "update", "fenix"})

	gitCallsData := readCalls(t, gitCalls)
	assertCall(t, gitCallsData, []string{"add", "flake.lock"})
	assertCall(t, gitCallsData, []string{"commit", "-m", "chore(flake): update input (fenix)"})
}
