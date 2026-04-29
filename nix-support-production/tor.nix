{ config, ... }:

{
  services.tor = {
    enable = true;

    # uncomment for more logging if relay daemon keeps crashing:
    settings.Log = [ "notice syslog" "info syslog" ];

    relay.onionServices.leftypol-onion = {
      version = 3;
      map = [
        {
          port = 80;
          target = {
            port = 8081;
          };
        }
      ];
    };

    relay.onionServices.leftychan-onion = {
      version = 3;
      map = [
        {
          port = 80;
          target = {
            port = 8081;
          };
        }
      ];
    };
  };
}
