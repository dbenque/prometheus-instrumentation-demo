# Export kubeconfig using nc

On the kubernetes master node ( 47.91.156.77 in this example )

install netcat
```
yum install nc
```

then netcat the configuration
```
cat /etc/kubernetes/kube.conf | nc -l -p 40000
```

On the remote machine

```
IP=47.91.156.77; nc $IP 40000 | sed -e "s/1.1.1.1/$IP/g" > ~/.kube/alibaba.conf
```

The insecure option must be use to skip certifiacte validation

```
alias ka='kubectl --kubeconfig=/home/david/.kube/alibaba.conf --insecure-skip-tls-verify'
```

Try to check
```
ka get pods --all-namespaces
```

# install the application

ka run resto --image=dbenque/prom-demo-resto:v0 --expose --port=8080
ka apply -f resto.ingress.yml
