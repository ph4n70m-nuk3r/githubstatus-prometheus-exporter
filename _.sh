set -e
set -x
## Fetch dependencies. ##
go get
## Build app. ##
go build -o main
## Done. ##
exit 0
