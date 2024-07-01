{ lib
, namespace
, ...
}: {
  ${namespace} = with lib.liberion; {
    darwin = {
      system = {
        trackpad = on;
      };

      homebrew = on;
    };
  };
}
