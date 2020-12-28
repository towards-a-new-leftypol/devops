{ config, ... }:

{
  users.mutableUsers = false;
  users.motd = ''
    _/        _/_/_/    _/_/_/                          
   _/        _/    _/  _/    _/    _/_/    _/      _/   
  _/        _/_/_/    _/    _/  _/_/_/_/  _/      _/    
 _/        _/        _/    _/  _/          _/  _/       
_/_/_/_/  _/        _/_/_/      _/_/_/      _/          

(leftypol development container, NixOS 20.09)
  '';

  users.extraUsers.admin = {
    isNormalUser = true;
    home = "/home/admin";
    description = "Sysadmin account. SSH into this.";
    extraGroups = [ "wheel" "nginx" "lainchan" ];

    # the password is password
    hashedPassword = "$6$mV1wguq77UrIH$i/gftmJYcg.OP6d3PgTTOmE/cQqGNqpspPYdwOc04otsdqkpLj1YKoa1QWp7Z.MApwofxawlQzfSGfO4AiUN2.";
    openssh.authorizedKeys.keys = [
        # Zer0's key, add your public key here
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBu2RKq+iiu2DoaeMlwhzGGGJww0qP1miyvBJ8OoDc8145XY9kw/LFQ8FbDG8jezszfpe6T6zEbpLFgEoj/ClrA= zer0@localhos"
        # Antinous's key
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDayOCrmPNQMsckY/ijvVaKtI2CMp6rwZjv920EF1m/PxRb6NqvvFTniatevnXK/QQ8xpDMAEfcm0yBHvQPjZAcsOLGby9FIoWeVe8zv3pJEdlG+HK9HC81tUpne1Tm0JQZh+Mcm9ptT/kq8Z96E/ifkzYiUWCB0VPONPzhqLf+PUV4MeAM1QRnI1sShG79MA3rpz017x6cCDjAuGuLWDdlsqCXmPsPv57csdGiuoKg+/QSC0jkDDHbXWlX+RHoCVi10/0E2UVf1EzDrudnBlaQRZi/MePXfuc1FEK85UmINHcZhz2vgOVzjujwQshsScggodQyKIvu4q4A+Pp2aCBj june_2020_droplet@gmail.com"
        #Barbara Pitt's key
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDUOhK4HLTeTaXUQ4LqqVWnTYh7hvKoEwpzMxqZ30FEvbPn9z0lipexRImNJKYuJWAkq3BYKrUKfblr7pL4hg++FcgZIXeMTdWyvaHlSbFZu1oR7xa7MhAVgBD59ZA0xevRr9K1CV5m/jHv8j+e1PANR8QZfwhcpzFdQ/RbKOKV1ag7kt3EqyYjlD95GvPES682Xn60/7/SIZEcXdfiwq1rBZvL/5i5taE1y+OiOgbu05d9YYCuEp8jO2T14xkVJ1BehNL6AssXIDGXxHah2LM2ZL+pPAoCRbjS8DKItgmfIQjUzmSJntWQ2TlO1PTVPtKmaUdHWZv8pQSX+MLY4F8/i5M4xcMTqUkA34iXLq11qz9RSAxT7uoevM756t7lgQfiVjWPSouyUrTESYjDWmRDQoNwS/iEqfY5gVhrogejDSYMVmPo0i4Ev785Q7UHGc1KkK0jZkQNWov6GOjVQWe3bOgq9R/T0A5PnTNObJRUUGRxpEWA+S9py0vfQwLhZJU= demo@nixos"

        #Acacio
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDWk70hNGDmWBR27UVP4H+ADovlXfbhGtOpRgeQpFTwiE+G630MWETn6kkPY/l73WjzGNWbVRmjjVInpoYQ658iQxihnjrbJLR85SwFvqQAXIi/NLQJX3n2ADacghMsULVrbUEbpXtZ9dhIRaj0PrRscmt149cZNM66eb0svRJf9v1OojltEyoC/jMHOu5OQPygncrkRVJORVaJmlSZnvQJ8OX+tVFOzqi/r+xBPaCyKbaaJ8z2naf0x1M3NxKaNC0Wx5kF2n6XtmWtxHWopDtZe+fim2l+Zax4RAExRR/moi2feJwNDGm27zjCE4V9PEV8cj2+OWSJGvQ0kJCY/KWcB5Ab0kZHnHEqd5l/8u8zY/muAUpcJOUYeIKCd2wkFU0AIns/r9z/cCx+iww5ITQbjA6g+0G6CPvejqWkcUMUSxxbyr+MIjFkoY+J/9sBXzC4OuCD2s33UDXRbaBEJcscvGLTPanUQkhzJ33pCuDKeoAM4OUVaTKdeDUim9+MvXk= masijo@navi"
    ];
  };

}
