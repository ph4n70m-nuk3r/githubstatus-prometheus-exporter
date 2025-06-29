# Minimalist prometheus exporter for githubstatus.com
## Routes  
| path       | content-type       | description                |
|------------|--------------------|----------------------------|
| `/`        | `text/html`        | Welcome page.              |
| `/info`    | `application/json` | Environment variables.     |
| `/metrics` | `text/plain`       | Prometheus format metrics. |

## Local Development  
### Prerequisites (Nix only)  
`nix-shell  --extra-experimental-features flakes`  
### Build  
`./_.sh`  
### Run  
`./main`  

## Docker Development
### Build  
`docker  build  -f Dockerfile  -t gh-status-exporter:latest  ./`
### Run  
`docker  run  --interactive  -tty  --publish 8080:8080  --rm  gh-status-exporter:latest`  
