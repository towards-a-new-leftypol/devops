{ config, pkgs, lib, ... }:

let
  spamnoticer_dbpassword = lib.fileContents ./secrets/spamnoticer/dbpassword;

in

{
  imports = [
    ./hardware-configuration.nix
    ./users.nix
    ./nginx.nix
    ./mysql.nix
    ./lainchan.nix
    ./cytube-nix/cytube.nix
    ./tor.nix
    ./i2pd.nix
    ./netdata.nix
    ./postgresql.nix
    ./postgrest.nix
    ./spamnoticer.nix
  ];

  environment.systemPackages = with pkgs; [
    neovim
    wget
    gitFull
    inetutils
    python3
    ripgrep
    dig
    tcpdump
    rsync
    (import ./spamnoticer_static.nix {})
  ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.configurationLimit = 20;
  
  services.openssh.enable = true;
  services.openssh.startWhenNeeded = false;
  services.openssh.settings.PasswordAuthentication = false;
  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];

  time.timeZone = "UTC";

  services.my_postgrest = {
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
    80	 # http
    443  # https
  ];

  networking.hostName = "Spaceship";

  system.stateVersion = "23.11";
}
