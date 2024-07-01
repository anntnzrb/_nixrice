{ config
, namespace
, ...
}:
let
  _cfg = config.${namespace}.darwin.system.dock;
in
{
  config = {
    system.defaults.dock = {
      autohide = true;
      largesize = 88;
      magnification = true;
      mineffect = "scale";
      orientation = "left";
      show-process-indicators = true;
      show-recents = false;
      showhidden = false; # hide the hidden lol
      static-only = false; # allow unopened apps to be shown
      tilesize = 40;
    };
  };
}
