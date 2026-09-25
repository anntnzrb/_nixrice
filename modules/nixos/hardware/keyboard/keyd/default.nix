import ../../../../toggle.nix "hardware.keyboard.keyd" (_: {
  services.keyd = {
    enable = true;

    keyboards.main.settings = {
      "main" = {
        "capslock" = "esc";
      };
    };
  };
})
