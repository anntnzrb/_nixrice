{ self
, me
, inputs
, outputs
, nixpkgs-stable
, ...
}:
let
  mkHost = hostInfo: nixpkgs-stable.lib.nixosSystem {
    specialArgs = { inherit self me hostInfo inputs outputs; };
    modules = [ "${me.nixHosts}/${hostInfo.hostName}" ];
  };
in
{
  munich = mkHost { hostName = "munich"; user = "annt"; };
  solna = mkHost { hostName = "solna"; user = "annt"; };
}
