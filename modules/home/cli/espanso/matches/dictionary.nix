{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.cli.espanso;
in
{
  config.services.espanso.matches.default.matches = lib.mkIf cfg.enable [
    # -------------------------------------------------------------------------
    # ES
    # -------------------------------------------------------------------------
    {
      trigger = "xq";
      replace = "porque";
      word = true;
    }
    {
      trigger = "xq?";
      replace = "por qué?";
      word = true;
    }
    {
      trigger = "dnd";
      replace = "donde";
      word = true;
    }
    {
      trigger = "rapido";
      replace = "rápido";
      word = true;
    }
    {
      trigger = "dnd?";
      replace = "dónde?";
      word = true;
    }
    {
      trigger = "asi";
      replace = "así";
      word = true;
    }
    {
      trigger = "tambien";
      replace = "también";
      word = true;
    }
    {
      trigger = "tmb";
      replace = "también";
      word = true;
    }

    # -------------------------------------------------------------------------
    # EN
    # -------------------------------------------------------------------------
    {
      trigger = "its";
      replace = "it's";
      word = true;
    }
    {
      trigger = "pls";
      replace = "please";
      word = true;
    }
    {
      trigger = "thx";
      replace = "thanks";
      word = true;
    }
    {
      trigger = "asap";
      replace = "as soon as possible";
      word = true;
    }
    {
      trigger = "cuz";
      replace = "because";
      word = true;
    }
    {
      trigger = "lmk";
      replace = "let me know";
      word = true;
    }
    {
      trigger = "tbh";
      replace = "to be honest";
      word = true;
    }
    {
      trigger = "tbf";
      replace = "to be fair";
      word = true;
    }
    {
      trigger = "idk";
      replace = "I don't know";
      word = true;
    }
    {
      trigger = "dont";
      replace = "don't";
      word = true;
    }
    {
      trigger = "didnt";
      replace = "didn't";
      word = true;
    }
    {
      trigger = "wont";
      replace = "won't";
      word = true;
    }
    {
      trigger = "weve";
      replace = "we've";
      word = true;
    }
    {
      trigger = "shouldnt";
      replace = "shouldn't";
      word = true;
    }
    {
      trigger = "couldnt";
      replace = "couldn't";
      word = true;
    }
    {
      trigger = "lenght";
      replace = "length";
      word = true;
    }
    {
      trigger = "ur";
      replace = "your";
      word = true;
    }
    {
      trigger = "urs";
      replace = "yours";
      word = true;
    }
    {
      trigger = "ure";
      replace = "you're";
      word = true;
    }
  ];
}
