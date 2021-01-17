{ config, pkgs, lib, ... }:

let
  app = "lainchan";
  domain = "leftypol.org";
  dataDir = "/srv/http/${app}.leftypol.org";

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
  security.acme = {
    email = "paul_cockshott@protonmail.com";
    acceptTerms = true;
    certs."leftypol.org" = {
      group = "nginx";
      extraDomainNames = [
        "dev.leftypol.org"
        "www.leftypol.org"
        "tv.leftypol.org"
        "leftychan.org"
        "bunkerchan.red"
      ];
    };
  };

  services.nginx = {
    enable = true;

    clientMaxBodySize = "50m";

    recommendedTlsSettings = true;
    virtualHosts.${domain} = {
      serverAliases = [ "www.leftypol.org" ];
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

    virtualHosts."leftychan.org" = {
      serverAliases = [
        "dev.leftypol.org"
        "bunkerchan.red"
      ];

      useACMEHost = "leftypol.org";
      addSSL = true;

      locations = {
        "/" = {
          return = "$scheme://leftypol.org$request_uri";
        };
      };

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
