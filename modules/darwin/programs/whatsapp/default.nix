{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.darwin.programs.mkOneMasAppProgram {
  inherit config namespace;
} "whatsapp" "WhatsApp Messenger" 310633997
