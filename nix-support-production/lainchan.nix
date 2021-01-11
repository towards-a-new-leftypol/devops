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
  imports = [
    ./cytube-nix/cytube.nix
  ];

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
    ghostscript
  ];

  networking.firewall.allowedTCPPorts = [ 8080 443 ];

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = [ "lainchan" "cytube" ];
    ensureUsers = [
      { name = "lainchan";
        ensurePermissions = { "lainchan.*" = "ALL PRIVILEGES"; };
      }
      { name = "admin";
        ensurePermissions = { "lainchan.*" = "ALL PRIVILEGES"; };
      }
      { name = "cytube";
        ensurePermissions = { "cytube.*" = "ALL PRIVILEGES"; };
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
      ghostscript
    ]);
  };

  services.memcached = {
    enable = true;
    maxMemory = 1024;
  };

  security.acme = {
    email = "paul_cockshott@protonmail.com";
    acceptTerms = true;
    certs."leftypol.org" = {
      group = "nginx";
      extraDomainNames = [
        "dev.leftypol.org"
        "www.leftypol.org"
        "tv.leftypol.org"
      ];
    };
  };

  services.nginx = {
    enable = true;

    clientMaxBodySize = "50m";

    recommendedTlsSettings = true;
    virtualHosts.${domain} = {
      serverAliases = [ "dev.leftypol.org" "www.leftypol.org" ];
      enableACME = true;
      forceSSL = true;

      locations = leftypol_common_location_block;

      # Since we are proxied by cloudflare, read the real ip from the header
      extraConfig = ''
        set_real_ip_from 127.0.0.1;
        set_real_ip_from ::1;

        real_ip_header CF-Connecting-IP;

        add_header Onion-Location http://wz6bnwwtwckltvkvji6vvgmjrfspr3lstz66rusvtczhsgvwdcixgbyd.onion$request_uri;
      '';

      listen = [
        { addr = "0.0.0.0"; port = 8080; ssl = false; }
        { addr = "0.0.0.0"; port = 443; ssl = true; }
      ];
    };

    virtualHosts."*.onion" = {
      locations = leftypol_common_location_block;

      listen = [
        { addr = "127.0.0.1"; port = 8081; ssl = false; }
      ];
    };

    virtualHosts."tv.leftypol.org" = {
      forceSSL = true;
      useACMEHost = "leftypol.org";

      locations = {
        "/" = {
          proxyPass = "http://127.0.0.1:8083";
          proxyWebsockets = true;
        };
      };

      listen = [
        { addr = "0.0.0.0"; port = 8080; ssl = false; }
        { addr = "0.0.0.0"; port = 443; ssl = true; }
      ];
    };

    virtualHosts."netdata.leftypol.org" = {
      locations = {
        "/" = {
          proxyPass = "http://127.0.0.1:8084";
        };
      };

      listen = [
        { addr = "0.0.0.0"; port = 8080; ssl = false; }
      ];
    };
  };

  services.cytube = {
    enable = true;
    httpPort = 8083;
    publicPort = 443;

    # Make sure you create the secrets directory with these files
    youtube-v3-key = lib.removeSuffix "\n" (builtins.readFile ./secrets/cytube/youtube-v3-key);
    cookie-secret = lib.removeSuffix "\n" (builtins.readFile ./secrets/cytube/cookie-secret);
    cookie-domain = "tv.leftypol.org";
    concurrentUsers = 500;
    database = {
      password = lib.removeSuffix "\n" (builtins.readFile ./secrets/cytube/database-password);
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

