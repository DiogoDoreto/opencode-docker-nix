{
  description = "OpenCode SST Docker image flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      opencodeCustomVersion = let
        version = "0.4.1";
      in pkgs.opencode.overrideAttrs (old: rec {
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "sst";
          repo = "opencode";
          rev = "v${version}";
          sha256 = "sha256-LEFmfsqhCuGcRK7CEPZb6EZfjOHAyYpUHptXu04fjpQ=";
        };
        buildPhase = ''
          runHook preBuild

          bun build \
            --define OPENCODE_TUI_PATH="'${tui}/bin/tui'" \
            --define OPENCODE_VERSION="'${version}'" \
            --compile \
            --target=bun-linux-x64 \
            --outfile=opencode \
            ./packages/opencode/src/index.ts

          runHook postBuild
        '';
        node_modules = old.node_modules.overrideAttrs (oldNM: {
          outputHash = "sha256-7Hc3FJcg2dA8AvGQlS082fO1ehGBMPXWPF8N+sAHh2I=";
        });
        tui = old.tui.overrideAttrs (oldTui: {
          vendorHash = "sha256-jGaTgKyAvBMt8Js5JrPFUayhVt3QhgyclFoNatoHac4=";
        });
      });

      dockerNixVersion = "2.30.2";
      dockerNixModule = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/NixOS/nix/${dockerNixVersion}/docker.nix";
        sha256 = "sha256-JQKi6B6yE4JyRYcM/XUSrjRBhFiAcRFOw9/gv5a2k2U=";
      };

      baseImage = pkgs.callPackage (import dockerNixModule) {
        extraPkgs = [
          opencodeCustomVersion
        ];
        nixConf = {
          experimental-features = "nix-command flakes";
        };
      };
    in {
      packages.${system}.default = pkgs.dockerTools.buildLayeredImage {
        name = "opencode";
        tag = "latest";
        fromImage = baseImage;
        config = {
          Cmd = [ "opencode" "." ];
          WorkingDir = "/app";
          Volumes = {
            "/app" = {};
          };
          ExposedPorts = {
            "4096/tcp" = {};
          };
        };
      };
    };
}
