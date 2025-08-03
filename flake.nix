{
  description = "OpenCode SST Docker image flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      opencodeCustomVersion = let
        version = "0.3.122";
        src = pkgs.fetchFromGitHub {
          owner = "sst";
          repo = "opencode";
          rev = "v${version}";
          sha256 = "sha256-JsyUXRfMQ40qQwtaW0Ebh/HlHqzb2D8AvsyJm5Yjm8E=";
        };
      in pkgs.opencode.overrideAttrs (old: {
        inherit version src;
        node_modules = old.node_modules.overrideAttrs (oldNM: {
          outputHash = "sha256-oZa8O0iK5uSJjl6fOdnjqjIuG//ihrj4six3FUdfob8=";
        });
        tui = old.tui.overrideAttrs (oldTui: {
          vendorHash = "sha256-LyF5bSglcoLFw0itGWGGW9h71C8qEKC9xAESNnh90Bo=";
          preBuild = ''
            cp -r ${src}/packages/sdk/go sdk-go
            substituteInPlace go.mod --replace "github.com/sst/opencode-sdk-go => ../sdk/go" "github.com/sst/opencode-sdk-go => ./sdk-go"
          '';
        });
      });
    in
    {
      packages.${system}.default = pkgs.dockerTools.buildImage {
        name = "opencode";
        tag = "latest";

        copyToRoot = pkgs.buildEnv {
          name = "image-root";
          paths = [
            pkgs.bash
            pkgs.coreutils
            pkgs.dockerTools.caCertificates
            pkgs.wget
            pkgs.curl
            pkgs.gnutar
            pkgs.unzip
            pkgs.fzf
            pkgs.ripgrep
            opencodeCustomVersion
          ];
          pathsToLink = [ "/bin" ];
        };

        config = {
          Cmd = [ "opencode" "." ];
          WorkingDir = "/app";
          Volumes = {
            "/app" = {};
          };
          Env = [
            "HOME=/root"
          ];
          ExposedPorts = {
            "4096/tcp" = {};
          };
        };
      };
    };
}
