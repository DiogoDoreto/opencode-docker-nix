{
  description = "OpenCode SST Docker image flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      opencodeCustomVersion = let
        version = "0.4.2";
      in pkgs.opencode.overrideAttrs (old: rec {
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "sst";
          repo = "opencode";
          rev = "v${version}";
          sha256 = "sha256-8qXmQfZGuCwlcKDm4hSNiHp8kWGK+liDT9ekUS45wso=";
        };
        nativeBuildInputs = old.nativeBuildInputs ++ [
          pkgs.makeBinaryWrapper
        ];
        # Wrap the binary with proper library paths to fix libstdc++.so.6 error
        postFixup = ''
          wrapProgram $out/bin/opencode \
            --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}"
        '';
        node_modules = old.node_modules.overrideAttrs (oldNM: {
          outputHash = "sha256-LmNn4DdnSLVmGS5yqLyk/0e5pCiKfBzKIGRvvwZ6jHY=";
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
