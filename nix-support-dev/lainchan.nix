{ pkgs, lib, config, ... }:

let
  app = "lainchan";
  phpPkg = pkgs.php82;
  phpPkgPackages = pkgs.php82Packages;
  phpPkgExtensions = pkgs.php82Extensions;
in

{
  environment.systemPackages = with pkgs; [
    coreutils
    neovim
    screen
    lsof
    which
    ffmpeg
    libiconv
    ghostscript
    exiftool
    phpPkg
    phpPkgPackages.composer
    phpPkgExtensions.memcached
  ];

  # Need to add a row to theme_settings:
  # INSERT INTO theme_settings (theme) VALUES ("catalog");
  # INSERT INTO theme_settings (theme, name, value) VALUES ("catalog", "boards", "b b_anime b_dead b_edu b_games b_get b_gulag b_hobby b_ref b_tech");

  services.phpfpm.pools.${app} = {
    user = app;
    group = app;
    phpPackage = phpPkg;

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
      display_errors = on
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
      exiftool
    ]);
  };

  services.memcached = {
    enable = false;
    maxMemory = 1024;
  };

  services.cytube = {
    enable = true;
    httpPort = 8083;
    publicPort = 8891;

    # Make sure you create the secrets directory with these files
    youtube-v3-key = lib.fileContents ./secrets/cytube/youtube-v3-key;
    cookie-secret = lib.fileContents ./secrets/cytube/cookie-secret;
    cookie-domain = "tv.leftypol.org";
    database = {
      password = lib.fileContents ./secrets/cytube/database-password;
    };
  };
}

