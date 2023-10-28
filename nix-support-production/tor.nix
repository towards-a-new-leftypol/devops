{ config, ... }:

{
  services.tor = {
    enable = true;
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
