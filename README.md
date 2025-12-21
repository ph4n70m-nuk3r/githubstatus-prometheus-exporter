# Minimalist prometheus exporter for githubstatus.com
![CI Status](https://github.com/ph4n70m-nuk3r/githubstatus-prometheus-exporter/actions/workflows/ci.yaml/badge.svg)

## Local Development  
### Prerequisites
Either:
- create `gh-pat.txt` file containing a GitHub Personal Access Token:  
- or, comment out lines `23` and `24` in `build.sh`.
-------------------------------------------
### Enter nix shell (ensure goEnv, gomod2nix, & dive are installed)
```shell
nix-shell --extra-experimental-features 'flakes' # OR: nix develop
```
-------------------------------------------
### Update gomod2nix definition (e.g. if packages have changed).
```shell
gomod2nix generate  --dir ./src/  --outdir ./
```
-------------------------------------------
### Build app
```shell
./build.sh app-bin
ls -lah result/bin/
```
-------------------------------------------
### Run app
```shell
./result/bin/githubstatus-prometheus-exporter # Use Ctrl+C to quit.
```
-------------------------------------------
### Build image (default build target)
```shell
./build.sh # OR: ./build.sh oci-image
ls -lah result
```
-------------------------------------------
### Load image
```shell
docker load < result
docker image ls
```
-------------------------------------------
### Run image
```shell
docker run -d --name='ghspe' --rm -p '8080:8080' githubstatus-prometheus-exporter:latest
```
-------------------------------------------
### Stop image
```shell
docker stop 'ghspe'
```
-------------------------------------------

## Using the app
### Routes
| path       | req-type | content-type       | description                |
|------------|----------|--------------------|----------------------------|
| `/`        | GET      | `text/html`        | Welcome page.              |
| `/info`    | GET      | `application/json` | Environment variables.     |
| `/metrics` | GET      | `text/plain`       | Prometheus format metrics. |
### cURL:
```shell
curl http://localhost:8080/metrics
```
### Browser:
- http://localhost:8080/
- http://localhost:8080/info
- http://localhost:8080/metrics  
