{
	stdenv,
	pkgs ? (
		let
			inherit (builtins) fetchTree fromJSON readFile;
			inherit ((fromJSON (readFile ./flake.lock)).nodes) nixpkgs gomod2nix;
		in
			import (fetchTree nixpkgs.locked) {
				overlays = [
					(import "${fetchTree gomod2nix.locked}/overlay.nix")
				];
			}
	),
	buildGoApplication ? pkgs.buildGoApplication
}:
(buildGoApplication {
		pname = "ph4n70m-nuk3r/githubstatus-prometheus-exporter";
		version = "1.3.0";
		pwd = ./src;
		src = ./src;
		modules = ./gomod2nix.toml;
}).overrideAttrs (old: {
	CGO_ENABLED = "0";
})
