# What every machine and home actually configures, as comparable data:
# package sets, files, users, services, launchd agents, activation scripts,
# Homebrew, aliases, env vars and PATH order. Store hashes are normalised
# and sets sorted, so reordering imports compares equal; report.sh diffs two
# of these.
{ flake }:
let
  f = builtins.getFlake flake;
  inherit (f.inputs.nixpkgs) lib;

  norm =
    s:
    lib.concatMapStrings (x: if builtins.isList x then "/nix/store/HASH-" else x) (
      builtins.split "/nix/store/[a-z0-9]{32}-" (
        builtins.unsafeDiscardStringContext (toString s)
      )
    );
  try =
    x:
    let
      r = builtins.tryEval (builtins.deepSeq x x);
    in
    if r.success then r.value else "<eval error>";

  pkgs =
    ps: lib.sort lib.lessThan (lib.unique (map (p: norm (p.drvPath or p)) ps));
  # repo files by content, so moving one is not a change
  source =
    s:
    let
      path = builtins.unsafeDiscardStringContext (toString s);
    in
    if
      lib.hasInfix "-source/" path
      && builtins.pathExists path
      && builtins.readFileType path == "regular"
    then
      "file sha256:${builtins.hashFile "sha256" path}"
    else
      norm path;
  files = lib.mapAttrs (
    _: v: try (if v.text or null != null then norm v.text else source v.source)
  );
  enabled = lib.filterAttrs (_: v: v.enable or true);

  home = u: {
    packages = pkgs u.home.packages;
    files = files (enabled u.home.file);
    sessionVariables = lib.mapAttrs (_: norm) u.home.sessionVariables;
    sessionPath = map norm u.home.sessionPath;
    aliases = lib.mapAttrs (_: norm) u.home.shellAliases;
    activation = lib.mapAttrs (_: a: norm a.data) u.home.activation;
    programs = lib.attrNames (
      lib.filterAttrs (
        _: p: (builtins.tryEval (p.enable or false)).value == true
      ) u.programs
    );
    launchd = lib.mapAttrs (_: a: try (norm (builtins.toJSON a.config))) (
      u.launchd.agents or { }
    );
    inherit (u.home) stateVersion;
  };

  system = c: {
    packages = pkgs c.environment.systemPackages;
    etc = files (enabled c.environment.etc);
    users = lib.mapAttrs (
      _: u:
      try {
        groups = lib.sort lib.lessThan (u.extraGroups or [ ]);
        keys = lib.sort lib.lessThan u.openssh.authorizedKeys.keys;
        shell = norm (u.shell or "");
        home = u.home or null;
      }
    ) c.users.users;
    home = lib.mapAttrs (_: u: try (home u)) (c.home-manager.users or { });
    services = try (
      lib.mapAttrs (
        _: s:
        norm (builtins.toJSON (s.serviceConfig or { } // { script = s.script or ""; }))
      ) (c.systemd.services or { })
    );
    launchd = try (
      lib.mapAttrs (_: a: norm (builtins.toJSON a.serviceConfig)) (
        (c.launchd.daemons or { })
        // lib.mapAttrs' (n: v: lib.nameValuePair "user-${n}" v) (
          c.launchd.user.agents or { }
        )
      )
    );
    activation = try (
      lib.mapAttrs (_: a: norm (a.text or "")) c.system.activationScripts
    );
    homebrew =
      if c ? homebrew then
        try {
          casks = lib.sort lib.lessThan (map (x: x.name) c.homebrew.casks);
          inherit (c.homebrew) masApps;
        }
      else
        null;
    env = try (
      lib.mapAttrs (
        _: v: norm (if builtins.isList v then lib.concatStringsSep ":" v else v)
      ) c.environment.variables
    );
    profiles = try (map norm c.environment.profiles);
    shellInit = try (
      map norm [
        (c.environment.shellInit or "")
        (c.environment.interactiveShellInit or "")
        (c.environment.loginShellInit or "")
      ]
    );
    inherit (c.system) stateVersion;
  };

  # long texts become a prefix plus a content hash: every change stays visible
  shorten =
    v:
    if builtins.isAttrs v then
      lib.mapAttrs (_: shorten) v
    else if builtins.isList v then
      map shorten v
    else if builtins.isString v && lib.stringLength v > 100 then
      "${lib.substring 0 60 v}... sha256:${
        lib.substring 0 12 (builtins.hashString "sha256" v)
      }"
    else
      v;
in
shorten (
  lib.mapAttrs (_: c: system c.config) (
    f.nixosConfigurations // f.darwinConfigurations
  )
  // lib.mapAttrs' (
    n: h: lib.nameValuePair "home:${n}" (home h.config)
  ) f.homeConfigurations
)
