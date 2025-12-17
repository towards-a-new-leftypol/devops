{ config, pkgs, lib, ... }:

let
  instanceModule = { config, ... }: {
    options = with lib.types; {
      connectionString = lib.mkOption {
        type = str;
        description = "PostgreSQL connection string";
        example = "postgres://user:password@host:port/db";
      };

      schemaName = lib.mkOption {
        type = str;
        default = "public";
        description = "PostgreSQL schema name";
      };

      anonRole = lib.mkOption {
        type = str;
        description = "PostgreSQL anonymous role";
        example = "anonymous";
      };

      jwtSecret = lib.mkOption {
        type = str;
        description = "Base64-encoded JWT secret";
      };

      user = lib.mkOption {
        type = str;
        default = "postgrest";
        description = "User to run the service as";
      };

      group = lib.mkOption {
        type = str;
        default = "postgrest";
        description = "Group to run the service as";
      };

      package = lib.mkOption {
        type = package;
        default = pkgs.postgrest;
        description = "PostgREST package to use";
      };

      port = lib.mkOption {
        type = port;
        default = 3000;
        description = "Port to listen on";
      };

      enableAggregates = lib.mkOption {
        type = bool;
        default = false;
        description = "Enable support for aggregate functions (e.g., count, sum) in queries";
      };
    };
  };
in

{
  options.services.my_postgrest = lib.mkOption {
    type = with lib.types; attrsOf (submodule instanceModule);
    default = {};
    description = "Multiple PostgREST instances";
  };

  config = lib.mkIf (config.services.my_postgrest != {}) {
    users.groups = lib.genAttrs
      (lib.unique (lib.concatMap (i: [i.group]) (lib.attrValues config.services.my_postgrest)))
      (name: {});

    users.users = lib.foldl' (acc: instanceCfg:
      acc // {
        ${instanceCfg.user} = {
          group = instanceCfg.group;
          isSystemUser = true;
        };
      }
    ) {} (lib.attrValues config.services.my_postgrest);

    systemd.services = lib.mapAttrs' (name: instanceCfg: let
      configFile = pkgs.writeText "postgrest-${name}.conf" ''
        db-uri = "${instanceCfg.connectionString}"
        db-schema = "${instanceCfg.schemaName}"
        db-anon-role = "${instanceCfg.anonRole}"
        jwt-secret = "${instanceCfg.jwtSecret}"
        secret-is-base64 = false
        server-port = ${toString instanceCfg.port}
        ${lib.optionalString instanceCfg.enableAggregates "db-aggregates-enabled = true"}
      '';
    in {
      name = "postgrest-${name}";
      value = {
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          User = instanceCfg.user;
          Group = instanceCfg.group;
          ExecStart = "${instanceCfg.package}/bin/postgrest ${configFile}";
          KillSignal = "SIGTERM";
          #Restart = "on-failure";
        };
      };
    }) config.services.my_postgrest;

    environment.systemPackages = lib.attrValues (lib.mapAttrs (_: i: i.package) config.services.my_postgrest);
  };
}
