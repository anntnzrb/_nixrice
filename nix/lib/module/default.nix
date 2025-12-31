{ lib, ... }:
{
  module = rec {
    /**
      Create an option with specified type, default value, and description.

      # Example

      ```nix
      mkOpt lib.types.str "hello" "A greeting message"
      =>
      { type = <str>; default = "hello"; description = "A greeting message"; }
      ```

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

      # Example

      ```nix
      mkOpt' lib.types.int 42
      =>
      { type = <int>; default = 42; description = null; }
      ```

      # Type

      ```
      mkOpt' :: Type -> Any -> Option
      ```
    */
    mkOpt' = type: def: mkOpt type def null;

    /**
      Create a boolean option defaulting to true, with description.

      # Example

      ```nix
      mkOptEnabled "Enable the feature"
      =>
      { type = <bool>; default = true; description = "Enable the feature"; }
      ```

      # Type

      ```
      mkOptEnabled :: String -> Option
      ```
    */
    mkOptEnabled = desc: mkOpt lib.types.bool true desc;

    /**
      Create a boolean option defaulting to true, no description.

      # Example

      ```nix
      mkOptEnabled'
      =>
      { type = <bool>; default = true; description = null; }
      ```

      # Type

      ```
      mkOptEnabled' :: Option
      ```
    */
    mkOptEnabled' = mkOpt lib.types.bool true null;

    /**
      Create a boolean option defaulting to false, with description.

      # Example

      ```nix
      mkOptDisabled "Enable experimental feature"
      =>
      { type = <bool>; default = false; description = "Enable experimental feature"; }
      ```

      # Type

      ```
      mkOptDisabled :: String -> Option
      ```
    */
    mkOptDisabled = desc: mkOpt lib.types.bool false desc;

    /**
      Create a boolean option defaulting to false, no description.

      # Example

      ```nix
      mkOptDisabled'
      =>
      { type = <bool>; default = false; description = null; }
      ```

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
