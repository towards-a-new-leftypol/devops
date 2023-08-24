{ pkgs, ... }:

{
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = [ "lainchan" "cytube" "mediawiki" ];
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
      { name = "mediawiki";
        ensurePermissions = { "mediawiki.*" = "ALL PRIVILEGES"; };
      }
    ];

    settings.mysqld.bind-address = "0.0.0.0";

    settings.mysqld = {
      innodb_buffer_pool_size = 2147483648;
      innodb_buffer_pool_instances = 4;
    };
  };

}
