{ config, pkgs, lib, ... }:

let
  pg = pkgs.postgresql_14;
  spgist = pkgs.callPackage ./pg_spgist_nix/default.nix { postgresql = pg; };

  # initScript = builtins.toFile "init-script.sql" (
  #   (builtins.readFile "${spgist}/init.sql") + ''

  #   CREATE EXTENSION pg_trgm;
  # '');
in

{
  services.postgresql = {
      enable = true;
      enableTCPIP = true;
      package = pg;
      authentication = ''
          host    all     all     localhost            md5
      '';
      settings = {
        shared_buffers = "2GB";
        work_mem = "16MB";
      };

      #ensureDatabases = [ "leftypol_test" ];

      ensureUsers = [
        {
          name = "admin";
          ensureClauses = {
            createrole = true;
            createdb = true;
          };
        }
      ];

      # initialScript = initScript;

      extraPlugins = [
        spgist
      ];
  };
}

