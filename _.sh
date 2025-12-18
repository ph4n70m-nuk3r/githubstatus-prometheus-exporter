set -e

tput reset
pushd src
go mod tidy
popd
gomod2nix generate  --dir ./src/  --outdir ./
nix build .#app-bin
LOG_LEVEL='INFO' ./result/bin/githubstatus-prometheus-exporter
