{ config, pkgs, lib, ... }:

let
  # Submodule for a single website
  websiteModule = { config, ... }: {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Website name";
        example = "Transportation";
      };

      root_url = lib.mkOption {
        type = lib.types.str;
        description = "Imageboard root URL";
        example = "https://transportation.example.com";
      };

      boards = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "List of board pathparts to archive";
        example = [ "t" ];
      };
    };
  };

  # Submodule for a single chandelorean service instance
  instanceModule = { config, ... }: {
    options = {
      user = lib.mkOption {
        type = lib.types.str;
        default = "chandelorean";
        description = "User to run the service as";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "chandelorean";
        description = "Group to run the service as";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.callPackage (pkgs.fetchFromGitHub {
          owner = "towards-a-new-leftypol";
          repo = "chandelorean";
          rev = "44b009613e8c2fcffe5116a28c2ab71004877f05";
          fetchSubmodules = true;
          sha256 = "sha256-pI4YTXAOwkqursVqc7LSMmNNjcoght4WAqoEqXJmKV4=";
        }) {};
        description = "Chandelorean package to use";
      };

      # Global settings
      postgrest_url = lib.mkOption {
        type = lib.types.str;
        default = "http://localhost:3000";
        description = "URL of the PostgREST backend";
      };

      jwt = lib.mkOption {
        type = lib.types.str;
        description = "JWT token for PostgREST authentication";
      };

      media_root_path = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/chandelorean/media";
        description = "Root path where archived media will be stored";
      };

      http_fill_all = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to backfill all threads immediately";
      };

      http_sync_continously = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to continuously sync new posts";
      };

      sync_max_concurrent_workers = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Maximum number of concurrent archiving workers";
      };

      sync_loop_timeout_microseconds = lib.mkOption {
        type = lib.types.int;
        default = 5000000;  # 5 seconds
        description = "Timeout between sync loops in microseconds";
      };

      # List of websites to archive
      websites = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule websiteModule);
        description = "List of websites to archive";
      };
    };
  };
in
{
  options.services.chandelorean = lib.mkOption {
    type = with lib.types; attrsOf (submodule instanceModule);
    default = {};
    description = "Chandelorean archive service instances";
  };

  config = lib.mkIf (config.services.chandelorean != {}) {
    users.groups = lib.genAttrs
      (lib.unique (lib.concatMap (i: [i.group]) (lib.attrValues config.services.chandelorean)))
      (name: {});

    users.users = lib.foldl' (acc: instanceCfg:
      acc // {
        ${instanceCfg.user} = {
          group = instanceCfg.group;
          isSystemUser = true;
          home = "/var/lib/chandelorean";
          description = "Chandelorean archive service user";
        };
      }
    ) {} (lib.attrValues config.services.chandelorean);

    systemd.services = lib.mapAttrs' (name: instanceCfg: let
      # Build the settings JSON from Nix config
      settingsJSON = builtins.toJSON {
        websites = instanceCfg.websites;
        postgrest_url = instanceCfg.postgrest_url;
        jwt = instanceCfg.jwt;
        media_root_path = instanceCfg.media_root_path;
        http_fill_all = instanceCfg.http_fill_all;
        http_sync_continously = instanceCfg.http_sync_continously;
        sync_max_concurrent_workers = instanceCfg.sync_max_concurrent_workers;
        sync_loop_timeout_microseconds = instanceCfg.sync_loop_timeout_microseconds;
      };

      settingsFile = pkgs.writeText "chandelorean-${name}-settings.json" settingsJSON;
    in {
      name = "chandelorean-${name}";
      value = {
        description = "Chandelorean archive service: ${name}";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          User = instanceCfg.user;
          Group = instanceCfg.group;
          ExecStart = "${instanceCfg.package}/bin/chan-delorean-consoomer +RTS -N2 -RTS -s ${settingsFile}";
          Restart = "on-failure";
          RestartSec = 5;
          LimitNOFILE = "65536";
        };

        preStart = ''
          mkdir -p "${instanceCfg.media_root_path}"
          chown -R ${instanceCfg.user}:${instanceCfg.group} "${instanceCfg.media_root_path}"
        '';
      };
    }) config.services.chandelorean;

    environment.systemPackages = lib.attrValues (lib.mapAttrs (_: i: i.package) config.services.chandelorean);
  };
}
