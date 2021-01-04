{ config, ... }:

{
  services.tor = {
    enable = true;
    hiddenServices = {
      leftypolOnion = {
        name = "leftypol-onion";
        version = 3;
        map = [
          { port = 80; toPort = 8081; }
        ];
      };
    };
  };
}
