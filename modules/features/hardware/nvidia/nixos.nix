# Proprietary NVIDIA driver with kernel modesetting (Wayland-ready). The
# default driver branch dropped Pascal and older GPUs: such a machine pins a
# legacy branch through hardware.nvidia.package.
{
  # loads the nvidia kernel modules; does not start X
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics.enable = true;
    nvidia = {
      open = false;
      modesetting.enable = true;
      # nvidia-settings is a GUI tool
      nvidiaSettings = false;
    };
  };
}
