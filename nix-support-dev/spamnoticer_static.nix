{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "spamnoticer-static";
  version = "0.0.1";

  src = builtins.fetchGit {
    url = "https://git.leftychan.net/0/spamnoticer_static.git";
    ref = "master";
    #rev = "1a1f039be54f70d6f569d42bcb8d57d87fca8792";
  };

  installPhase = ''
    mkdir -p $out
    cp -R ./* $out
  '';

  meta = {
    description = "Front-end code for administrating SpamNoticer";
    homepage = "https://git.leftychan.net/0/spamnoticer_static";
    changelog = "https://git.leftychan.net/0/spamnoticer_static/commits/branch/master";
    platforms = pkgs.lib.platforms.all;
  };
}
