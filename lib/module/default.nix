{ lib, ... }:
let
  /**
    Create an option with specified type, default value, and description.
    Use this for non-boolean options, or when a module needs a precise
    default that is not captured by the enable-helper naming convention.
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
    This helper is for default-enabled baseline behavior: modules that should
    participate unless a host or home explicitly opts out.

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
    This is the description-free form of `mkOptEnabled`; reserve it for
    default-enabled baselines where generated option documentation is not needed.

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
    This helper is for opt-in features: modules that should stay inactive unless
    a host or home explicitly enables them.

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
    This is the description-free form of `mkOptDisabled`; reserve it for opt-in
    features where generated option documentation is not needed.

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
in
{
  module = {
    inherit
      mkOpt
      mkOpt'
      mkOptEnabled
      mkOptEnabled'
      mkOptDisabled
      mkOptDisabled'
      ;

    /**
      Attribute set for enabling an option.
      Use with modules exposing the conventional `enable` flag. For
      default-disabled helpers, this opts the feature in; for default-enabled
      helpers, this is normally redundant but can make intent explicit at a
      call site.

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
      Use with modules exposing the conventional `enable` flag. For
      default-enabled helpers, this opts the baseline out; for default-disabled
      helpers, this is normally redundant but can make intent explicit at a
      call site.

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
