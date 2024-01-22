{ config
, lib
, pkgs
, ...
}:
let
  hyprlandEnabled = config.programs.hyprland.enable;
in
{
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # driver for both Xorg and Wayland
  #services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = false;
    nvidiaSettings = true;

    # NOTE: match the kernel
    package = pkgs.linuxPackages_xanmod_latest.nvidia_x11;

    modesetting.enable = true;
  };

  # misc
  programs.hyprland.enableNvidiaPatches = hyprlandEnabled;
  environment.sessionVariables = lib.mkIf hyprlandEnabled {
    "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    XDG_SESSION_TYPE = "wayland";
    GBM_BACKEND = "nvidia-drm";
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };
}
