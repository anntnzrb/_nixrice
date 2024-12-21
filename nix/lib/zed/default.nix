{
  zed-editor.util = {
    # takes a list of paths and imports each one
    mapImports = paths: map (p: import p) paths;

    # creates a formatter configuration via external command
    mkFmt = command: arguments: {
      external = {
        inherit command arguments;
      };
    };

    # configuration for direnv integration
    useDirenv = {
      path_lookup = true;
    };
  };
}
