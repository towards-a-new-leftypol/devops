{ config, pkgs, lib, ... }:

let
  spamnoticer_dbpassword = lib.fileContents ./secrets/spamnoticer/dbpassword;
  chan_archiver_password = lib.fileContents ./secrets/chan_archives/chan_archives_dbpassword;
  chan_archiver_pgrest_jwt = lib.fileContents ./secrets/chan_archives/jwt;

in

{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/lxc-container.nix>
    ./users.nix
    ./nginx.nix
    ./mysql.nix
    ./lainchan.nix
    # #./mediawiki.nix
    # ./cytube-nix/cytube.nix
    ./postgresql.nix
    ./postgrest.nix
    # ./spamnoticer.nix
    ./chandelorean.nix
    ./chandlr-server.nix
  ];

  environment.systemPackages = with pkgs; [
    neovim
    wget
    gitAndTools.gitFull
    inetutils
    python3
    ripgrep
    dig
    tcpdump
    rsync
    (import ./spamnoticer_static.nix {})
  ];

  boot.isContainer = true;
  
  services.openssh.enable = true;
  services.openssh.startWhenNeeded = false;
  services.openssh.settings.PasswordAuthentication = false;
  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];

  # services.my_postgrest."leftypol_test" = {
  #   connectionString = "postgres://spam_noticer:${spamnoticer_dbpassword}@localhost:5432/leftypol_test";
  #   anonRole = "leftypol_anon";
  #   jwtSecret = lib.fileContents ./secrets/spamnoticer/jwt_secret;
  #   port = 3000;
  # };

  services.my_postgrest."chan_archives" = {
    connectionString = "postgres://chan_archiver:${chan_archiver_password}@localhost:5432/chan_archives";
    anonRole = "chan_archive_anon";
    jwtSecret = lib.fileContents ./secrets/chan_archives/jwt_secret;
    port = 3001;
    enableAggregates = true;
  };

  # services.spamnoticer = {
  #   enable = true;
  #   postgrestUrl = "http://localhost:3000";
  #   jwt = lib.fileContents ./secrets/spamnoticer/jwt;
  #   spamContentDir = "/srv/http/spam";
  #   port = 3300;
  #   debug = true;
  # };

  services.chandelorean.transportation = {
    websites = [
        {
          name = "transportation";
          root_url = "https://transportation.volguine.com";
          boards  = [
            "c"
          ];
        }
    ];

    group = "nginx";
    postgrest_url = "http://localhost:3001";
    media_root_path = "/srv/http/chan_archive_media";
    jwt = chan_archiver_pgrest_jwt;
  };

  services.chandlr-server.transportation = {
    postgrestUrl = "https://transportation-pgrest.volguine.com";
    jwt = chan_archiver_pgrest_jwt;
    postgrestFetchCount = 200;
    mediaRoot = "https://transportation-archive-media.volguine.com";
    # mediaRootPath = config.services.chandelorean.transportation.media_root_path;
    mediaRootPath = "/srv/http/chan_archive_media";
    admin = false;
    port = 8100;
  };

  networking.firewall.allowedTCPPorts = [
    22   # ssh
    80
    8080 # http
    # 443  # https
    # 8081 # cytube http
    3001   # postgrest chan_archives
    # 3000 # postgREST (should be open on dev only)
    # 8300 # SpamNoticer
    # 5432 # postgresql
  ];

  networking.hostName = "LPDev-Linixy";
  networking.useDHCP = false;
  networking.interfaces.eth0.ipv4.addresses =
    [{ address = "10.0.100.2"; prefixLength = 24; }];
  networking.defaultGateway = "10.0.100.1";
  networking.nameservers = [ "192.168.4.2" ];
  #networking.interfaces.eth0.useDHCP = true;

  system.stateVersion = "23.05";
}
