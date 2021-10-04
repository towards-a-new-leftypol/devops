{ pkgs, ... }:

{
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = [ "lainchan" "cytube" ];
    ensureUsers = [
      { name = "lainchan";
        ensurePermissions = { "lainchan.*" = "ALL PRIVILEGES"; };
      }
      { name = "admin";
        ensurePermissions = { "lainchan.*" = "ALL PRIVILEGES"; };
      }
      { name = "cytube";
        ensurePermissions = { "cytube.*" = "ALL PRIVILEGES"; };
      }
    ];

    settings.mysqld = {
      innodb_buffer_pool_size = 2147483648;
      innodb_buffer_pool_instances = 4;
    };
  };
}
