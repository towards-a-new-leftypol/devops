{ config, pkgs, lib, ... }:

let
  chandlr-miso-bin = import ./chandlr-miso-bin.nix { inherit pkgs; };

  chandlr-server-src = pkgs.fetchFromGitHub {
    owner = "towards-a-new-leftypol";
    repo = "chandlr-server";
    rev = "5015b8e343ec8f5c98438540a6fa0643c92ed40c";
    fetchSubmodules = true;
    sha256 = "sha256-j/t/J543vq7zpM0WJHjiqAL4nNSBscVRHq3zXUM2siA=";
  };

  instanceModule = { config, ... }: {
    options = with lib.types; {
      # Database settings
      postgrestUrl = lib.mkOption {
        type = str;
        description = "URL of the PostgREST service";
        example = "https://pgrest.example.com";
      };

      jwt = lib.mkOption {
        type = str;
        description = "JWT token for authentication with PostgREST";
        example = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiY2hhbl9hcmNoaXZlciJ9.rGIKZokTDKTuQLIv8138bUby5PELfDipYYIDpJzH02c";
      };

      postgrestFetchCount = lib.mkOption {
        type = int;
        default = 200;
        description = "Number of items to fetch from PostgREST at once";
      };

      # Media settings
      mediaRoot = lib.mkOption {
        type = str;
        description = "Base URL for media files";
        example = "https://chan_media.example.com";
      };

      mediaRootPath = lib.mkOption {
        type = str;
        description = "Filesystem path to media files";
        default = "/var/lib/chandelorean/media";
      };

      staticServePath = lib.mkOption {
        type = str;
        description = "Filesystem path to static files";
        default = "${chandlr-miso-bin}/static";
      };

      staticServeUrlRoot = lib.mkOption {
        type = str;
        default = "/static";
        description = "URL root for static files";
      };

      # Admin settings
      admin = lib.mkOption {
        type = bool;
        default = false;
        description = "Whether to enable admin features";
      };

      # Service settings
      user = lib.mkOption {
        type = str;
        default = "chandlr";
        description = "User to run the service as";
      };

      group = lib.mkOption {
        type = str;
        default = "chandlr";
        description = "Group to run the service as";
      };

      package = lib.mkOption {
        type = package;
        default = pkgs.callPackage (chandlr-server-src) {};
        description = "chandlr-server package to use";
      };

      port = lib.mkOption {
        type = port;
        default = 8080;
        description = "Port to listen on";
      };

      extraEnvironment = lib.mkOption {
        type = attrsOf str;
        default = {};
        description = "Extra environment variables for the service";
      };

      extraServiceConfig = lib.mkOption {
        type = attrs;
        default = {};
        description = "Extra systemd service configuration";
      };
    };
  };
in

{
  options.services.chandlr-server = lib.mkOption {
    type = with lib.types; attrsOf (submodule instanceModule);
    default = {};
    description = "Multiple chandlr-server instances";
  };

  config = lib.mkIf (config.services.chandlr-server != {}) {
    # Create groups for all instances
    users.groups = lib.genAttrs
      (lib.unique (lib.concatMap (i: [i.group]) (lib.attrValues config.services.chandlr-server)))
      (name: {});

    # Create users for all instances
    users.users = lib.foldl' (acc: instanceCfg:
      acc // {
        ${instanceCfg.user} = {
          group = instanceCfg.group;
          isSystemUser = true;
        };
      }
    ) {} (lib.attrValues config.services.chandlr-server);

    # Create systemd services
    systemd.services = lib.mapAttrs' (name: instanceCfg: let
      # Generate settings.json from configuration
      settingsFile = pkgs.writeText "chandlr-server-${name}-settings.json" (builtins.toJSON {
        postgrest_url = instanceCfg.postgrestUrl;
        jwt = instanceCfg.jwt;
        postgrest_fetch_count = instanceCfg.postgrestFetchCount;
        media_root = instanceCfg.mediaRoot;
        media_root_path = instanceCfg.mediaRootPath;
        static_serve_path = instanceCfg.staticServePath;
        static_serve_url_root = instanceCfg.staticServeUrlRoot;
        admin = instanceCfg.admin;
      });
    in {
      name = "chandlr-server-${name}";
      value = {
        description = "chandlr-server instance ${name}";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        environment = instanceCfg.extraEnvironment // {
          PORT = toString instanceCfg.port;
        };
        serviceConfig = {
          Type = "simple";
          User = instanceCfg.user;
          Group = instanceCfg.group;
          ExecStart = "${instanceCfg.package}/bin/chandlr-server -s ${settingsFile}";
          KillSignal = "SIGTERM";
          Restart = "on-failure";
          # Allow binding to privileged ports if needed
          CapabilityBoundingSet = lib.optional (instanceCfg.port < 1024) "CAP_NET_BIND_SERVICE";
          AmbientCapabilities = lib.optional (instanceCfg.port < 1024) "CAP_NET_BIND_SERVICE";
        } // instanceCfg.extraServiceConfig;
      };
    }) config.services.chandlr-server;
  };
}
