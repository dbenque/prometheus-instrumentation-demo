# prometheus-instrumentation-demo

Sample application (resto) and setup (local and gke) to demonstrate Prometheus.
Assocaited presentation done during Sophia-CNCF-Meetup: https://docs.google.com/presentation/d/1uqiGwtBsLp1NbtW-ByGCR9rh8ZYp3NoatcXBiX0uxnA/edit#slide=id.g328b5dc653_0_154

Link to the meetup:
https://www.meetup.com/CNCF-Cloud-Native-Computing-Sophia-Antipolis/events/246424155/

## Folders

resto: contains the demo application
prometheus: contains scripts to run local prometheus+grafana and federation
vendor: go vendoring for resto application
gke: script and procedure to launch a kube cluster and install prometheus+grafana using coreos operator on GKE
alibabacloud: procedure to launch a kube cluster and install prometheus+grafana using coreos operator on alibabacloud (not working after december 2017... fix needed)

## Local

Run the demo application in local:
```
docker run -d --rm --name="resto" --net=host dbenque/prom-demo-resto:v3
```

Browse http://localhost:8080

Now launch local instance of prometheus (and grafana)
```
prometheus/launch.local.sh
```

Browse Prometheus http://localhost:9090

Browse Grafana http://localhost:3000   (user/pass = admin/admin)

### Cleanup

To stop the application:
```
docker stop resto
```
To stop the monitoring:
```
prometheus/stop.local.sh
```

## GKE cluster

Follow the instruction in the **GKE** folder.

## Alibaba cluster
(not tested in 2018)
Follow the instruction in the **alibaba** folder.

