{ config, ... }:

{
  ## I2P Eepsite
  services.i2pd = {
    enable     = true;
    enableIPv4 = true;

    port       = 4000;
    ntcp2.port = 4401;

    inTunnels = {
      leftychan = {
        enable = true;
        #keys = "myEep-keys.dat";
        inPort = 80;
        address = "::1";
        destination = "::1";
        port = 8081;
        inbound.length = 1;
        outbound.length = 1;
      };
    };
  };
}
