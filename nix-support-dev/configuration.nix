{ config, pkgs, lib, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/lxc-container.nix>
    ./users.nix
    ./nginx.nix
    ./mysql.nix
    ./lainchan.nix
    ./mediawiki.nix
    ./cytube-nix/cytube.nix
  ];

  environment.systemPackages = with pkgs; [
    neovim
    wget
    gitAndTools.gitFull
    inetutils
    python3
    ripgrep
    php74Packages.composer
  ];

  boot.isContainer = true;
  environment.noXlibs = true;
  
  services.openssh.enable = true;
  services.openssh.startWhenNeeded = false;
  services.openssh.passwordAuthentication = false;
  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];

  networking.firewall.allowedTCPPorts = [
    22   # ssh
    8080 # http
    443  # https
    8081 # cytube http
    #80   # apache (mediawiki)
  ];

  networking.hostName = "LPDev2";
  networking.nameservers = [ "213.186.33.99" ];
}
