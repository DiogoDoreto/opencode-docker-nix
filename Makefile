result: flake.nix flake.lock
	nix build .

.PHONY: load-image
load-image: result
	podman load -i ./result

.PHONY: clean
clean:
	rm -rf ./result

.PHONY: clean-load-image
clean-load-image:
	$(MAKE) clean
	$(MAKE) load-image
