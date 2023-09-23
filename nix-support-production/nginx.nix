{ config, pkgs, lib, ... }:

let
  app = "lainchan";
  domain = "leftychan.net";
  dataDir = "/srv/http/${app}.leftypol.org";

  # Since we are proxied by cloudflare, read the real ip from the header
  cloudflareExtraConfig = ''
    set_real_ip_from 127.0.0.1;
    set_real_ip_from ::1;

    real_ip_header CF-Connecting-IP;

    add_header Onion-Location http://wz6bnwwtwckltvkvji6vvgmjrfspr3lstz66rusvtczhsgvwdcixgbyd.onion$request_uri;
  '';


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

  serverConfig."m.server" = "matrix.leftychan.net";

  clientConfig = {
    "m.homeserver".base_url = "https://matrix.leftychan.net";
    "m.identity_server" = {};
  };

  mkWellKnown = data: ''
    add_header Content-Type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';

  spamnoticer_static_cfg = {
    postgrest_url = "https://pgrest-spam.leftychan.net";
    jwt = builtins.readFile ./secrets/spamnoticer/jwt;
    website_urls = {
      leftychan = "https://leftychan.net";
    };
  };

  spamnoticer_static_cfg_filename = pkgs.writeText "settings.json" (builtins.toJSON spamnoticer_static_cfg);

in

{
  security.acme = {
    acceptTerms = true;
    certs."${domain}" = {
      group = "nginx";
      email = "paul_cockshott@protonmail.com";
      extraDomainNames = [
        "www.leftychan.net"
        "tv.leftychan.net"
        "dev.leftychan.net"
        "dev2.leftychan.net"
        "dev3.leftychan.net"
        "dev-spamnoticer.leftychan.net"
        "dev-pgrest-spam.leftychan.net"
        "cytube-dev.leftychan.net"
        "drama.leftychan.net"
        "spamnoticer.leftychan.net"
        "pgrest-spam.leftychan.net"
      ];
    };
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    clientMaxBodySize = "80m";

    appendHttpConfig = ''
      proxy_cache_path /tmp/nginx_cache levels=1:2 keys_zone=nginx_cache:10M max_size=1G inactive=2d;
    '';

    recommendedTlsSettings = true;

    virtualHosts.${domain} = {
      enableACME = true;
      forceSSL = true;

      locations = leftypol_common_location_block // {
        "= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig; 
        "= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig; 
      };

      extraConfig = cloudflareExtraConfig;

      listen = [
        { addr = "0.0.0.0"; port = 8080; ssl = false; }
        { addr = "0.0.0.0"; port = 443; ssl = true; }
      ];
    };

    virtualHosts."www.leftychan.net" = {
      /*
      serverAliases = [
        "dev.leftychan.net"
        "dev2.leftychan.net"
        "dev3.leftychan.net"
        #"bunkerchan.red"
        #"leftychan.org"
        #"bunkerchan.net"
        #"leftypol.org"
      ];
      */

      useACMEHost = domain;
      addSSL = true;

      locations = {
        "/" = {
          return = "$scheme://${domain}$request_uri";
        };
      };

      listen = [
        { addr = "0.0.0.0"; port = 8080; ssl = false; }
        { addr = "0.0.0.0"; port = 443; ssl = true; }
      ];
    };

    virtualHosts."*.onion" = {
      locations = leftypol_common_location_block;

      extraConfig = ''
        port_in_redirect off;
      '';

      listen = [
        { addr = "127.0.0.1"; port = 8081; ssl = false; }
      ];
    };

    virtualHosts."tv.leftychan.net" = {
      forceSSL = true;
      #addSSL = true;
      useACMEHost = domain;

      locations = {
        "/" = {
          proxyPass = "http://127.0.0.1:8083";
          proxyWebsockets = true;
        };
      };

      extraConfig = ''
        proxy_redirect          off;
        proxy_http_version      1.1;
        proxy_set_header        Host $host;
        proxy_set_header        X-Real-IP $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto $scheme;
        proxy_set_header        X-Forwarded-Host $host;
        proxy_set_header        X-Forwarded-Server $host;
      '';

      listen = [
        { addr = "0.0.0.0"; port = 8080; ssl = false; }
        { addr = "0.0.0.0"; port = 443; ssl = true; }
      ];
    };

    virtualHosts."netdata.leftychan.net" = {
      locations = {
        "/" = {
          proxyPass = "http://127.0.0.1:8084";
          extraConfig = ''
            proxy_set_header        Host $host;
            proxy_set_header        X-Real-IP $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        X-Forwarded-Proto $scheme;
            proxy_set_header        X-Forwarded-Host $host;
            proxy_set_header        X-Forwarded-Server $host;
          '';
        };
      };

      listen = [
        { addr = "0.0.0.0"; port = 8080; ssl = false; }
      ];
    };

    virtualHosts."drama.leftychan.net" = {
      useACMEHost = domain;
      forceSSL = true;
      root = "/srv/http/drama";
      listen = [
        { addr = "0.0.0.0"; port = 8080; ssl = false; }
        { addr = "0.0.0.0"; port = 443; ssl = true; }
      ];
    };

    virtualHosts."dev.leftychan.net" = {
      serverAliases = [
        "dev-spamnoticer.leftychan.net"
        "dev-pgrest-spam.leftychan.net"
      ];
      useACMEHost = domain;
      forceSSL = true;

      locations = {
        "/" = {
          proxyPass = "http://10.125.114.96:8080";
          extraConfig = ''
            proxy_set_header        Host $host;
            proxy_set_header        X-Real-IP $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        X-Forwarded-Proto $scheme;
            proxy_set_header        X-Forwarded-Host $host;
            proxy_set_header        X-Forwarded-Server $host;
          '';
        };
      };

      listen = [
        { addr = "0.0.0.0"; port = 8080; ssl = false; }
        { addr = "0.0.0.0"; port = 443; ssl = true; }
      ];
    };

    virtualHosts."cytube-dev.leftychan.net" = {
      useACMEHost = domain;
      forceSSL = true;

      locations = {
        "/" = {
          proxyPass = "http://10.125.114.96:8080";
        };
      };

      listen = [
        { addr = "0.0.0.0"; port = 8080; ssl = false; }
        { addr = "0.0.0.0"; port = 443; ssl = true; }
      ];
    };

    # Proxy to authenticate SpamNoticer users
    virtualHosts."spamnoticer.leftychan.net" = {
      useACMEHost = domain;
      forceSSL = true;

      locations = {
        "/stylesheets" = {
          root = dataDir;
          extraConfig = ''
            expires 1s;
          '';
        };

        "= /main.js" = {
          root = dataDir;
          extraConfig = ''
            expires 1s;
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
        { addr = "0.0.0.0"; port = 443; ssl = false; }
      ];
    };

    # SpamNoticer service (doesn't have own authentication)
    virtualHosts.spam = {
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

    virtualHosts."pgrest-spam.leftychan.net" = {
      useACMEHost = domain;
      forceSSL = true;

      locations = {
        "/" = {
          proxyPass = "http://127.0.0.1:3000";
          recommendedProxySettings = true;
        };
      };

      listen = [
        { addr = "0.0.0.0"; port = 8080; ssl = false; }
        { addr = "0.0.0.0"; port = 443; ssl = false; }
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
