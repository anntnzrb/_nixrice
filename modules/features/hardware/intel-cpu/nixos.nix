# Intel CPU: microcode updates, redistributable firmware, kvm.
{
  boot.kernelModules = [ "kvm-intel" ];
  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };
}
