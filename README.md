# k8s 1.8.4 docker 镜像同步

> 用于kubernetes 1.8.4 版本安装，包括kubernetes 安装包、docker 所需镜像，拉取镜像脚本，以及yaml配置文件。



文件列表

	#kubernetes 初始化所需镜像
	gcr.io/google_containers/kube-apiserver-amd64  v1.8.4
	gcr.io/google_containers/kube-controller-manager-amd64  v1.8.4
	gcr.io/google_containers/kube-proxy-amd64  v1.8.4
	gcr.io/google_containers/kube-scheduler-amd64  v1.8.4
	quay.io/coreos/flannel    v0.9.1-amd64
	gcr.io/google_containers/k8s-dns-sidecar-amd64  1.14.5
	gcr.io/google_containers/k8s-dns-kube-dns-amd64  1.14.5
	gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64  1.14.5
	gcr.io/google_containers/etcd-amd64  3.0.17
	gcr.io/google_containers/pause-amd64  3.0

	#dashboard
	gcr.io/google_containers/kubernetes-dashboard-amd64
	
	#heapster
	gcr.io/google_containers/heapster-amd64:v1.4.2
	gcr.io/google_containers/heapster-grafana-amd64:v4.4.3
	gcr.io/google_containers/heapster-influxdb-amd64:v1.3.3