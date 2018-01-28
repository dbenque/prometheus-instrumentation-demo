# Instrumentation for prometheus metric export

## Import package

```
import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)
```

## Declaration of histogram

```
var commandeDuration = prometheus.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "demo_commande_seconds",
		Help:    "Temps de prise de commande.",
		Buckets: prometheus.LinearBuckets(2, 2, 10),
	}, []string{"plat", "dessert"})

prometheus.MustRegister(commandeDuration)
```

## Expose http endpoint

```
http.Handle("/metrics", promhttp.Handler())
```

## Update metrics
In your function handler, within your business code.

```
commandeDuration.WithLabelValues(commande.Plat, commande.Dessert).Observe(commandeDuration)
```

