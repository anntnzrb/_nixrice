{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    du-dust
    exa
    fd
    (ripgrep.override { withPCRE2 = true; })
  ];

  home.shellAliases = {
    # ls/tree => exa
    ls = "exa --color=automatic --group-directories-first --icons --sort=Name -Fagh";
    ll = "exa --color=automatic --group-directories-first --icons --sort=Name -Faglh";

    tree = "exa --color=automatic --group-directories-first --icons -FTgh";
    treea = "exa --color=automatic --group-directories-first --icons -FTagh";
    treed = "exa --color=automatic --icons -DFTgh";

    # grep => rg
    grep = "rg --color=auto --column --hidden -Hin";

    # cat/less => bat
    cat = "bat --color=auto --theme='Monokai Extended Origin' --style=full -P";
    less = "bat --color=auto --theme='Monokai Extended Origin' --style=full";
  };
}
