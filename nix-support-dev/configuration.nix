{ config, pkgs, lib, ... }:

{
  imports = [
    ./users.nix
    ./nginx.nix
    ./lainchan.nix
    ./cytube-nix/cytube.nix
  ];

  environment.systemPackages = with pkgs; [
    neovim
    wget
    gitAndTools.gitFull
    inetutils
    python3
    ripgrep
  ];

  boot.isContainer = true;
  environment.noXlibs = true;
  
  services.openssh.enable = true;
  services.openssh.startWhenNeeded = false;
  services.openssh.passwordAuthentication = false;
  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];

  networking.firewall.allowedTCPPorts = [
    22   # ssh
    8080   # http
    443  # https
    8081 # cytube http
  ];

  networking.hostName = "LPDev";
  networking.nameservers = [ "213.186.33.99" ];
}
