{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.shells.zellij;
in
{
  config = lib.mkIf cfg.enable {
    xdg.configFile."zellij/config.kdl".text = # kdl
      ''
        keybinds clear-defaults=true {
            // ------------------------------------------------------------------
            // pane
            // ------------------------------------------------------------------

            pane {
                // navigation
                bind "k" "up"    { MoveFocus "up"; }
                bind "l" "right" { MoveFocus "right"; }
                bind "j" "down"  { MoveFocus "down"; }
                bind "h" "left"  { MoveFocus "left"; }

                bind "tab" { SwitchFocus; }

                // new panes
                bind "%"  { NewPane "down";  SwitchToMode "locked"; }
                bind "\"" { NewPane "right"; SwitchToMode "locked"; }

                // misc
                bind "c" { SwitchToMode "renamepane"; PaneNameInput 0; }
                bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "locked"; }
                bind "f" { ToggleFocusFullscreen;     SwitchToMode "locked"; }
                bind "w" { ToggleFloatingPanes;       SwitchToMode "locked"; }
                bind "x" { CloseFocus;                SwitchToMode "locked"; }
                bind "z" { TogglePaneFrames;          SwitchToMode "locked"; }
            }

            shared_among "normal" "resize" "tab" "scroll" "prompt" "tmux" {
                bind "1" { SwitchToMode "pane"; }
            }

            renamepane {
                bind "esc" { UndoRenamePane; SwitchToMode "pane"; }
            }

            shared_among "renametab" "renamepane" {
                bind "Ctrl c" { SwitchToMode "locked"; }
            }

            // ------------------------------------------------------------------
            // tab
            // ------------------------------------------------------------------

            tab {
                // navigation
                bind "k" "up"    { GoToPreviousTab; }
                bind "l" "right" { GoToNextTab; }
                bind "j" "down"  { GoToNextTab; }
                bind "h" "left"  { GoToPreviousTab; }

                // new tabs
                bind "n" { NewTab;         SwitchToMode "locked"; }
                bind "b" { BreakPane;      SwitchToMode "locked"; }
                bind "[" { BreakPaneLeft;  SwitchToMode "locked"; }
                bind "]" { BreakPaneRight; SwitchToMode "locked"; }

                // misc
                bind "c"   { SwitchToMode "renametab"; TabNameInput 0; }
                bind "s"   { ToggleActiveSyncTab;      SwitchToMode "locked"; }
                bind "x"   { CloseTab;                 SwitchToMode "locked"; }
                bind "tab" { ToggleTab; }
            }

            shared_except "locked" "tab" "entersearch" "renametab" "renamepane" {
                bind "2" { SwitchToMode "tab"; }
            }

            // ------------------------------------------------------------------
            // rename
            // ------------------------------------------------------------------

            renametab {
                bind "esc" { UndoRenameTab; SwitchToMode "tab"; }
            }

            // ------------------------------------------------------------------
            // resize
            // ------------------------------------------------------------------

            resize {
                bind "k" "up"    { Resize "Increase up"; }
                bind "l" "right" { Resize "Increase right"; }
                bind "j" "down"  { Resize "Increase down"; }
                bind "h" "left"  { Resize "Increase left"; }
            }

            shared_except "locked" "resize" "pane" "tab" "entersearch" "renametab" "renamepane" {
                bind "r" { SwitchToMode "resize"; }
            }

            // ------------------------------------------------------------------
            // move
            // ------------------------------------------------------------------

            move {
                bind "k" "up"    { MovePane "up"; }
                bind "l" "right" { MovePane "right"; }
                bind "j" "down"  { MovePane "down"; }
                bind "h" "left"  { MovePane "left"; }
            }

            shared_except "locked" "entersearch" "renametab" "renamepane" "move" {
                bind "m" { SwitchToMode "move"; }
            }

            // ------------------------------------------------------------------
            // scroll/search
            // ------------------------------------------------------------------

            scroll {
                bind "e" { EditScrollback; SwitchToMode "locked"; }
                bind "/" { SwitchToMode "entersearch"; SearchInput 0; }
            }

            search {
                // navigation
                bind "p" { Search "up"; }
                bind "n" { Search "down"; }

                // misc
                bind "c" { SearchToggleOption "CaseSensitivity"; }
                bind "o" { SearchToggleOption "WholeWord"; }
                bind "w" { SearchToggleOption "Wrap"; }
            }

            entersearch {
                bind "Ctrl c" { SwitchToMode "scroll"; }
                bind "esc" { SwitchToMode "scroll"; }
                bind "enter" { SwitchToMode "search"; }
            }

            shared_except "locked" "tab" "scroll" "entersearch" "renametab" "renamepane" {
                // like search-map (M-s) in Emacs
                bind "Alt s" { SwitchToMode "scroll"; }
            }

            shared_among "scroll" "search" {
                bind "h" "left"  { PageScrollUp; }
                bind "j" "down"  { ScrollDown; }
                bind "k" "up"    { ScrollUp; }
                bind "l" "right" { PageScrollDown; }
                bind "u"         { HalfPageScrollUp; }
                bind "d"         { HalfPageScrollDown; }
            }

            // ------------------------------------------------------------------
            // session
            // ------------------------------------------------------------------

            session {
                bind "c" {
                    LaunchOrFocusPlugin "configuration" {
                        floating true
                        move_to_focused_tab true
                    }
                    SwitchToMode "locked"
                }
                bind "d" { Detach; }
                bind "p" {
                    LaunchOrFocusPlugin "plugin-manager" {
                        floating true
                        move_to_focused_tab true
                    }
                    SwitchToMode "locked"
                }
                bind "w" {
                    LaunchOrFocusPlugin "session-manager" {
                        floating true
                        move_to_focused_tab true
                    }
                    SwitchToMode "locked"
                }
            }

            shared_except "locked" "pane" "entersearch" "search" "renametab" "renamepane" "session" {
                bind "x" { SwitchToMode "session"; }
            }

            // ------------------------------------------------------------------
            // misc
            // ------------------------------------------------------------------

            locked {
                bind "Ctrl a" { SwitchToMode "normal"; }
            }

            shared_except "locked" "renametab" "renamepane" {
                bind "Ctrl a" { SwitchToMode "locked"; }
                bind "Ctrl q" { Quit; }
            }

            shared_except "locked" "entersearch" {
                bind "enter" { SwitchToMode "locked"; }
            }

            shared_except "locked" "entersearch" "renametab" "renamepane" {
                bind "esc" { SwitchToMode "locked"; }
            }
        }
      '';
  };
}
