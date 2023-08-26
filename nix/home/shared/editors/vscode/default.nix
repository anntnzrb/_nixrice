{ pkgs
, ...
}: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs; # non-free

    enableUpdateCheck = true;
    enableExtensionUpdateCheck = true;
    # whether extensions can be installed or updated manually or by visual studio code.
    mutableExtensionsDir = true;
  };
}
