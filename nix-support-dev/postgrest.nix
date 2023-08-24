{ config, pkgs, lib, ... }:

let
  cfg = config.services.postgrest;

  postgrestConfig = ''
    db-uri = "${cfg.connectionString}"
    db-schema = "${cfg.schemaName}"
    db-anon-role = "${cfg.anonRole}"
    jwt-secret = "${cfg.jwtSecret}"
    secret-is-base64 = true
  '';

  configFileLocation = pkgs.writeText "postgrest.cfg" postgrestConfig;
in

{
  options = {
    services.postgrest = with lib; {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = "Enable PostgREST service";
      };

      connectionString = mkOption {
        type = types.str;
        description = "Postgresql connection string";
        example = "postgres://pg_username:pg_password@192.168.1.11:5432/db_name";
      };

      schemaName = mkOption {
        type = types.str;
        description = "Postgresql schema the database is in";
        default = "public";
      };

      anonRole = mkOption {
        type = types.str;
        description = "Postgresql role that will be used for unauthenticated access.";
        example = "anonymous";
      };

      jwtSecret = mkOption {
        type = types.str;
        description = "base64 encoded jwt secret (see postgrest quick start documentation)";
      };

      user = mkOption {
        type = types.str;
        default = "postgrest";
        description = "User the PostgREST server will run as";
      };

      group = mkOption {
        type = types.str;
        default = "postgrest";
        description = "Group the PostgREST server will run as";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      haskellPackages.postgrest
    ];

    systemd.services.postgrest = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        #Restart = "on-failure";
        ExecStart = "${pkgs.haskellPackages.postgrest}/bin/postgrest ${configFileLocation}";
        KillSignal = "SIGQUIT";
      };
    };

    users.groups = {
      ${cfg.group} = {};
    };

    users.extraUsers.${cfg.user} = {
      group = cfg.group;
      isSystemUser = true;
    };

  };
}
