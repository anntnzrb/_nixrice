{
  lib,
  pkgs,
  inputs,
  config,
  system,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOpt' mkOptBool';
  inherit (inputs.nixpkgs.legacyPackages.${system}) emacs30;

  cfg = config.${namespace}.editors.emacs;

  mkEmacsPackage =
    pkg:
    (pkgs.emacsPackagesFor pkg).emacsWithPackages (
      epkgs: with epkgs; [
        pkgs.coreutils-prefixed # provides gls

        # nix
        pkgs.nixd # LSP
        pkgs.nixfmt-rfc-style # fmt

        # binds
        evil
        evil-collection

        treesit-grammars.with-all-grammars

        # themes
        ef-themes

        # font
        fontaine

        pulsar

        corfu
        envrc
        consult
        orderless

        # minibuffer
        vertico
        marginalia
        embark
        embark-consult

        # AI
        gptel

        # fmt
        apheleia

        # langs
        nix-ts-mode
        gleam-ts-mode
        markdown-mode
      ]
    );
in
{
  options.${namespace}.editors.emacs = {
    enable = mkOptBool';

    package = mkOpt' lib.types.package (
      mkEmacsPackage (
        emacs30.override {
          withNativeCompilation = true;
          withTreeSitter = true;
        }
      )
    );
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      [ cfg.package ]
      ++ [
        # fonts
        pkgs.iosevka-comfy.comfy-motion
        pkgs.iosevka-comfy.comfy-wide-motion-duo
        (pkgs.nerdfonts.override { fonts = [ "ZedMono" ]; })
      ];

    home.shellAliases = {
      # NOTE: 'disown' is not POSIX
      eee = "nohup ${cfg.package}/bin/emacs >/tmp/emacs-nohup.out 2>&1 & disown";
    };
  };
}
