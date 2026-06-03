package rice

import (
	"strings"
	"testing"
)

func TestRunCmd(t *testing.T) {
	tests := []struct {
		name    string
		cmd     []string
		wantErr bool
		wantMsg string // substring the error must contain
	}{
		{
			name:    "empty command",
			cmd:     []string{},
			wantErr: true,
			wantMsg: "empty command",
		},
		{
			name:    "missing command",
			cmd:     []string{"__rice_missing_command__"},
			wantErr: true,
			wantMsg: "__rice_missing_command__",
		},
		{
			name:    "non-zero exit",
			cmd:     []string{"sh", "-c", "exit 7"},
			wantErr: true,
			wantMsg: "exit: 7",
		},
		{
			name:    "signal termination",
			cmd:     []string{"sh", "-c", "kill -TERM $$"},
			wantErr: true,
			wantMsg: "exit: -1",
		},
		{
			name:    "successful command",
			cmd:     []string{"true"},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := RunCmd(tt.cmd)
			if tt.wantErr {
				if err == nil {
					t.Fatalf("RunCmd(%v) returned nil, want error", tt.cmd)
				}
				if !strings.Contains(err.Error(), tt.wantMsg) {
					t.Errorf("RunCmd(%v) error = %q, want substring %q", tt.cmd, err.Error(), tt.wantMsg)
				}
			} else if err != nil {
				t.Errorf("RunCmd(%v) unexpected error: %v", tt.cmd, err)
			}
		})
	}
}
