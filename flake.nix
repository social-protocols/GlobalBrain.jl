{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nixpkgs-sqlite = {
      # bug blocking from upgrading: https://www.sqlite.org/forum/forumpost/6e42c65eb8
      # sqlite 3.45.1 - https://www.nixhub.io/packages/sqlite-interactive
      url = "github:NixOS/nixpkgs/807c549feabce7eddbf259dbdcec9e0600a0660d"; 
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # for `flake-utils.lib.eachSystem`
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-sqlite,
    flake-utils
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [];
          config.allowUnfree = false;
        };
        pkgs-sqlite = import nixpkgs-sqlite { inherit system; };
        build_packages = with pkgs; [
          git
          diffutils
          jq
          pkgs-sqlite.sqlite-interactive
          julia_19-bin
          nodejs_20
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
