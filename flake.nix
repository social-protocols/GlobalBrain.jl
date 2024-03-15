{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # for `flake-utils.lib.eachSystem`
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ ];
          config = {
            allowUnfree = false;
            packageOverrides = super: let self = super.pkgs; in
            {
              rEnv = super.rWrapper.override {
                packages = with self.rPackages; [
                    shiny
                    shinydashboard
                    DBI
                    RSQLite
                    dplyr
                    tidyr
                    r2d3
                    languageserver
                ];
              };
            };
          };
        };
      in
      {
        devShells = {
          default = with pkgs; pkgs.mkShellNoCC {
            buildInputs = [
              just
              git
              openssh # Necessary to run git on macs
              julia-bin
              # libgcc
              sqlite-interactive
              litecli
              vim
              neovim
              less
              fzf
              cloc
              entr
              rEnv
            ];
          };
        };
      }
    );
}


