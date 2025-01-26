# kdl
''
  keybinds clear-defaults=true {
      locked {
          bind "Ctrl b" { SwitchToMode "normal"; }
      }

      // ----------------------------------------------------------------------
      // pane
      // ----------------------------------------------------------------------
      pane {
          /// navigation
          // arrows
          bind "up"    { MoveFocus "up"; }
          bind "right" { MoveFocus "right"; }
          bind "down"  { MoveFocus "down"; }
          bind "left"  { MoveFocus "left"; }

          // vi
          bind "k" { MoveFocus "up"; }
          bind "l" { MoveFocus "right"; }
          bind "j" { MoveFocus "down"; }
          bind "h" { MoveFocus "left"; }

          bind "tab" { SwitchFocus; }

          /// creation
          bind "\"" { NewPane "down"; SwitchToMode "locked"; }
          bind "%"  { NewPane "right"; SwitchToMode "locked"; }

          /// modification
          bind "c" { SwitchToMode "renamepane"; PaneNameInput 0; }
          bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "locked"; }
          bind "f" { ToggleFocusFullscreen; SwitchToMode "locked"; }
          bind "w" { ToggleFloatingPanes; SwitchToMode "locked"; }
          bind "x" { CloseFocus; SwitchToMode "locked"; }
      }

      renamepane {
          bind "esc" { UndoRenamePane; SwitchToMode "pane"; }
      }

      // ----------------------------------------------------------------------
      // tab
      // ----------------------------------------------------------------------
      tab {
          /// navigation
          // arrows
          bind "left"  { GoToPreviousTab; }
          bind "right" { GoToNextTab; }

          // numbers
          bind "1" { GoToTab 1; SwitchToMode "locked"; }
          bind "2" { GoToTab 2; SwitchToMode "locked"; }
          bind "3" { GoToTab 3; SwitchToMode "locked"; }
          bind "4" { GoToTab 4; SwitchToMode "locked"; }
          bind "5" { GoToTab 5; SwitchToMode "locked"; }
          bind "6" { GoToTab 6; SwitchToMode "locked"; }
          bind "7" { GoToTab 7; SwitchToMode "locked"; }
          bind "8" { GoToTab 8; SwitchToMode "locked"; }
          bind "9" { GoToTab 9; SwitchToMode "locked"; }

          // modification
          bind "n" { NewTab; SwitchToMode "locked"; }
          bind "c" { SwitchToMode "renametab"; TabNameInput 0; }
          bind "x" { CloseTab; SwitchToMode "locked"; }
          bind "b" { BreakPane; SwitchToMode "locked"; }
          bind "[" { BreakPaneLeft; SwitchToMode "locked"; }
          bind "]" { BreakPaneRight; SwitchToMode "locked"; }
      }

      renametab {
          bind "esc" { UndoRenameTab; SwitchToMode "tab"; }
      }

      // ----------------------------------------------------------------------
      // resize
      // ----------------------------------------------------------------------
      resize {
          // arrows
          bind "up"    { Resize "Increase up"; }
          bind "right" { Resize "Increase right"; }
          bind "down"  { Resize "Increase down"; }
          bind "left"  { Resize "Increase left"; }

          // vi
          bind "k" { Resize "Increase up"; }
          bind "l" { Resize "Increase right"; }
          bind "j" { Resize "Increase down"; }
          bind "h" { Resize "Increase left"; }
      }

      // ----------------------------------------------------------------------
      // move
      // ----------------------------------------------------------------------
      move {
          // vi
          bind "k" { MovePane "up"; }
          bind "l" { MovePane "right"; }
          bind "j" { MovePane "down"; }
          bind "h" { MovePane "left"; }

          // arrows
          bind "up"    { MovePane "up"; }
          bind "right" { MovePane "right"; }
          bind "down"  { MovePane "down"; }
          bind "left"  { MovePane "left"; }
      }

      // ----------------------------------------------------------------------
      // search/scroll
      // ----------------------------------------------------------------------

      search {
          bind "c" { SearchToggleOption "CaseSensitivity"; }
          bind "n" { Search "down"; }
          bind "o" { SearchToggleOption "WholeWord"; }
          bind "p" { Search "up"; }
          bind "w" { SearchToggleOption "Wrap"; }
      }

      shared_among "scroll" "search" {
          // arrows
          bind "up" { ScrollUp; }
          bind "down" { ScrollDown; }
          bind "left" { PageScrollUp; }
          bind "right" { PageScrollDown; }

          // vi
          bind "k" { ScrollUp; }
          bind "j" { ScrollDown; }
          bind "h" { PageScrollUp; }
          bind "l" { PageScrollDown; }
          bind "u" { HalfPageScrollUp; }
          bind "d" { HalfPageScrollDown; }
      }

      shared_except "locked" "entersearch" {
          bind "enter" { SwitchToMode "locked"; }
      }

      entersearch {
          bind "Ctrl c" { SwitchToMode "scroll"; }
          bind "esc" { SwitchToMode "scroll"; }
          bind "enter" { SwitchToMode "search"; }
      }

      // ----------------------------------------------------------------------
      // session
      // ----------------------------------------------------------------------
      session {
          bind "d" { Detach; }
          bind "p" {
              LaunchOrFocusPlugin "zellij:plugin-manager" {
                  floating true
                  move_to_focused_tab true
              }
              SwitchToMode "locked"
          }
          bind "w" {
              LaunchOrFocusPlugin "zellij:session-manager" {
                  floating true
                  move_to_focused_tab true
              }
              SwitchToMode "locked"
          }
      }

      // ----------------------------------------------------------------------
      // global
      // ----------------------------------------------------------------------

      shared_except "locked" "renametab" "renamepane" {
          bind "Ctrl b" { SwitchToMode "locked"; }
          bind "Ctrl q" { Quit; }
      }

      shared_except "locked" "entersearch" "renametab" "renamepane" {
          bind "esc" { SwitchToMode "locked"; }
      }

      shared_except "locked" "entersearch" "renametab" "renamepane" "move" {
          bind "m" { SwitchToMode "move"; }
      }

      shared_except "locked" "entersearch" "search" "renametab" "renamepane" "session" {
          bind "o" { SwitchToMode "session"; }
      }

      shared_except "locked" "tab" "entersearch" "renametab" "renamepane" {
          bind "t" { SwitchToMode "tab"; }
      }

      shared_except "locked" "tab" "scroll" "entersearch" "renametab" "renamepane" {
          bind "s" { SwitchToMode "scroll"; }
      }

      shared_except "locked" "resize" "pane" "tab" "entersearch" "renametab" "renamepane" {
          bind "r" { SwitchToMode "resize"; }
      }
  }
''
