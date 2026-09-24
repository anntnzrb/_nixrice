package rice

import (
	"bytes"
	"strings"
	"testing"
)

func TestOK(t *testing.T) {
	tests := []struct {
		name string
		msg  string
	}{
		{name: "done", msg: "done"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var buf bytes.Buffer
			OK(&buf, tt.msg)
			got := buf.String()
			if !strings.Contains(got, "✓") {
				t.Errorf("OK(%q): expected output to contain ✓, got %q", tt.msg, got)
			}
			if !strings.Contains(got, tt.msg) {
				t.Errorf("OK(%q): expected output to contain %q, got %q", tt.msg, tt.msg, got)
			}
		})
	}
}

func TestErr(t *testing.T) {
	tests := []struct {
		name string
		msg  string
	}{
		{name: "boom", msg: "boom"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var buf bytes.Buffer
			Err(&buf, tt.msg)
			got := buf.String()
			if !strings.Contains(got, "✗") {
				t.Errorf("Err(%q): expected output to contain ✗, got %q", tt.msg, got)
			}
			if !strings.Contains(got, tt.msg) {
				t.Errorf("Err(%q): expected output to contain %q, got %q", tt.msg, tt.msg, got)
			}
		})
	}
}

func TestInfo(t *testing.T) {
	tests := []struct {
		name string
		msg  string
	}{
		{name: "heads up", msg: "heads up"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var buf bytes.Buffer
			Info(&buf, tt.msg)
			got := buf.String()
			if !strings.Contains(got, "→") {
				t.Errorf("Info(%q): expected output to contain →, got %q", tt.msg, got)
			}
			if !strings.Contains(got, tt.msg) {
				t.Errorf("Info(%q): expected output to contain %q, got %q", tt.msg, tt.msg, got)
			}
		})
	}
}

func TestPreview(t *testing.T) {
	tests := []struct {
		name string
		cmd  []string
		want string
	}{
		{name: "nix flake check .", cmd: []string{"nix", "flake", "check", "."}, want: "nix flake check ."},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var buf bytes.Buffer
			Preview(&buf, tt.cmd)
			got := buf.String()
			if !strings.Contains(got, "$") {
				t.Errorf("Preview(%v): expected output to contain $, got %q", tt.cmd, got)
			}
			if !strings.Contains(got, tt.want) {
				t.Errorf("Preview(%v): expected output to contain %q, got %q", tt.cmd, tt.want, got)
			}
		})
	}
}
