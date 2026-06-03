package rice

import (
	"fmt"
	"os"
	"path/filepath"
	"testing"
)

// fakeExec writes a shell script to t.TempDir()/bin/name that records its
// arguments and either succeeds or fails based on env vars.
//
// The script logs every invocation to callsFile with one line per arg,
// separated by blank-line records. If RICE_FAKE_FAIL_AT is set to N, the
// Nth invocation exits non-zero. RICE_FAKE_STATUS overrides the exit code
// (default 1).
//
// Returns the directory prepended to PATH and the calls log path.
func fakeExec(t *testing.T, name string) (binDir, callsFile string) {
	t.Helper()

	binDir = filepath.Join(t.TempDir(), "bin")
	if err := os.MkdirAll(binDir, 0o755); err != nil {
		t.Fatal(err)
	}

	callsFile = filepath.Join(binDir, name+".calls")

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

	t.Setenv("PATH", binDir+":"+os.Getenv("PATH"))
	return binDir, callsFile
}

// readCalls reads the fake-exec calls log and returns the recorded
// arguments grouped by invocation (one []string per call).
func readCalls(t *testing.T, callsFile string) [][]string {
	t.Helper()

	data, err := os.ReadFile(callsFile)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		t.Fatal(err)
	}

	var calls [][]string
	var current []string
	lines := splitLines(string(data))
	for _, line := range lines {
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

func splitLines(s string) []string {
	var lines []string
	start := 0
	for i := 0; i < len(s); i++ {
		if s[i] == '\n' {
			lines = append(lines, s[start:i])
			start = i + 1
		}
	}
	if start < len(s) {
		lines = append(lines, s[start:])
	}
	return lines
}
