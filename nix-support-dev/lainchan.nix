{ pkgs, lib, config, ... }:

let
  app = "lainchan";
  domain = "leftypol.org";
  dataDir = "/srv/http/${app}.leftypol.org";
  oldpkgs = import ./nixpkgs {};

  leftypol_common_location_block = {
    "~ \.php$" = {
      root = dataDir;
      extraConfig = ''
            # fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:${config.services.phpfpm.pools.${app}.socket};
      '';
    };

    "~* \.(?:html|json)$" = {
      root = dataDir;
      extraConfig = ''
        expires 1s;
      '';
    };

    "~* \.(jpg|jpeg|png|gif|ico|css|js|mp4|mp3|webm|pdf|bmp|zip|epub)$" = {
      root = dataDir;
      extraConfig = ''
        expires 1h;
      '';
    };

    "/" = {
      root = dataDir;
      index = "index.html index.php";
    };
  };
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
    phpExtensions.memcached
  ];

  networking.firewall.allowedTCPPorts = [ 8080 ];
  #networking.firewall.enable = true;

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = [ "lainchan" ];
    ensureUsers = [
      { name = "lainchan";
        ensurePermissions = { "lainchan.*" = "ALL PRIVILEGES"; };
      }
      { name = "admin";
        ensurePermissions = { "lainchan.*" = "ALL PRIVILEGES"; };
      }
    ];
    settings.mysqld = {
      innodb_buffer_pool_size = 2147483648;
      innodb_buffer_pool_instances = 4;
    };
  };

  # Need to add a row to theme_settings:
  # INSERT INTO theme_settings (theme) VALUES ("catalog");
  # INSERT INTO theme_settings (theme, name, value) VALUES ("catalog", "boards", "b b_anime b_dead b_edu b_games b_get b_gulag b_hobby b_ref b_tech");

  services.phpfpm.phpPackage = oldpkgs.pkgs.php72;
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
      extension=${pkgs.phpExtensions.memcached}/lib/php/extensions/memcached.so
    '';

    phpEnv."PATH" = lib.makeBinPath ( with pkgs; [
      coreutils
      gifsicle
      imagemagick
      graphicsmagick
      php
      which
      ffmpeg
      exiftool
    ]);
  };

  services.memcached = {
    enable = true;
    maxMemory = 1024;
  };

  services.nginx = {
    enable = true;

    clientMaxBodySize = "50m";

    recommendedTlsSettings = true;
    virtualHosts.${domain} = {
      serverAliases = [ "dev.leftypol.org" "www.leftypol.org" ];
      locations = leftypol_common_location_block;

      # Since we are proxied by cloudflare, read the real ip from the header
      extraConfig = ''
        set_real_ip_from 127.0.0.1;
        set_real_ip_from ::1;

        real_ip_header CF-Connecting-IP;
      '';

      listen = [
        { addr = "0.0.0.0"; port = 8080; ssl = false; }
        #{ addr = "0.0.0.0"; port = 443; ssl = true; }
      ];
    };
  };

  users.users.${app} = {
    isSystemUser = true;
    createHome = true;
    home = dataDir;
    group = app;
    extraGroups = [ "nginx" ];
  };

  users.groups.${app} = {};

  users.users.nginx.extraGroups = [ app "nginx" ];
}

