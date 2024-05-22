{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

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
          nodejs_20
          python3 # for node-gyp
          gcc
          gnumake
          gnused
          clang
          llvmPackages.libcxxStdenv
          llvmPackages.libcxx
          llvmPackages.libcxxabi
          llvmPackages.clang
          libcxxStdenv
          libcxx
          libcxxabi
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
                  xcbuild
                ];
            };
          build = pkgs.mkShellNoCC {
            buildInputs = build_packages;
          };
        };
      }
    );
}
