{ inputs, ... }: { imports = with inputs.self.darwinModules; [ sshd ]; }
