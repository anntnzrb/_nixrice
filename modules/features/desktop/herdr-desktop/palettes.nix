let
  lightBackground = "#F5F0E7";
  lightForeground = "#3a3627";
  lightBlack = "#484431";
  darkForeground = "#e8e4b1";
  darkRaised = "#2C231D";
  marks = {
    markAnsi6 = "#22a99a";
    markAnsi3 = "#e3814f";
    markAnsi4 = "#5b8def";
    markAnsi5 = "#8b7cf6";
    markAnsi2 = "#3fae6a";
    markAnsi1 = "#d9649a";
    markText = "#ffffff";
  };
in
{
  light = {
    background = lightBackground;
    foreground = lightForeground;
    selection = "#DAC9AE";
    ansi = [
      lightBlack
      "#ba2d2f"
      "#007a0a"
      "#9c600f"
      "#375cc6"
      "#aa3e74"
      "#3f60af"
      "#666d87"
      "#80431a"
      "#c24200"
      "#5a7400"
      "#b44f05"
      "#5e5edc"
      "#b02f80"
      "#4060a0"
      lightBlack
    ];
    colors = marks // {
      chrome = "#E9E0D1";
      canvas = "#DCD0BC";
      border = "#C4AF91";
      accent = "#542c11";
      hover = "#DED0BA";
      selected = "#D8C3A3";
      raised = "#EFE5D5";
      popover = lightBackground;
      working = "#3e360d";
      blocked = "#68191a";
      done = "#004005";
    };
    secondary = lightForeground;
  };
  dark = {
    background = "#191716";
    foreground = darkForeground;
    selection = "#57412F";
    ansi = [
      darkForeground
      "#ff7f7f"
      "#6fd560"
      "#e4b53f"
      "#57aff6"
      "#f0aac5"
      "#6fcad0"
      "#90918a"
      "#ccaa70"
      "#ff7f4f"
      "#a0d13a"
      "#ffa21f"
      "#98bfff"
      "#fa90aa"
      "#7fc5df"
      darkForeground
    ];
    colors = marks // {
      chrome = "#211C19";
      canvas = "#151312";
      border = "#594431";
      accent = "#edc08f";
      hover = "#3B2D23";
      selected = "#493322";
      raised = darkRaised;
      popover = darkRaised;
      working = "#e9c465";
      blocked = "#ffb5b5";
      done = "#86dc79";
    };
    secondary = "#dcc59d";
  };
}
