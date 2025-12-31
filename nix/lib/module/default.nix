{ lib, ... }:
{
  module = rec {
    /**
      Create an option with specified type, default value, and description.

      # Type

      ```
      mkOpt :: Type -> Any -> String -> Option
      ```

      # Arguments

      type
      : The option type (e.g., lib.types.str)

      default
      : The default value

      description
      : Documentation string for the option
    */
    mkOpt =
      type: default: description:
      lib.mkOption { inherit type default description; };

    /**
      Create an option with specified type and default value, no description.

      # Type

      ```
      mkOpt' :: Type -> Any -> Option
      ```
    */
    mkOpt' = type: def: mkOpt type def null;

    /**
      Create a boolean option defaulting to true, with description.

      # Type

      ```
      mkOptEnabled :: String -> Option
      ```
    */
    mkOptEnabled = desc: mkOpt lib.types.bool true desc;

    /**
      Create a boolean option defaulting to true, no description.

      # Type

      ```
      mkOptEnabled' :: Option
      ```
    */
    mkOptEnabled' = mkOpt lib.types.bool true null;

    /**
      Create a boolean option defaulting to false, with description.

      # Type

      ```
      mkOptDisabled :: String -> Option
      ```
    */
    mkOptDisabled = desc: mkOpt lib.types.bool false desc;

    /**
      Create a boolean option defaulting to false, no description.

      # Type

      ```
      mkOptDisabled' :: Option
      ```
    */
    mkOptDisabled' = mkOpt lib.types.bool false null;

    /**
      Attribute set for enabling an option.

      # Example

      ```nix
      myModule = on;
      =>
      { enable = true; }
      ```
    */
    on.enable = true;

    /**
      Attribute set for disabling an option.

      # Example

      ```nix
      myModule = off;
      =>
      { enable = false; }
      ```
    */
    off.enable = false;
  };
}
