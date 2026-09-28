{
  programs.yt-dlp = {
    enable = true;

    settings = {
      audio-multistreams = true;
      video-multistreams = true;

      format-sort = "quality,filesize";
      format = "bestvideo*+bestaudio*/best";

      no-keep-fragments = true;
      no-keep-video = true;
      post-overwrites = true;

      continue = true;
      no-playlist = true;
      no-write-comments = true;
      progress = true;
      restrict-filenames = true;
      sponsorblock-mark = "all";
    };
  };
}
