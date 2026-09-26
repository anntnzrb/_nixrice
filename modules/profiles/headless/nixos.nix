# Machines tagged `headless`: no GUI (no X, no docs). Always-on lives in `server`.
{
  services.xserver.enable = false;

  # no man pages either (base already drops doc/info and the NixOS manual)
  documentation.enable = false;
}
