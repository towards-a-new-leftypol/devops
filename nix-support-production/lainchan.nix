{ pkgs, lib, config, ... }:

let
  app = "lainchan";
  phpPkg = pkgs.php83;
  phpPkgPackages = pkgs.php83Packages;
  phpPkgExtensions = pkgs.php83Extensions;
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
      upload_max_filesize = 90m
      post_max_size = 90m
      extension=${pkgs.phpExtensions.memcached}/lib/php/extensions/memcached.so
    '';

    phpEnv."PATH" = lib.makeBinPath ( with pkgs; [
      coreutils
      gifsicle
      imagemagick
      graphicsmagick
      phpPkg
      which
      ffmpeg
      ghostscript
      exiftool
    ]);
  };

  services.memcached = {
    enable = true;
    maxMemory = 1024;
  };

  services.cytube = {
    enable = true;
    httpPort = 8083;
    publicPort = 443;

    # Make sure you create the secrets directory with these files
    youtube-v3-key = lib.fileContents ./secrets/cytube/youtube-v3-key;
    cookie-secret = lib.fileContents ./secrets/cytube/cookie-secret;
    cookie-domain = "tv.leftychan.net";
    concurrentUsers = 500;
    database = {
      password = lib.fileContents ./secrets/cytube/database-password;
    };
  };
}

