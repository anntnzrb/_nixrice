{ flake }:
let
  f = flake;
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

  home = u: options: {
    packages = pkgs u.home.packages;
    files = files (enabled u.home.file);
    sessionVariables = lib.mapAttrs (_: norm) u.home.sessionVariables;
    sessionPath = map norm u.home.sessionPath;
    aliases = lib.mapAttrs (_: norm) u.home.shellAliases;
    activation = lib.mapAttrs (_: a: norm a.data) u.home.activation;
    systemd = lib.genAttrs [ "services" "timers" ] (
      kind:
      lib.mapAttrs (_: unit: try (norm (builtins.toJSON unit))) (
        u.systemd.user.${kind} or { }
      )
    );
    programs = builtins.filter (
      name:
      let
        option = options.programs.${name};
        isAlias =
          o:
          (o.visible or true) == false
          && lib.hasPrefix "Alias of {option}`" (o.description or "");
      in
      !isAlias option
      && !isAlias (option.enable or { })
      && (builtins.tryEval (u.programs.${name}.enable or false)).value == true
    ) (lib.attrNames options.programs);
    launchd = lib.mapAttrs (_: a: try (norm (builtins.toJSON a.config))) (
      u.launchd.agents or { }
    );
    inherit (u.home) stateVersion;
  };

  system = c: homeOptions: {
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
    home = lib.mapAttrs (name: u: try (home u homeOptions.${name})) (
      c.home-manager.users or { }
    );
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
    nixSettings = try (
      lib.mapAttrs (_: v: norm (builtins.toJSON v)) c.nix.settings
    );
    determinateSettings = try (
      lib.mapAttrs (_: v: norm (builtins.toJSON v)) (
        c.determinateNix.customSettings or { }
      )
    );
    inherit (c.system) stateVersion;
  };

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
  lib.mapAttrs (
    _: c:
    system c.config (
      lib.mapAttrs (_: v: v.configuration.options) (
        c.options.home-manager.users.valueMeta.attrs or { }
      )
    )
  ) (f.nixosConfigurations // f.darwinConfigurations)
  // lib.mapAttrs' (
    n: h: lib.nameValuePair "home:${n}" (home h.config h.options)
  ) f.homeConfigurations
)
