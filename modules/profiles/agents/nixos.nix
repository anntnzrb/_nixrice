{ inputs, ... }: { imports = with inputs.self.nixosModules; [ t3 ]; }
