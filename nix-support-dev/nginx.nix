{ config, pkgs, lib, ... }:

let
  app = "lainchan";
  domain = "leftychan.net";
  dataDir = "/srv/http/${app}.leftypol.org";

  leftypol_common_location_block = {
    "^~ /vi/" = {
      proxyPass = "https://img.youtube.com:443";
      extraConfig = ''
        proxy_cache nginx_cache;
      '';
    };

    "~* \.(jpg|jpeg|png|gif|ico|css|js|mp4|mp3|webm|pdf|djvu|bmp|zip|xz|epub)$" = {
      root = dataDir;
      extraConfig = ''
        expires 1h;
      '';
    };

    "~* \.php$" = {
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

    "/" = {
      root = dataDir;
      index = "index.html index.php";
    };
  };

  #container_ip = "10.207.38.96";
  container_ip = "10.4.0.96";

  spamnoticer_static_cfg = {
    postgrest_url = "http://postgrest-local:8080";
    jwt = builtins.readFile ./secrets/spamnoticer/jwt;
    website_urls = {
      leftychan.net = "https://leftychan.net";
      leftychan_dev = "http://${container_ip}:8080";
    };
  };

  spamnoticer_static_cfg_filename = pkgs.writeText "settings.json" (builtins.toJSON spamnoticer_static_cfg);

in

{
  services.nginx = {
    enable = true;

    clientMaxBodySize = "50m";

    appendHttpConfig = ''
      proxy_cache_path /tmp/nginx_cache levels=1:2 keys_zone=nginx_cache:10M max_size=1G inactive=2d;
    '';

    recommendedTlsSettings = false;

    virtualHosts."cytube_dev.leftypol.org" = {
      locations = {
        "/" = {
          proxyPass = "http://127.0.0.1:8083";
          proxyWebsockets = true;
        };
      };

      listen = [
        { addr = "0.0.0.0"; port = 8080; ssl = false; }
      ];
    };

    virtualHosts.${domain} = {
      serverAliases = [ "dev.leftychan.net" "10.207.38.96" "10.4.0.96" ];

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
      ];
    };

    virtualHosts."postgrest-local" = {
      locations = {
        "/" = {
          proxyPass = "http://127.0.0.1:3000";
        };
      };

      listen = [
        { addr = "0.0.0.0"; port = 8080; ssl = false; }
      ];
    };

    # Proxy to authenticate SpamNoticer users
    virtualHosts.spamnoticer = {
      locations = {
        "/stylesheets" = {
          root = dataDir;
          extraConfig = ''
            expires 15d;
          '';
        };

        "= /main.js" = {
          root = dataDir;
          extraConfig = ''
            expires 15d;
          '';
        };

        "/" = {
          root = dataDir;
          index = "auth-proxy.php";
          tryFiles = "$uri /auth-proxy.php";

          extraConfig = ''
            fastcgi_pass unix:${config.services.phpfpm.pools.${app}.socket};
          '';
        };

      };

      listen = [
        { addr = "0.0.0.0"; port = 8080; ssl = false; }
      ];
    };

    # SpamNoticer service (doesn't have own authentication)
    virtualHosts.spam = {
      serverAliases = [ "10.207.38.96" ];

      locations = {
        "=/static/settings.json" = {
          alias = spamnoticer_static_cfg_filename;
        };
        "/" = {
          proxyPass = "http://127.0.0.1:${builtins.toString config.services.spamnoticer.port}";
        };
      };

      listen = [
        { addr = "0.0.0.0"; port = 8300; ssl = false; }
      ];
    };
  };

  users.users.${app} = {
    isSystemUser = true;
    createHome = true;
    home = dataDir;
    homeMode = "750";
    group = app;
    extraGroups = [ "nginx" ];
  };

  users.groups.${app} = {};

  users.users.nginx.extraGroups = [ app "nginx" ];
}
