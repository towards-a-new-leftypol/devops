{ config, ... }:

{
  ## I2P Eepsite
  services.i2pd = {
    enable     = true;
    enableIPv4 = true;
    enableIPv6 = true;

    port       = 4400;
    ntcp2.port = 4401;
    ntcp2.published = true;

    inTunnels = {
      leftychan = {
        enable = true;
        keys = "leftychmxz3wczbd4add4atspbqevzrtwf2sjobm3waqosy2dbua.dat";
        inPort = 80;
        address = "127.0.0.1";
        destination = "127.0.0.1";
        port = 8081;
        inbound.length = 1;
        outbound.length = 1;
      };
    };
  };
}
