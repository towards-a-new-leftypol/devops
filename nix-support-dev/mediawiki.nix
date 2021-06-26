{ ... }:

{
  services.mediawiki = {
    enable = false;

    virtualHost = {
      hostName = "wiki.leftypol.org:2052";
      adminAddr = "webmaster@leftypol.org";
      forceSSL = false;
      enableACME = false;
    };

    database = {
      user = "mediawiki";
      name = "mediawiki";
      #host = "127.0.0.1";
      #socket = "/var/run/mysqld/mysqld.sock";
      #passwordFile = ./secrets/mediawiki/db_password.txt;
      #createLocally = false;
    };

    passwordFile = ./secrets/mediawiki/password.txt;

    name = "Leftypedia";

    extensions = {
      Cite = null;
      ParserFunctions = null;
    };

    extraConfig = ''
      // Define constants for my additional namespaces.
      define("NS_ESSAY", 3000); // This MUST be even.
      // The odd index immediately following denotes its associated discussion (talk) page
      define("NS_ESSAY_TALK", 3001); // This MUST be the following odd integer.
      define("NS_RHETORIC", 3002);
      define("NS_RHETORIC_TALK", 3003);
      define("NS_ARCHIVE", 3004);
      define("NS_ARCHIVE_TALK", 3005);

      // Add namespaces.
      $wgExtraNamespaces[NS_ESSAY] = "Essay";
      $wgExtraNamespaces[NS_ESSAY_TALK] = "Essay_talk"; // Note underscores in the namespace name.
      $wgExtraNamespaces[NS_RHETORIC] = "Rhetoric";
      $wgExtraNamespaces[NS_RHETORIC_TALK] = "Rhetoric_talk";
      $wgExtraNamespaces[NS_ARCHIVE] = "Archive";
      $wgExtraNamespaces[NS_ARCHIVE_TALK] = "Archive_talk";
    '';
  };
}
