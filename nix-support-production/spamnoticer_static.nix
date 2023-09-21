{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "spamnoticer-static";
  version = "0.0.2";

  src = builtins.fetchGit {
    url = "https://git.leftychan.net/0/spamnoticer_static.git";
    #ref = "master";
    rev = "7be80cb4081a83814ced9e4c1bdaf8298dddf0bb";
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
