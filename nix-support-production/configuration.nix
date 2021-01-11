{ config, pkgs, lib, ... }:

{
  imports = [
    ./users.nix
    ./lainchan.nix
    ./tor.nix
    ./netdata.nix
  ];

  environment.systemPackages = with pkgs; [
    neovim
    wget
    gitAndTools.gitFull
    inetutils
  ];

  boot.isContainer = true;
  environment.noXlibs = true;
  
  services.openssh.enable = true;
  services.openssh.startWhenNeeded = false;
  services.openssh.passwordAuthentication = false;
  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];

  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.hostName = "LPProd";
  networking.nameservers = [ "213.186.33.99" ];
}
