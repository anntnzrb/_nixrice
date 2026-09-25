{ lib, config, ... }:
lib.liberion.darwin.programs.mkOneMasAppProgram {
  inherit config;
} "whatsapp" "WhatsApp Messenger" 310633997
