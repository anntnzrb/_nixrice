{ ... }: {
  on = {
    # services.foo = enabled;
    enable = true;
  };

  off = {
    # services.bar = disabled;
    enable = false;
  };
}
