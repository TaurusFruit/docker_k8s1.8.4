#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

KUBE_DASHBOARD_VERSION=v1.8.0

GCR_URL=gcr.io/google_containers
DOCKERIO_URL=zhang0128lei

images=(kubernetes-dashboard-amd64:${KUBE_DASHBOARD_VERSION})

for imageName in ${images[@]} ; do
  docker pull $DOCKERIO_URL/$imageName
  docker tag $DOCKERIO_URL/$imageName $GCR_URL/$imageName
  docker rmi $DOCKERIO_URL/$imageName
done