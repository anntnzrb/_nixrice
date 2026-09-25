{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.cli.yt-dlp;
in
{
  options.liberion.cli.yt-dlp = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.yt-dlp = {
      inherit (cfg) enable;

      settings = {
        # multistreams
        audio-multistreams = true;
        video-multistreams = true;

        # formats
        format-sort = "quality,filesize";
        format = "bestvideo*+bestaudio*/best";

        # cleanup
        no-keep-fragments = true;
        no-keep-video = true;
        post-overwrites = true;

        # misc
        continue = true;
        no-playlist = true;
        no-write-comments = true;
        progress = true;
        restrict-filenames = true;
        sponsorblock-mark = "all";
      };
    };
  };
}
