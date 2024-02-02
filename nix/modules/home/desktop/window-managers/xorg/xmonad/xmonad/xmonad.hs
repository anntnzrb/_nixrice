import Data.Map qualified as M
import System.Exit (exitSuccess)
import XMonad
import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.StackSet qualified as W
import XMonad.Util.EZConfig (additionalKeysP)

modKey :: KeyMask
modKey = mod4Mask

workspaces :: [WorkspaceId]
workspaces = ["www", "abc"] ++ map show [3 .. 9 :: Int]

layout = Tall nmaster delta ratio
  where
    nmaster = 1 -- amount of master windows
    ratio = 1 / 2
    delta = 3 / 100 -- percent of screen to increment by when resizing panes

keys :: [(String, X ())]
keys =
  [ ("M-<Return>", spawn "${TERMINAL}"),
    ("M-d", spawn "bemenu-run"),
    ("M-M1-r", spawn "xmonad --recompile && xmonad --restart"),
    ("M-S-q", kill),
    ("M-M1-q", io exitSuccess)
  ]
    ++ [ ("M-" ++ m ++ k, windows $ f w)
         | (w, k) <- zip Main.workspaces $ map show [1 .. 9 :: Int],
           (f, m) <- [(W.greedyView, ""), (W.shift, "S-")]
       ]

config =
  def
    { XMonad.modMask = Main.modKey,
      XMonad.keys = const M.empty, -- clear all defaults
      XMonad.workspaces = Main.workspaces,
      XMonad.layoutHook = Main.layout
    }
    `additionalKeysP` Main.keys

main :: IO ()
main = xmonad . ewmh $ Main.config

-- [
-- References:
--
-- Original config (def)
-- - https://github.com/xmonad/xmonad/blob/master/src/XMonad/Config.hs
--
-- Imports not found (NixOS)
-- - https://stackoverflow.com/a/73656818
-- ]
