{ lib, pkgs, ... }: {
  environment.systemPackages =
    with pkgs;
    [
      git
      curl
      wget

      atool
      rar
      unzip
      zip

      bc
      file
      gettext
      gnumake
      lsof
      openssl
      python3
      shellcheck
      shfmt
      sqlite
      vim.xxd
      watch

      nh
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      binutils
      psmisc
    ];
}
