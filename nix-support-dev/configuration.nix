{ config, pkgs, lib, ... }:

let
  spamnoticer_dbpassword = builtins.readFile ./secrets/spamnoticer/dbpassword;
  jwt_secret = builtins.readFile ./secrets/spamnoticer/jwt_secret;
  jwt = builtins.readFile ./secrets/spamnoticer/jwt;

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
    (import ./spamnoticer_static.nix {})
  ];

  boot.isContainer = true;
  
  services.openssh.enable = true;
  services.openssh.startWhenNeeded = false;
  services.openssh.settings.PasswordAuthentication = false;
  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];

  services.postgrest = {
    enable = true;
    connectionString = "postgres://spam_noticer:${spamnoticer_dbpassword}@/leftypol_test";
    anonRole = "leftypol_anon";
    jwtSecret = jwt_secret;
  };

  services.spamnoticer = {
    enable = true;
    postgrestUrl = "http://localhost:3000";
    jwt = jwt;
    spamContentDir = "/srv/http/spam";
    port = 3300;
    debug = true;
  };

  networking.firewall.allowedTCPPorts = [
    22   # ssh
    8080 # http
    443  # https
    8081 # cytube http
    3000 # postgREST (should be open on dev only)
    8300 # SpamNoticer
    #80   # apache (mediawiki)
  ];

  networking.hostName = "LPDev";
  networking.nameservers = [ "213.186.33.99" ];
}
