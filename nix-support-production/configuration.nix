{ config, pkgs, lib, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/lxc-container.nix>
    ./users.nix
    ./nginx.nix
    ./lainchan.nix
    ./cytube-nix/cytube.nix
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

  networking.firewall.allowedTCPPorts = [ 22 8080 443 ];
  networking.hostName = "LPProd";
  networking.nameservers = [ "213.186.33.99" ];

  # Install new init script
  system.activationScripts.installInitScript = lib.mkForce ''
    mkdir -p /sbin
    ln -fs $systemConfig/init /sbin/init
  '';
}
