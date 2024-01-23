{ lib
, ...
}: with lib; rec {

  # Alias for mkOption.
  mkOpt = type: default: description:
    mkOption { inherit type default description; };

  # Alias for mkOption with no description.
  mkOpt' = type: default: mkOpt type default null;

  # Alias for mkEnableOption.
  mkOptBool = desc: mkEnableOption desc;

  # Alias for mkEnableOption with no description.
  mkOptBool' = mkOptBool null;

  # Alias for enabling a service.
  on = {
    enable = true;
  };

  # Alias for disabling a service.
  off = {
    enable = false;
  };
}
