{ config, pkgs, lib, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/lxc-container.nix>
    ./users.nix
    ./nginx.nix
    ./mysql.nix
    ./lainchan.nix
    #./mediawiki.nix
    ./cytube-nix/cytube.nix
    ./postgrest.nix
  ];

  environment.systemPackages = with pkgs; [
    neovim
    wget
    gitAndTools.gitFull
    inetutils
    python3
    ripgrep
    php
    phpPackages.composer
  ];

  boot.isContainer = true;
  
  services.openssh.enable = true;
  services.openssh.startWhenNeeded = false;
  services.openssh.settings.PasswordAuthentication = false;
  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];

  services.postgrest = {
    enable = true;
    connectionString = "postgres://spam_noticer:test_password@192.168.4.2:5432/leftypol_test";
    anonRole = "leftypol_anon";
    jwtSecret = "pJuvmNFgYCctNxMijeEbkQAhfHpuZirVOtpRQIPaEhQ=";
  };

  networking.firewall.allowedTCPPorts = [
    22   # ssh
    8080 # http
    443  # https
    8081 # cytube http
    3000 # postgREST (should be open on dev only)
    #80   # apache (mediawiki)
  ];

  networking.hostName = "LPDev";
  networking.nameservers = [ "213.186.33.99" ];
}
