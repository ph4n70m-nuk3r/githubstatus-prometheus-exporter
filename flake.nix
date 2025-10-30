{
	description = "Flake to build Go app + OCI image.";
	inputs = {
		nixpkgs = {
			url = "github:nixos/nixpkgs/nixos-unstable";
		};
		systems = {
			flake = false;
			url = "path:./flake.systems.nix";
		};
	};
	outputs = {
		systems,
		nixpkgs,
		self,
		...
	}: let
		eachSystem = nixpkgs.lib.genAttrs (import systems);
	in {
		packages = eachSystem (system: rec {
			pkgs = nixpkgs.legacyPackages.${system};

			ca-certs-overridden = pkgs.cacert.override {
#				extraCertificateFiles = [
#					./certs/corporate-ca.crt
#				];
			};

			app-bin = (pkgs.buildGoModule {
				pname = "ph4n70m-nuk3r/githubstatus-prometheus-exporter";
				version = "1.0.0";
				modRoot = ./src;
				src = ./src;
				vendorHash = null;
			}).overrideAttrs (old: {
				env.CGO_ENABLED = "0";
			});

			oci-image = pkgs.dockerTools.buildLayeredImage {
				name = "githubstatus-prometheus-exporter";
				tag = "latest";
				contents = with pkgs; [ ca-certs-overridden ];
				config = {
					Cmd = [ "${app-bin}/bin/githubstatus-prometheus-exporter" ];
					Env = [
						"CURL_CA_BUNDLE=${ca-certs-overridden}/etc/ssl/certs/ca-bundle.crt"
						"SSL_CERT_FILE=${ca-certs-overridden}/etc/ssl/certs/ca-bundle.crt"
					];
				};
			};

			default = oci-image;
		});
	};
}
