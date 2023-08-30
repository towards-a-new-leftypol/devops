{ config, pkgs, lib, ... }:

let
  cfg = config.services.spamnoticer;

  spamnoticer_static = pkgs.callPackage ./spamnoticer_static.nix {};
  spamnoticer = pkgs.callPackage ./SpamNoticer/default.nix {};

  noticerConfig = {
    "postgrest_url" = cfg.postgrestUrl;
    "jwt" = cfg.jwt;
    "static_dir" = spamnoticer_static;
    "spam_content_dir" = cfg.spamContentDir;
    "port" = cfg.port;
    "debug" = cfg.debug;
  };

in

{
  options = {
    services.spamnoticer = with lib; {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = "Enable SpamNoticer http server";
      };

      postgrestUrl = mkOption {
        type = types.str;
        description = "Url to reach postgREST server";
        example = "http://localhost:3000";
      };

      jwt = mkOption {
        type = types.str;
        description = "base64 encoded JWT for postgREST";
      };

      spamContentDir = mkOption {
        type = types.str;
        description = "directory where spam images are written / served from";
        example = "/srv/http/spam";
      };

      port = mkOption {
        type = types.int;
        default = 8300;
        description = "http serve port";
      };

      debug = mkOption {
        default = false;
        type = types.bool;
        description = "Enable/disable debugging";
      };

      user = mkOption {
        type = types.str;
        default = "spamnoticer";
        description = "User the service will run as";
      };

      group = mkOption {
        type = types.str;
        default = "spamnoticer";
        description = "Group the service will run as";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      spamnoticer_static
      spamnoticer
    ];

    systemd.services.spamnoticer = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        SPAMNOTICER_CONFIG = builtins.toJSON noticerConfig;
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        #Restart = "on-failure";
        WorkingDirectory = "/home/${cfg.user}";
        ExecStart = "${spamnoticer}/bin/spamnoticer";
        KillSignal = "SIGTERM";
      };
    };

    users.groups = {
      ${cfg.group} = {};
    };

    users.extraUsers.${cfg.user} = {
      group = cfg.group;
      extraGroups = [ "nginx" ];
      #isSystemUser = true;
      isNormalUser = true;
      createHome = true;
    };
  };
}
