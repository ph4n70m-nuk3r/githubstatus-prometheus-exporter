{
	description = "Flake to build Go app + OCI image.";
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		gomod2nix.url = "github:nix-community/gomod2nix";
		gomod2nix.inputs.nixpkgs.follows = "nixpkgs";
	};
	outputs = { self, nixpkgs, gomod2nix, ...	} @inputs:
	let
		forEachSystem = nixpkgs.lib.genAttrs (import ./systems.nix);
	in {
		packages = forEachSystem (system: rec {
			pkgs = nixpkgs.legacyPackages.${system};
			callPackage = pkgs.callPackage;
			app-bin = callPackage ./app-bin.nix {
				inherit (pkgs) stdenv;
				inherit (gomod2nix.legacyPackages.${system}) buildGoApplication;
			};
			ca-certs = callPackage ./ca-certs.nix {};
			oci-image = callPackage ./oci-image.nix {
				app-bin = app-bin;
				ca-certs = ca-certs;
			};
			default = oci-image;
		});
		devShells = forEachSystem (system: rec {
			pkgs = nixpkgs.legacyPackages.${system};
			callPackage = pkgs.callPackage;
			default = callPackage ./shell.nix {
				inherit (gomod2nix.legacyPackages.${system}) mkGoEnv gomod2nix;
			};
		});
	};
}
