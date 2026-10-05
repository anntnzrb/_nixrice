{
  home.stateVersion = "26.05";

  programs = {
    gh.settings = {
      git_protocol = "ssh";
      prompt = "enabled";
    };

    direnv.config.global = {
      load_dotenv = true;
      strict_env = true;
      hide_env_diff = true;
    };
  };
}
