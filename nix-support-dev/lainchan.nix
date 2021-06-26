{ pkgs, lib, config, ... }:

let
  app = "lainchan";
  oldpkgs = import ./nixpkgs {};
in

{
  environment.systemPackages = with pkgs; [
    coreutils
    neovim
    screen
    lsof
    gifsicle
    imagemagick
    graphicsmagick
    which
    ffmpeg
    libiconv
    ghostscript
    exiftool
  ];

  # Need to add a row to theme_settings:
  # INSERT INTO theme_settings (theme) VALUES ("catalog");
  # INSERT INTO theme_settings (theme, name, value) VALUES ("catalog", "boards", "b b_anime b_dead b_edu b_games b_get b_gulag b_hobby b_ref b_tech");

  #services.phpfpm.phpPackage = oldpkgs.pkgs.php72;
  services.phpfpm.pools.${app} = {
    user = app;

    settings = {
      "listen.owner" = config.services.nginx.user;
      "pm" = "dynamic";
      "pm.max_children" = 32;
      "pm.max_requests" = 500;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 2;
      "pm.max_spare_servers" = 5;
      "php_admin_value[error_log]" = "stderr";
      "php_admin_flag[log_errors]" = true;
      "catch_workers_output" = true;
    };

    phpOptions = ''
      upload_max_filesize = 50m
      post_max_size = 51m
    '';

    phpEnv."PATH" = lib.makeBinPath ( with pkgs; [
      coreutils
      gifsicle
      imagemagick
      graphicsmagick
      php
      which
      ffmpeg
      ghostscript
    ]);
  };

  services.memcached = {
    enable = false;
    maxMemory = 1024;
  };

  services.cytube = {
    enable = false;
    httpPort = 8083;
    publicPort = 8891;

    # Make sure you create the secrets directory with these files
    youtube-v3-key = builtins.readFile ./secrets/cytube/youtube-v3-key;
    cookie-secret = builtins.readFile ./secrets/cytube/cookie-secret;
    cookie-domain = "tv.leftypol.org";
    database = {
      password = builtins.readFile ./secrets/cytube/database-password;
    };
  };
}

