package rice

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// RunCmd executes cmd as a subprocess with inherited stdio.
// It returns nil on success, or an error describing the failure.
func RunCmd(cmd []string) error {
	if len(cmd) == 0 {
		return errors.New("command failed: (empty command)")
	}
	//nolint:gosec // subprocess execution with user-provided argv is the intended behavior
	c := exec.CommandContext(context.Background(), cmd[0], cmd[1:]...)
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr

	if err := c.Run(); err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			return fmt.Errorf("command failed: %s (exit: %d)", joinCmd(cmd), exitErr.ExitCode())
		}
		return fmt.Errorf("command failed: %s: %w", joinCmd(cmd), err)
	}
	return nil
}

func joinCmd(cmd []string) string {
	return strings.Join(cmd, " ")
}
