{ self
, me
, inputs
, outputs
, nixpkgs
, ...
}:
let
  mkHost = hostInfo: nixpkgs.lib.nixosSystem {
    specialArgs = { inherit self me hostInfo inputs outputs; };
    modules = [ "${me.nixHosts}/${hostInfo.hostName}" ];
  };
in
{
  munich = mkHost { hostName = "munich"; user = "annt"; };
  solna = mkHost { hostName = "solna"; user = "annt"; };
  zadar = mkHost { hostName = "zadar"; user = "annt"; };
}
