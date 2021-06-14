{ config, pkgs, ...}:

{
  services.netdata = {
    enable = true;
    config.global = {
      "default port" = 8084;
      "web files owner" = "root";
      "web files group" = "root";
    };
  };
}
