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

    "~* \.(jpg|jpeg|png|gif|ico|css|js|mp4|mp3|webm|pdf|bmp|zip|epub)$" = {
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

  serverConfig."m.server" = "matrix.leftychan.net:443";
  clientConfig = {
    "m.homeserver".base_url = "https://matrix.leftychan.net";
    "m.identity_server" = {};
  };
  mkWellKnown = data: ''
    add_header Content-Type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';

in

{
  security.acme = {
    email = "paul_cockshott@protonmail.com";
    acceptTerms = true;
    certs."${domain}" = {
      group = "nginx";
      extraDomainNames = [
        "www.leftychan.net"
        "tv.leftychan.net"
        "dev.leftychan.net"
        "dev2.leftychan.net"
        "dev3.leftychan.net"
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

    # recommendedProxySettings = true;

    virtualHosts.${domain} = {
      enableACME = true;
      forceSSL = true;

      locations = leftypol_common_location_block // {
        "= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig; 
        "= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig; 
      };

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

    virtualHosts."www.leftychan.net" = {
      serverAliases = [
        "dev.leftychan.net"
        "dev2.leftychan.net"
        "dev3.leftychan.net"
        #"bunkerchan.red"
        #"leftychan.org"
        #"bunkerchan.net"
        #"leftypol.org"
      ];

      useACMEHost = domain;
      addSSL = true;

      locations = {
        "/" = {
          return = "$scheme://${domain}$request_uri";
        };
      };

      listen = [
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

    virtualHosts."dev2.leftychan.net" = {
      useACMEHost = domain;
      addSSL = true;

      locations = {
        "/" = {
          proxyPass = "http://10.125.114.138:8080";
        };
      };

      listen = [
        { addr = "0.0.0.0"; port = 8080; ssl = false; }
      ];
    };

    virtualHosts."dev3.leftychan.net" = {
      useACMEHost = domain;
      addSSL = true;

      locations = {
        "/" = {
          proxyPass = "http://10.125.114.210:8080";
        };
      };

      listen = [
        { addr = "0.0.0.0"; port = 8080; ssl = false; }
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
