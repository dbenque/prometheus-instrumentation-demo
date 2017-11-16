# prometheus-instrumentation-demo
small server to demo the code instrumentation and prometheus usage

## Local

Run the demo application in local:
```
docker run -d --rm --name="resto" --net=host dbenque/prom-demo-resto:v2
```

Browse http://localhost:8080

Now launch local instance of prometheus (and grafana)
```
prometheus/launch.local.sh
```

Browse Prometheus http://localhost:9090

Browse Grafana http://localhost:3000   (user/pass = admin/admin)

## Alibaba cluster

Follow the instruction in the alibaba folder.

## GKE cluster