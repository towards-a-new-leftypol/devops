{ config, pkgs, lib, ... }:

let
  spgist = pkgs.callPackage ./pg_spgist_nix/default.nix {};

  initScript = builtins.toFile "init-script.sql" (
    (builtins.readFile "${spgist}/init.sql") + ''

    CREATE EXTENSION pg_trgm;
  '');
in

{
  services.postgresql = {
      enable = true;
      #enableTCPIP = true;
      package = pkgs.postgresql;
      authentication = ''
          host    all     all     localhost       password
      '';
      settings = {
        shared_buffers = "2GB";
        work_mem = "16MB";
      };

      ensureDatabases = [ "leftypol_test" ];

      ensureUsers = [
        {
          name = "admin";
          ensurePermissions = {
            "DATABASE \"leftypol_test\"" = "ALL PRIVILEGES";
            "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES";
          };
        }
      ];

      initialScript = initScript;

      extraPlugins = [
        spgist
      ];
  };
}

