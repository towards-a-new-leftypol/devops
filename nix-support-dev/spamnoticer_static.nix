{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "spamnoticer-static";
  version = "0.0.2";

  src = builtins.fetchGit {
    url = "https://git.leftychan.net/0/spamnoticer_static.git";
    #ref = "master";
    rev = "358b63564a3b9495a5732a08da80a0ef5c708f27";
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
