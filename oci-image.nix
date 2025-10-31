{
	pkgs,
	app-bin,
	ca-certs
}:
let
	static = pkgs.lib.fileset.toSource {
		root = ./.;
		fileset = ./static;
	};
in
	pkgs.dockerTools.buildLayeredImage {
		name = "githubstatus-prometheus-exporter";
		tag = "latest";
		contents = [ ca-certs static ];
		config = {
			Cmd = [ "${app-bin}/bin/githubstatus-prometheus-exporter" ];
			Env = [
				"CURL_CA_BUNDLE=${ca-certs}/etc/ssl/certs/ca-bundle.crt"
				"SSL_CERT_FILE=${ca-certs}/etc/ssl/certs/ca-bundle.crt"
			];
		};
	}
