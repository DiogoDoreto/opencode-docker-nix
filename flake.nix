{
  description = "OpenCode SST Docker image flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      opencodeCustomVersion = let
        # newer versions are broken (last version checked 0.3.117).
        # see https://github.com/sst/opencode/issues/1521
        version = "0.3.61";
      in pkgs.opencode.overrideAttrs (old: {
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "sst";
          repo = "opencode";
          rev = "v${version}";
          sha256 = "sha256-0N4VsGa3l8IWy8YMCuDQJoxWxTQtXQBt0scyPPiRwvI=";
        };
        node_modules = old.node_modules.overrideAttrs (oldNM: {
          outputHash = "sha256-ZMz7vfndYrpjUvhX8L9qv/lXcWKqXZwvfahGAE5EKYo=";
        });
        tui = old.tui.overrideAttrs (oldTui: {
          vendorHash = "sha256-gvWD8ILnA5NxGpiNMcNFUI6YVLMeRGz45pDk0G5zBjc=";
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
