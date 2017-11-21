# Demo

## Slide 7

Launch application
```
docker run -d --rm --name="resto" --net=host dbenque/prom-demo-resto:v3
```

Browse http://localhost:8080

Now launch local instance of prometheus (and grafana)
```
prometheus/launch.local.sh
```

Show the prometheus configuration http://localhost:9090/config

Browse Grafana http://localhost:3000   (user/pass = admin/admin)

## Slide 10

Code instrumenté en go

Définir et déclarer les metriques
```
	commandeDuration = prometheus.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "demo_commande_seconds",
		Help:    "Temps de prise de commande.",
		Buckets: prometheus.LinearBuckets(2, 2, 10),
	}, []string{"plat", "dessert"})

    prometheus.MustRegister(commandeDuration)
```

Accumuler metriques dans le code
```
		s := time.Now().Sub(time.Unix(int64(v), 0)).Seconds()
		commandeDuration.WithLabelValues(c.Plat, c.Dessert).Observe(s)
```

Servir les metriques en http:
```
http.Handle("/metrics", promhttp.Handler())
```