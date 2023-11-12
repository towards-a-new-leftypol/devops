{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "spamnoticer-static";
  version = "0.0.3";

  src = builtins.fetchGit {
    url = "https://git.leftychan.net/0/spamnoticer_static.git";
    #ref = "master";
    rev = "23169e0533c628a186522d3a67747f322fb42ca0";
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
