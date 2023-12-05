{ config, pkgs, lib, ... }:

let
  spgist = pkgs.callPackage ./pg_spgist_nix/default.nix {};

  # initScript = builtins.toFile "init-script.sql" (
  #   (builtins.readFile "${spgist}/init.sql") + ''

  #   CREATE EXTENSION pg_trgm;
  # '');
in

{
  services.postgresql = {
      enable = true;
      enableTCPIP = true;
      package = pkgs.postgresql_14;
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

