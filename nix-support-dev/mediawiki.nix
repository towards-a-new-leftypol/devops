{ ... }:

{
  services.mediawiki.enable = true;
  services.mediawiki.virtualHost = {
    hostName = "wiki.leftypol.org:2052";
    adminAddr = "webmaster@leftypol.org";
    forceSSL = false;
    enableACME = false;
  };
  services.mediawiki.database.user = "mediawiki";
  services.mediawiki.database.name = "mediawiki";
  #services.mediawiki.database.host = "127.0.0.1";
  #services.mediawiki.database.socket = "/var/run/mysqld/mysqld.sock";
  #services.mediawiki.database.passwordFile = ./secrets/mediawiki/db_password.txt;
  #services.mediawiki.database.createLocally = false;
  services.mediawiki.passwordFile = ./secrets/mediawiki/password.txt;
}
