{
  description = "OpenCode SST Docker image flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      opencodeCustomVersion =
        let
          version = "0.5.5";
        in
        pkgs.opencode.overrideAttrs (old: rec {
          inherit version;
          src = pkgs.fetchFromGitHub {
            owner = "sst";
            repo = "opencode";
            rev = "v${version}";
            sha256 = "sha256-FDAHu7tWa6M6XIargmr+dO722oD6O/nt+vreS3ag8og=";
          };
          node_modules = old.node_modules.overrideAttrs (oldNM: {
            outputHash = "sha256-/RdfDi1QMHlwvnx4wHKs2o1QwdGkHSOHG6yH0RtJdws=";
            patches = [
              (pkgs.fetchpatch {
                url = "https://github.com/sst/opencode/commit/5d5ac168a4233ee1f38581ec56b915733b12510c.patch";
                hash = "sha256-Odfmj2SjNB2phTX8c+rMKCGyPwWooH55vn//uizHr3g=";
              })
            ];
            buildPhase = ''
              runHook preBuild

              export BUN_INSTALL_CACHE_DIR=$(mktemp -d)

              # Disable post-install scripts to avoid shebang issues
              bun install \
                --filter=opencode \
                --force \
                --frozen-lockfile \
                --ignore-scripts \
                --no-progress \
                --production

              runHook postBuild
            '';
          });
          tui = old.tui.overrideAttrs (oldTui: {
            vendorHash = "sha256-acDXCL7ZQYW5LnEqbMgDwpTbSgtf4wXnMMVtQI1Dv9s=";
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
    in
    {
      packages.${system}.default = pkgs.dockerTools.buildLayeredImage {
        name = "opencode";
        tag = "latest";
        fromImage = baseImage;
        config = {
          Cmd = [
            "opencode"
            "."
          ];
          WorkingDir = "/app";
          Volumes = {
            "/app" = { };
          };
          ExposedPorts = {
            "4096/tcp" = { };
          };
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          bun
        ];
      };
    };
}
