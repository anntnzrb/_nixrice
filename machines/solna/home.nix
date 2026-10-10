{ inputs, ... }: { imports = with inputs.self.homeModules; [ ai-agents ]; }
