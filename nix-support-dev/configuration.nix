{ config, pkgs, lib, ... }:

let
  spamnoticer_dbpassword = lib.fileContents ./secrets/spamnoticer/dbpassword;

in

{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/lxc-container.nix>
    ./users.nix
    ./nginx.nix
    ./mysql.nix
    ./lainchan.nix
    #./mediawiki.nix
    ./cytube-nix/cytube.nix
    ./postgresql.nix
    ./postgrest.nix
    ./spamnoticer.nix
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
    dig
    tcpdump
    (import ./spamnoticer_static.nix {})
  ];

  boot.isContainer = true;
  
  services.openssh.enable = true;
  services.openssh.startWhenNeeded = false;
  services.openssh.settings.PasswordAuthentication = false;
  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];

  nixpkgs.overlays = [ (import ./postgrest-overlay.nix { inherit pkgs; }) ];

  services.postgrest = {
    enable = true;
    connectionString = "postgres://spam_noticer:${spamnoticer_dbpassword}@localhost:5432/leftypol_test";
    anonRole = "leftypol_anon";
    jwtSecret = lib.fileContents ./secrets/spamnoticer/jwt_secret;
  };

  services.spamnoticer = {
    enable = true;
    postgrestUrl = "http://localhost:3000";
    jwt = lib.fileContents ./secrets/spamnoticer/jwt;
    spamContentDir = "/srv/http/spam";
    port = 3300;
    debug = true;
  };

  networking.firewall.allowedTCPPorts = [
    22   # ssh
    8080 # http
    443  # https
    8081 # cytube http
    # 3000 # postgREST (should be open on dev only)
    # 8300 # SpamNoticer
    # 5432 # postgresql
    #80   # apache (mediawiki)
  ];

  networking.hostName = "LPDev";
  networking.nameservers = [ "213.186.33.99" ];

  system.stateVersion = "23.05";
}
