{
  description = "R build environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }: 
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryEnv;
      pythonEnv = mkPoetryEnv {
        python = pkgs.python311;
        preferWheels = true;
        projectDir = ./.;
      };
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
        buildInputs = with pkgs; [
          R-dev
          pythonEnv
          pandoc
          pkg-config
          readline
          python311
          poetry
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
