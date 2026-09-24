''
  layout {
      cwd "~/repos/rice"

      default_tab_template {
          children

          pane size=1 {
              plugin location="zellij:status-bar"
          }
      }

      pane_template name="mk_stacked_panes" {
          pane stacked=true {
              pane name="git" command="lazygit"

              pane name="nix[os] build" {
                  command "direnv"
                  args "exec" "." "just" "build"
                  start_suspended true
              }

              pane name="nix[os] switch" {
                  command "direnv"
                  args "exec" "." "just" "switch"
                  start_suspended true
              }

              pane name="scratch"
          }
      }

      /// TAB 1

      tab name="i" focus=true {
          pane split_direction="vertical" {
              pane name="main" command="nvim" {
                  args "flake.nix"

                  size "55%"
                  focus true
              }

              mk_stacked_panes
          }
      }
  }
''
