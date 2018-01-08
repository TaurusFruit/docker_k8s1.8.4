#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

KUBE_VERSION=v1.8.4
KUBE_PAUSE_VERSION=3.0
ETCD_VERSION=3.0.17
DNS_VERSION=1.14.5
FLANNEL=v0.9.1-amd64

GCR_URL=gcr.io/google_containers
DOCKERIO_URL=zhang0128lei

images=(kube-proxy-amd64:${KUBE_VERSION}
kube-scheduler-amd64:${KUBE_VERSION}
kube-controller-manager-amd64:${KUBE_VERSION}
kube-apiserver-amd64:${KUBE_VERSION}
pause-amd64:${KUBE_PAUSE_VERSION}
etcd-amd64:${ETCD_VERSION}
k8s-dns-sidecar-amd64:${DNS_VERSION}
k8s-dns-kube-dns-amd64:${DNS_VERSION}
k8s-dns-dnsmasq-nanny-amd64:${DNS_VERSION})


for imageName in ${images[@]} ; do
  docker pull $DOCKERIO_URL/$imageName
  docker tag $DOCKERIO_URL/$imageName $GCR_URL/$imageName
  docker rmi $DOCKERIO_URL/$imageName
done

docker pull $DOCKERIO_URL/flannel:v0.9.1-amd64
docker tag $DOCKERIO_URL/flannel:v0.9.1-amd64 quay.io/coreos/flannel:v0.9.1-amd64
docker rmi $DOCKERIO_URL/flannel:v0.9.1-amd64


