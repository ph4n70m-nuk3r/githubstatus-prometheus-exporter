package main

import (
    "crypto/x509"
    "encoding/json"
    "fmt"
    "github.com/labstack/echo/v4"
    "github.com/labstack/echo/v4/middleware"
    "io"
    "net/http"
    "os"
)

const (
    githubStatusUrl = "https://www.githubstatus.com/api/v2/components.json"
    metricName      = "github_status"
    certsFile       = "/etc/ssl/certs/ca-certificates.crt"
)

type Component struct {
    Name   string `json:"name"`
    Status string `json:"status"`
}

type GithubStatus struct {
    Components []Component `json:"components"`
}

func generateMetrics(githubStatus GithubStatus) string {
    var prometheusMetrics = ""
    prometheusMetrics += "# HELP " + metricName + " Github Status Metrics.\n"
    prometheusMetrics += "# TYPE " + metricName + " gauge\n"
    for _, component := range githubStatus.Components {
        var metricValue = "0.0"
        if component.Status == "operational" {
            metricValue = "1.0"
        }
        prometheusMetrics += metricName + "{" + "component=\"" + component.Name + "\"} " + metricValue + "\n"
    }
    return prometheusMetrics
}

func scrapeGithubStatus(c echo.Context) error {
    var githubStatus GithubStatus
    resp, err := http.Get(githubStatusUrl)
    if err != nil {
        return c.String(http.StatusInternalServerError, fmt.Sprintf("Error requesting githubstatus api: %s\n", err))
    }
    defer func(Body io.ReadCloser) {
        err := Body.Close()
        if err != nil {
            c.Logger().Warnf("Failed to close response body: {%v}", err)
        }
    }(resp.Body)
    body, err := io.ReadAll(resp.Body)
    if err := json.Unmarshal(body, &githubStatus); err != nil {
        return c.String(http.StatusInternalServerError, fmt.Sprintf("Error unmarshalling json from githubstatus api: %s\n", err))
    }
    return c.String(http.StatusOK, generateMetrics(githubStatus))
}

func info(c echo.Context) error {
    return c.JSON(http.StatusOK, os.Environ())
}

func favicon(c echo.Context) error {
    return c.HTML(http.StatusOK, "<link rel=\"icon\" href=\"data:;base64,=\">")
}

func home(c echo.Context) error {
    return c.HTML(http.StatusOK,
        "<!DOCTYPE html>" +
        "<html lang=\"en\">" +
        "<head>" +
            "<meta charset=\"utf-8\"><title>GithubStatus Prometheus Exporter</title>" +
        "</head>" +
        "<body>" +
            "<h1>GithubStatus Prometheus Exporter.</h1><br>" +
            "<br>" +
            "<h2>Routes:</h2>" +
            "<ul style=\"font-size: 2em;\">" +
                "<li><code>/        => [text/html]</code></li>" +
                "<li><code>/info    => [application/json]</code></li>" +
                "<li><code>/metrics => [text/plain]</code></li>" +
            "</ul>" +
        "</body>" +
        "</html>")
}

func initCaCerts() {
    rootCAs, _ := x509.SystemCertPool()
    if rootCAs == nil {
        rootCAs = x509.NewCertPool()
        certs, err := os.ReadFile(certsFile)
        if err != nil {
            panic(err)
        }
        if ok := rootCAs.AppendCertsFromPEM(certs); !ok {
            panic("Unable to append certs to tls.Config.RootCAs")
        }
    }
}

func main() {
    /* Load Certificates If No System Pool Found. */
    initCaCerts()
    /* Configure and Start Echo Server. */
    e := echo.New()
    e.Use(middleware.Logger())
    e.GET("/", home)
    e.GET("/favicon.ico", favicon)
    e.GET("/info", info)
    e.GET("/metrics", scrapeGithubStatus)
    e.Logger.Fatal(e.Start(":8080"))
}
