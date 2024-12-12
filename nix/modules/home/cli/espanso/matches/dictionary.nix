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
      trigger = "qtal?";
      replace = "qué tal?";
      word = true;
    }
    {
      trigger = "qfue?";
      replace = "qué fue?";
      word = true;
    }
    {
      trigger = "qpaso?";
      replace = "qué pasó?";
      word = true;
    }
    {
      trigger = "asi";
      replace = "así";
      word = true;
    }
    {
      trigger = "snmr";
      replace = "si no mal recuerdo";
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
      trigger = "i";
      replace = "I";
      word = true;
    }
    {
      trigger = "its";
      replace = "it's";
      word = true;
    }
    {
      trigger = "itss";
      replace = "its";
      word = true;
    }
    {
      trigger = "pls";
      replace = "please";
      word = true;
    }
    {
      trigger = "sry";
      replace = "sorry";
      word = true;
    }
    {
      trigger = "np";
      replace = "noproblem";
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
      trigger = "btw";
      replace = "by the way,";
      word = true;
    }
    {
      trigger = "fyi";
      replace = "for your information,";
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
      trigger = "fr?";
      replace = "for real?";
      word = true;
    }
    {
      trigger = "idk";
      replace = "I don't know";
      word = true;
    }
    {
      trigger = "afaik";
      replace = "as far as I know";
      word = true;
    }
    {
      trigger = "iirc";
      replace = "If I recall correctly";
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
      trigger = "w/";
      replace = "with";
      word = true;
    }
    {
      trigger = "w/o";
      replace = "without";
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
