{
  description = "R build environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: 
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      R-dev = pkgs.rWrapper.override {
        packages = with pkgs.rPackages; [
          languageserver
          systemfonts
          textshaping
          httr
          ragg
          httr2
          credentials
          openssl
          curl
          httpuv
          pkgdown
          gh
          gert
          usethis
          servr
          xslt
          # sandpaper
        ];
      };
    in {
      devShell = with pkgs; mkShellNoCC {
        name = "R";
        buildInputs = [
          R-dev
          pkgs.pandoc
          pkgs.pkg-config
          pkgs.readline
        ];

        # If for some reason you need to install
        # packages manually
        shellHook = ''
          mkdir -p "$(pwd)/_libs"
          export R_LIBS_USER="$(pwd)/_libs"
        '';
      };
    });
}
