{ pkgs, ... }:

final: prev: {
  haskellPackages = prev.haskellPackages.override {
    overrides = let
      inherit (pkgs.haskell.lib.compose)
        doJailbreak
        markUnbroken
        overrideSrc
        overrideCabal
        addBuildDepends
      ;
    in
      self: super: {
        configurator-pg = pkgs.lib.pipe super.configurator-pg [
          markUnbroken
          doJailbreak
        ];
        fuzzyset = pkgs.lib.pipe super.fuzzyset [
          markUnbroken
          (overrideCabal (drv: {
            version = "0.2.4";
            sha256 = "sha256-tsOPShYkKxCccIwKj1aL4rURgXWN4N8HJyV5Jn5pRmY=";
            revision = "0";
            editedCabalFile = "sha256-8bbei/Myd79iVSB1QdZQKPHx6pOvVUG2VMhrVnSZVIU=";
          }))
          (addBuildDepends [
            self.data-default
          ])
        ];
        hasql-pool = pkgs.lib.pipe super.hasql-pool [
          (overrideCabal (drv: {
            version = "0.10";
            sha256 = "sha256-EeyKo3NPIpBLv6e7DVQYMus3soGtMC/IzKVg6qBWBZY=";
            revision = "0";
            editedCabalFile = "sha256-kSGXoyisuFUF+Yu5cA1h82a4dlnKRRJsXC1jZoe4AcM=";
          }))
        ];
        postgrest = pkgs.lib.pipe super.postgrest [
          (overrideSrc {
            version = "11.2.2";
            src = pkgs.fetchFromGitHub {
              owner = "PostgREST";
              repo = "postgrest";
              rev = "v11.2.2";
              hash = "sha256-6Nv0NSAiNUSg2T/cmWs7zGSInLSmF0WDA3E/KxlA7O8=";
            };
          })
          (addBuildDepends [
            self.extra self.fuzzyset self.cache self.timeit
          ])
        ];
      };
  };
}
