package main

import (
	"crypto/x509"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/labstack/echo/v4"
// 	"github.com/labstack/echo/v4/middleware"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

const (
	githubStatusUrl = "https://www.githubstatus.com/api/v2/components.json"
	certsFile       = "/etc/ssl/certs/ca-certificates.crt"
)

var (
	logLevel      = os.Getenv("LOG_LEVEL")
	pollFrequency = os.Getenv("POLL_FREQUENCY")
	pollFrequencyParsed = time.Duration(0)

	GitHubStatusMetric = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "github_status",
			Help: "Status of the various GitHub components.",
		},
		[]string{"component"},
	)

	ScrapeStatusMetric = prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name: "scrape_status",
			Help: "Status of scrape for GitHub Status.",
		},
	)
)

type Component struct {
	Name   string `json:"name"`
	Status string `json:"status"`
}

type GithubStatus struct {
	Components []Component `json:"components"`
}

func init() {
	prometheus.MustRegister(GitHubStatusMetric)
	// Set default poll frequency of 30s if undefined or invalid.
	pollFrequencyTemp,err := strconv.Atoi(pollFrequency)
	if err != nil || pollFrequencyTemp < 5 {
		pollFrequencyParsed = time.Duration(30)
	} else {
		pollFrequencyParsed = time.Duration(pollFrequencyTemp)
	}
}

func main() {
	// Configure log level.
	configureLogLevel()
	// Load Certificates If No System Pool Found.
	initCaCerts()
	// Start scraping GitHub Status.
	go generateGitHubStatusMetrics()
	// Configure and Start Echo Server.
	startServer()
}

func configureLogLevel() {
	logLevelUpper := strings.ToUpper(logLevel)
	switch logLevelUpper {
	case "DEBUG":
		slog.SetLogLoggerLevel(slog.LevelDebug)
	case "INFO":
		slog.SetLogLoggerLevel(slog.LevelInfo)
	case "WARN":
		slog.SetLogLoggerLevel(slog.LevelWarn)
	case "ERROR":
		slog.SetLogLoggerLevel(slog.LevelError)
	default:
		slog.SetLogLoggerLevel(slog.LevelInfo)
	}
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

func generateGitHubStatusMetrics() {
	for {
		startTime := time.Now().Unix()
		var githubStatus GithubStatus
		resp, err := http.Get(githubStatusUrl)
		if err != nil {
			ScrapeStatusMetric.Set(0)
			slog.Warn(fmt.Sprintf("Error requesting githubstatus api: %s\n", err.Error()))
			time.Sleep(pollFrequencyParsed * time.Second)
			continue
		}
		defer func(Body io.ReadCloser) {
			err := Body.Close()
			if err != nil {
				slog.Warn("Failed to close response body: %s\n", err.Error())
			}
		}(resp.Body)
		body, err := io.ReadAll(resp.Body)
		if err := json.Unmarshal(body, &githubStatus); err != nil {
			ScrapeStatusMetric.Set(0)
			slog.Warn(fmt.Sprintf("Error unmarshalling json from githubstatus api: %s\n", err.Error()))
			time.Sleep(pollFrequencyParsed * time.Second)
			continue
		}
		if len(githubStatus.Components) >= 10 {
			ScrapeStatusMetric.Set(1)
		}
		for _, component := range githubStatus.Components {
			if component.Status == "operational" {
				GitHubStatusMetric.WithLabelValues(component.Name).Set(1.0)
			} else {
				GitHubStatusMetric.WithLabelValues(component.Name).Set(0.0)
			}
		}
		endTime := time.Now().Unix()
		slog.Debug(fmt.Sprintf("PROFILING: end=%d - start=%d == %d seconds", startTime, endTime, endTime-startTime))
		// Could subtract time taken from the sleep value, but in practice it runs in <1s anyway.
		time.Sleep(pollFrequencyParsed * time.Second)
	}
}

func startServer() {
	e := echo.New()
// 	e.Use(middleware.Logger())
	e.Static("/", "static/html")
	e.GET("/favicon.ico", favicon)
	e.GET("/info", info)
	e.GET("/metrics", echo.WrapHandler(promhttp.Handler()))
	e.Logger.Fatal(e.Start(":8080"))
}

func favicon(c echo.Context) error {
	return c.HTML(http.StatusOK, "<link rel=\"icon\" href=\"data:;base64,=\">")
}

func info(c echo.Context) error {
	return c.JSON(http.StatusOK, os.Environ())
}
