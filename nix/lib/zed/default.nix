{
  zed-editor.util = {
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
