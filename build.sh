## Print informational message. ##
echo ">>>>>>>>>> STARTING [$(date -Is)] <<<<<<<<<<"
## Exit on regular command failures. ##
set -e
## Fail script if a command which feeds into a pipe fails. ##
set -o pipefail
## Treat unset variables as failures if expanded. ##
set -u
## Allow user-provided build target. ##
if [ ${#@} -gt 1 ]
  then
    echo "Argument takes at most 1 argument, got ${#@}." 1>&2
    exit 1
  elif [ ${#@} -eq 0 ]
    then
      TARGET='default'
  else
    TARGET="${1}"
fi
## Disable basic command traces to prevent GH Token being leaked. ##
set +x
## Use PAT for Github to ease rate limiting. ##
read -r GH_PAT ./gh-pat.txt
export NIX_CONFIG="access-tokens = github.com=${GH_PAT}"
## Enable basic command traces. ##
set -x
## Run Go app built from flake. ##
nix \
  --extra-experimental-features 'nix-command' \
  --extra-experimental-features 'flakes' \
  build \
  .#"${TARGET}"
## Print informational message. ##
echo ">>>>>>>>>> FINISHED [$(date -Is)] <<<<<<<<<<"
## Exit success. ##
exit 0
