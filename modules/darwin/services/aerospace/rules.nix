# AeroSpace window rules parameterised by the rule helpers; the parent's enable
# guard in default.nix applies `aerospaceLib.mkRules` to this list.
aerospaceLib: [
  {
    appId = "org.mozilla.firefox";
    run = [ (aerospaceLib.mvNodeToWorkspace 1) ];
  }
  {
    appId = "org.gnu.Emacs";
    furtherCallbacks = false;
    run = [ (aerospaceLib.mkLayout "tiling") ];
  }
  {
    appId = "org.alacritty";
    run = [ (aerospaceLib.mvNodeToWorkspace 2) ];
  }
  {
    appId = "com.mitchellh.ghostty";
    run = [ (aerospaceLib.mvNodeToWorkspace 2) ];
  }
  {
    appId = "com.raphaelamorim.rio";
    run = [ (aerospaceLib.mvNodeToWorkspace 2) ];
  }
  {
    appId = "com.microsoft.VSCode";
    run = [ (aerospaceLib.mvNodeToWorkspace 3) ];
  }
  {
    appId = "net.whatsapp.WhatsApp";
    run = [ (aerospaceLib.mvNodeToWorkspace 4) ];
  }
  {
    appId = "com.openai.chat";
    run = [ (aerospaceLib.mvNodeToWorkspace 4) ];
  }
  { run = [ (aerospaceLib.mkLayout "floating") ]; }
]
