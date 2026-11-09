{ lib, ... }: {
  options.liberion.shells.herdr.desktop = lib.liberion.module.mkOptDisabled';
}
