package main

import (
	"bytes"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"

	rice "liberion/rice/internal/rice"
)

// captureStdio redirects os.Stdout, os.Stderr, rice.Stdout, and rice.Stderr
// to pipes, runs fn, and returns the captured output plus the exit code.
func captureStdio(t *testing.T, fn func() int) (exitCode int, stdout, stderr string) {
	t.Helper()

	origOSOut := os.Stdout
	origOSErr := os.Stderr
	origRiceOut := rice.Stdout
	origRiceErr := rice.Stderr

	rOut, wOut, err := os.Pipe()
	if err != nil {
		t.Fatal(err)
	}
	rErr, wErr, err := os.Pipe()
	if err != nil {
		t.Fatal(err)
	}

	os.Stdout = wOut
	os.Stderr = wErr
	rice.Stdout = wOut
	rice.Stderr = wErr

	outCh := make(chan string, 1)
	errCh := make(chan string, 1)
	go func() {
		var buf bytes.Buffer
		_, _ = buf.ReadFrom(rOut)
		outCh <- buf.String()
	}()
	go func() {
		var buf bytes.Buffer
		_, _ = buf.ReadFrom(rErr)
		errCh <- buf.String()
	}()

	exitCode = fn()

	wOut.Close()
	wErr.Close()

	os.Stdout = origOSOut
	os.Stderr = origOSErr
	rice.Stdout = origRiceOut
	rice.Stderr = origRiceErr

	stdout = <-outCh
	stderr = <-errCh

	return exitCode, stdout, stderr
}

// makeFakeExec creates a shell script in t.TempDir()/bin/name that records
// each invocation's arguments to a calls file (one arg per line, blank-line
// separated) and exits 0.
func makeFakeExec(t *testing.T, name string) (binDir, callsFile string) {
	t.Helper()
	binDir = filepath.Join(t.TempDir(), "bin")
	if err := os.MkdirAll(binDir, 0o755); err != nil {
		t.Fatal(err)
	}
	callsFile = filepath.Join(binDir, name+".calls")
	script := "#!/bin/sh\n" +
		`for a in "$@"; do echo "$a" >> "` + callsFile + `"; done` + "\n" +
		`echo "" >> "` + callsFile + `"` + "\n" +
		"exit 0\n"
	if err := os.WriteFile(filepath.Join(binDir, name), []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}
	return binDir, callsFile
}

// readFakeCalls reads the calls log produced by makeFakeExec and returns
// the recorded arguments grouped by invocation.
func readFakeCalls(t *testing.T, callsFile string) [][]string {
	t.Helper()
	data, err := os.ReadFile(callsFile)
	if os.IsNotExist(err) {
		return nil
	}
	if err != nil {
		t.Fatal(err)
	}
	var calls [][]string
	var current []string
	for _, line := range strings.Split(strings.TrimSpace(string(data)), "\n") {
		if line == "" {
			if len(current) > 0 {
				calls = append(calls, current)
				current = nil
			}
		} else {
			current = append(current, line)
		}
	}
	if len(current) > 0 {
		calls = append(calls, current)
	}
	return calls
}

func TestMain_HelpExitsZero(t *testing.T) {
	exitCode, stdout, _ := captureStdio(t, func() int {
		return rice.Main([]string{})
	})
	if exitCode != 0 {
		t.Errorf("exit code = %d, want 0", exitCode)
	}
	if !strings.Contains(stdout, "Usage: rice <COMMAND>") {
		t.Errorf("stdout does not contain 'Usage: rice <COMMAND>':\n%s", stdout)
	}
}

func TestMain_HelpFlagExitsZero(t *testing.T) {
	exitCode, stdout, _ := captureStdio(t, func() int {
		return rice.Main([]string{"--help"})
	})
	if exitCode != 0 {
		t.Errorf("exit code = %d, want 0", exitCode)
	}
	if !strings.Contains(stdout, "Usage: rice <COMMAND>") {
		t.Errorf("stdout does not contain 'Usage: rice <COMMAND>':\n%s", stdout)
	}
}

func TestMain_UnknownCommandExitsOne(t *testing.T) {
	exitCode, _, stderr := captureStdio(t, func() int {
		return rice.Main([]string{"wat"})
	})
	if exitCode != 1 {
		t.Errorf("exit code = %d, want 1", exitCode)
	}
	if !strings.Contains(stderr, "unknown command: wat") {
		t.Errorf("stderr does not contain 'unknown command: wat':\n%s", stderr)
	}
}

func TestMain_ParserErrorPrintsUsage(t *testing.T) {
	_, _, stderr := captureStdio(t, func() int {
		return rice.Main([]string{"wat"})
	})
	if !strings.Contains(stderr, "Usage: rice <COMMAND>") {
		t.Errorf("stderr does not contain 'Usage: rice <COMMAND>':\n%s", stderr)
	}
}

func TestMain_PlatformRejection(t *testing.T) {
	binDir, _ := makeFakeExec(t, "nixos-rebuild")
	t.Setenv("PATH", binDir+":"+os.Getenv("PATH"))

	exitCode, _, stderr := captureStdio(t, func() int {
		return rice.Main([]string{"nixos", "build"})
	})

	// NixOSBuild has Platform: PlatformLinux. On darwin ExecTask returns
	// "Requires Linux"; on linux it proceeds to run nixos-rebuild.
	if runtime.GOOS == "darwin" {
		if exitCode != 1 {
			t.Errorf("exit code = %d, want 1", exitCode)
		}
		if !strings.Contains(stderr, "Requires Linux") {
			t.Errorf("stderr does not contain 'Requires Linux':\n%s", stderr)
		}
	} else if exitCode != 0 {
		t.Errorf("exit code = %d, want 0", exitCode)
	}
}

func TestMain_SuccessfulCommand(t *testing.T) {
	binDir, callsFile := makeFakeExec(t, "nix")
	t.Setenv("PATH", binDir+":"+os.Getenv("PATH"))

	exitCode, _, _ := captureStdio(t, func() int {
		return rice.Main([]string{"flake", "check"})
	})

	if exitCode != 0 {
		t.Errorf("exit code = %d, want 0", exitCode)
	}

	calls := readFakeCalls(t, callsFile)
	if len(calls) == 0 {
		t.Fatal("nix was not called")
	}
}

func TestMain_SuccessfulConsoleOutput(t *testing.T) {
	binDir, _ := makeFakeExec(t, "nix")
	t.Setenv("PATH", binDir+":"+os.Getenv("PATH"))

	_, stdout, _ := captureStdio(t, func() int {
		return rice.Main([]string{"flake", "check"})
	})

	if !strings.Contains(stdout, "Checking flake") {
		t.Errorf("stdout does not contain 'Checking flake':\n%s", stdout)
	}
	if !strings.Contains(stdout, "nix flake check .") {
		t.Errorf("stdout does not contain 'nix flake check .':\n%s", stdout)
	}
	if !strings.Contains(stdout, "Flake check passed") {
		t.Errorf("stdout does not contain 'Flake check passed':\n%s", stdout)
	}
}
