## Build stage. ##
FROM docker.io/library/golang:1.24.4-alpine3.22 AS build
WORKDIR /app
COPY ./go.mod  ./main.go  ./
RUN go get \
 && go build -o main

## Runtime image. ##
FROM scratch
## Copy certificates from Alpine image. ##
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
## Copy compiled app from build stage. ##
COPY --from=build /app/main /go/bin/
EXPOSE 8080
ENTRYPOINT [ "/go/bin/main" ]
