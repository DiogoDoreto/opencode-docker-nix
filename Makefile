result: flake.nix flake.lock
	nix build .

.PHONY: load-image
load-image: result
	podman load -i ./result
