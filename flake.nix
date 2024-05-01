{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # for `flake-utils.lib.eachSystem`
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [];
          config.allowUnfree = false;
        };
      in {
        devShells = {
          default = with pkgs;
            pkgs.mkShellNoCC {
              buildInputs = [
                just
                git
                gh
                diffutils
                jq
                openssh # Necessary to run git on macs
                julia_19-bin
                # libgcc
                sqlite-interactive
                litecli
                vim
                neovim
                less
                fzf
                cloc
                entr
                nodejs_21
                python3
                earthly
                jq
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
            };

        };
        packages = {
          ci = pkgs.buildEnv {
            name = "ci-build-env";
            paths = with pkgs; [
                julia_19-bin
                python3
                gnumake
                gnused
                gcc
                nodejs_21
                sqlite
                diffutils
                jq
            ];
          };
        };
      }
    );
}
