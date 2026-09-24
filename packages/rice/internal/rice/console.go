package rice

import (
	"fmt"
	"io"
	"os"
	"strings"
)

// ANSI escape sequences for colored output.
const (
	green = "\x1b[1;32m"
	red   = "\x1b[1;31m"
	blue  = "\x1b[1;34m"
	dim   = "\x1b[2m"
	reset = "\x1b[0m"
)

// Stdout and Stderr are the output writers used by all console helpers.
// Tests may replace these with bytes.Buffer.
var (
	// Stdout is the writer for success and informational output. Replaced by tests.
	Stdout io.Writer = os.Stdout
	// Stderr is the writer for error output. Replaced by tests.
	Stderr io.Writer = os.Stderr
)

// OK prints a green checkmark and msg to w.
func OK(w io.Writer, msg string) {
	fmt.Fprintf(w, "%s✓%s %s\n", green, reset, msg)
}

// Err prints a red cross and msg to w.
func Err(w io.Writer, msg string) {
	fmt.Fprintf(w, "%s✗%s %s\n", red, reset, msg)
}

// Info prints a blue arrow and msg to w.
func Info(w io.Writer, msg string) {
	fmt.Fprintf(w, "%s→%s %s\n", blue, reset, msg)
}

// Preview prints cmd as a dimmed $ shell command line to w.
func Preview(w io.Writer, cmd []string) {
	fmt.Fprintf(w, "%s$ %s%s\n", dim, strings.Join(cmd, " "), reset)
}
