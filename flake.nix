{
	description = "Flake to build Go app + OCI image.";
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
	};
	outputs = {
	 self,
	 nixpkgs,
	 ...
	}:
	let
		forEachSystem = nixpkgs.lib.genAttrs [ "aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux" ];
		owner = "ph4n70m-nuk3r";
		repo = "githubstatus-prometheus-exporter";
		version = "0.1.0";
	in {
		## DevShells. ##
		devShells = forEachSystem (system: rec {
			pkgs = nixpkgs.legacyPackages.${system};
			## Default developer shell. ##
			default = pkgs.mkShell {
				packages = [ pkgs.go pkgs.dive ];
			};
		});
		## Packages. ##
		packages = forEachSystem (system: rec {
			pkgs = nixpkgs.legacyPackages.${system};
			## App src, used for building app bin. ##
			src = pkgs.fetchFromGitHub {
				inherit owner;
				inherit repo;
				rev = version;
				# obtained using command: 'nix flake prefetch github:<owner>/<repo>/<rev>'.
				hash = "sha256-J+LkFa5knaZs6h8/R0i+xa0yKhrSCxBMi7yt1hioBus=";
			};
			## App bin, built from app src. ##
			app-bin = pkgs.buildGoModule {
				pname = repo;
				inherit version;
				src = "${src}/src";
				vendorHash = "sha256-wXO9YgnKYHTWBAtUMUmM00JgyhUzSxIN4uM3AgH3DKI=";
				meta = {
					   homepage = "https://github.com/${owner}/${repo}";
					   description = "Minimal prometheus exporter for GitHub Status.";
					   license = pkgs.lib.licenses.mit;
				};
		   	};
			## CA certificates. ##
			ca-certs = pkgs.cacert.override {
            	#extraCertificateFiles = [ ./extra-ca-1.pem.crt ./extra-ca-2.pem.crt ];
            };
			## Web resources used by app, e.g. 'static/html/index.html'. ##
            static = pkgs.runCommand "isolated-static-files" { } ''
                ## Create dir and copy files manually.
                mkdir -p $out/
                cp -r -t $out/.  ${src}/static
            '';
			## Container image, including App bin, CA certs, and Web resources. ##
			oci-image = pkgs.dockerTools.buildLayeredImage {
				name = repo;
				tag = version;
				contents = [ ca-certs static ];
				config = {
					Cmd = [ "${app-bin}/bin/githubstatus-prometheus-exporter" ];
					Env = [
						"CURL_CA_BUNDLE=${ca-certs}/etc/ssl/certs/ca-bundle.crt"
						"SSL_CERT_FILE=${ca-certs}/etc/ssl/certs/ca-bundle.crt"
					];
				};
			};
			## Make oci-image the default target for nix build. ##
			default = oci-image;
		});
	};
}
