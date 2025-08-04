{
  description = "OpenCode SST Docker image flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      opencodeCustomVersion = let
        version = "0.3.128";
        src = pkgs.fetchFromGitHub {
          owner = "sst";
          repo = "opencode";
          rev = "v${version}";
          sha256 = "sha256-iS/RJ3PADze0C5wP31YE5nfxm7HJ9A3fVlvU1z8mNGI=";
        };
      in pkgs.opencode.overrideAttrs (old: {
        inherit version src;
        node_modules = old.node_modules.overrideAttrs (oldNM: {
          outputHash = "sha256-oZa8O0iK5uSJjl6fOdnjqjIuG//ihrj4six3FUdfob8=";
        });
        tui = old.tui.overrideAttrs (oldTui: {
          vendorHash = "sha256-k8LJq6KBqkAlmAi9XXSKVf1Y+zqrJRzXQwjsHurOLSw=";
          preBuild = ''
            cp -r ${src}/packages/sdk/go sdk-go
            substituteInPlace go.mod --replace "github.com/sst/opencode-sdk-go => ../sdk/go" "github.com/sst/opencode-sdk-go => ./sdk-go"
          '';
        });
      });
    in {
      packages.${system}.default = pkgs.dockerTools.buildLayeredImage {
        name = "opencode";
        tag = "latest";

        fromImage = pkgs.dockerTools.pullImage {
          imageName = "docker.io/nixos/nix";
          imageDigest = "sha256:7894650fb65234b35c80010e6ca44149b70a4a216118a6b7e5c6f6ae377c8d21";
          hash = "sha256-8eY/oaia3fchYReZOn4Darl1s11OEnN49kV4vvRkHsk=";
          finalImageTag = "latest";
        };

        contents = [
            # pkgs.bashInteractive
            # pkgs.coreutils
            opencodeCustomVersion
        ];

        # copyToRoot = pkgs.buildEnv {
        #   name = "image-root";
        #   paths = [
        #     pkgs.bashInteractive
        #     pkgs.coreutils
        #     # pkgs.nix
        #     # pkgs.dockerTools.caCertificates
        #     # pkgs.cacert
        #     opencodeCustomVersion
        #   ];
        #   pathsToLink = [ "/bin" ];
        # };

        extraCommands = ''
          # mkdir -p etc/nix
          # echo "experimental-features = nix-command flakes" >> etc/nix/nix.conf
          # mkdir -p root/.nix-profile/bin
          # ln -sf ${opencodeCustomVersion}/bin/opencode root/.nix-profile/bin/opencode
          # mkdir -p etc/ssl/certs
          # ln -sf ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt etc/ssl/certs/ca-certificates.crt
        '';

        config = {
          Cmd = [ "opencode" "." ];
          WorkingDir = "/app";
          Volumes = {
            "/app" = {};
          };
          # Env = [
          #   "NIX_PAGER=cat"
          #   "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
          #   "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
          # ];
          ExposedPorts = {
            "4096/tcp" = {};
          };
        };
      };
    };
}
