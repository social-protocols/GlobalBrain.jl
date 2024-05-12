{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/ba733f8000925e837e30765f273fec153426403d";

    # for `flake-utils.lib.eachSystem`
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [];
          config.allowUnfree = false;
        };
        build_packages = with pkgs; [
          git
          diffutils
          jq
          sqlite-interactive
          julia_19-bin
          nodejs_21
          python3 # for node-gyp
          gcc
          gnumake
          gnused
          clang
          llvmPackages.libcxxStdenv
          llvmPackages.libcxx
          llvmPackages.clang
          libcxxStdenv
          libcxx
        ];
      in {
        devShells = {
          default = with pkgs;
            pkgs.mkShellNoCC {
              buildInputs =
                build_packages
                ++ [
                  just
                  gh
                  openssh # Necessary to run git on macs
                  litecli
                  vim
                  neovim
                  less
                  fzf
                  cloc
                  entr
                  earthly
                  docker
                ];
            };
          build = pkgs.mkShellNoCC {
            buildInputs = build_packages;
          };
        };
      }
    );
}
