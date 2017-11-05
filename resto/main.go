package main

import (
	"flag"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"path/filepath"
	"strconv"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	addr = flag.String("listen-address", ":8080", "The address to listen on for HTTP requests.")
)

var (
	commandeDuration = prometheus.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "demo_commande_seconds",
		Help:    "Temps de prise de commande.",
		Buckets: prometheus.LinearBuckets(2, 2, 10),
	}, []string{"plat", "dessert"})
)

func init() {
	// Register the summary and the histogram with Prometheus's default registry.
	prometheus.MustRegister(commandeDuration)
	initializeTemplates()
	defineRoutes()
}

var templates = make(map[string]*template.Template)

// Base template is 'theme.html'  Can add any variety of content fillers in /layouts directory
func initializeTemplates() {
	layouts, err := filepath.Glob("templates/*.html")
	if err != nil {
		log.Fatal(err)
	}

	for _, layout := range layouts {
		templates[filepath.Base(layout)] = template.Must(template.ParseFiles(layout, "templates/layouts/theme.html"))
	}
}

type Commande struct {
	Plat    string
	Dessert string
}

func defineRoutes() {
	//http.HandleFunc("/showcase", showcaseHandler)
	http.HandleFunc("/", menuHandler)
	http.HandleFunc("/commande", commandeHandler)
	http.Handle("/bootstrap/", http.StripPrefix("/bootstrap/", http.FileServer(http.Dir("./bootstrap/"))))
	http.Handle("/images/", http.StripPrefix("/images/", http.FileServer(http.Dir("./images/"))))
}

// func showcaseHandler(w http.ResponseWriter, r *http.Request) {
// 	// showcase.html doesn't expect any data, so pass empty string ""
// 	templates["showcase.html"].ExecuteTemplate(w, "outerTheme", "")
// }

func menuHandler(w http.ResponseWriter, r *http.Request) {
	// showcase.html doesn't expect any data, so pass empty string ""
	now := strconv.FormatInt(time.Now().Unix(), 10)
	cookieNow := &http.Cookie{Name: "timereq", Value: now, HttpOnly: false}
	http.SetCookie(w, cookieNow)
	templates["menu.html"].ExecuteTemplate(w, "outerTheme", "")
}

func commandeHandler(w http.ResponseWriter, r *http.Request) {
	cookieNow, err := r.Cookie("timereq")
	c := Commande{Plat: r.FormValue("plat"), Dessert: r.FormValue("dessert")}
	templates["commande.html"].ExecuteTemplate(w, "outerTheme", &c)
	if err == nil && cookieNow != nil {
		v, _ := strconv.Atoi(cookieNow.Value)
		s := time.Now().Sub(time.Unix(int64(v), 0)).Seconds()
		commandeDuration.WithLabelValues(c.Plat, c.Dessert).Observe(s)
	} else {
		commandeDuration.WithLabelValues(c.Plat, c.Dessert).Observe(0)
		fmt.Printf("Error: %v\n", err)
	}
}

var BUILDTIME string
var VERSION string
var COMMIT string
var BRANCH string

func mainHeader() {
	fmt.Println("Program started at: " + time.Now().String())
	fmt.Println("BUILDTIME=" + BUILDTIME)
	fmt.Println("VERSION=" + VERSION)
	fmt.Println("COMMIT=" + COMMIT)
	fmt.Println("BRANCH=" + BRANCH)
	fmt.Println("-------")
}

func main() {
	mainHeader()
	flag.Parse()

	// Expose the registered metrics via HTTP.
	http.Handle("/metrics", promhttp.Handler())
	log.Fatal(http.ListenAndServe(*addr, nil))
}
