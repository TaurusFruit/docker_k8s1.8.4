#!/bin/sh
#
# Description: centos7 kubernetes 1.8.4 一键部署脚本
# CreateDate: 2018/1/9
# LastModify: 2017/1/9
# Author： lei
#
# 软件版本
# centos 7
# kubernetes 1.8.4
# docker 17.0.2.ce
#
# History:
# 
#
#



#set -e

master_ip=$1

function show_help(){
    prompt="Usage: ./k8s_install.sh [options]\n-n\t\t\tInstall k8s node\n-m\t\t\tInstall k8s master\n-i 10.0.0.1\t\tDefine master IP\n-h \t\t\tshow help\n"
    echo -e $prompt
}

while getopts "i:nm" arg
do
    case $arg in
        n)
            node=True
            ;;
        m)
            master=True
            ;;
        i)
            master_ip=$OPTARG
            echo "Master IP: $master_ip"
            ;;
        h)
            show_help
            ;;
        *)
            show_help
            ;;  
    esac
done


#环境初始化
function env_init(){
	systemctl stop firewalld && systemctl disable firewalld || echo "Failed to stop firewalld.service: Unit firewalld.service not loaded."
	iptables -P FORWARD ACCEPT
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	setenforce 0

	cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
vm.swappiness=0
EOF
	sysctl -p /etc/sysctl.d/k8s.conf > /dev/null 2>&1 

	swapoff -a

}

# 安装docker 17.0.2
function docker_install(){
	echo "Docker is installing ..."
	yum install -y yum-utils device-mapper-persistent-data lvm2 wget
	yum-config-manager \
    	--add-repo \
    	https://download.docker.com/linux/centos/docker-ce.repo
	yum makecache fast

	yum install -y --setopt=obsoletes=0 \
    	docker-ce-17.03.2.ce-1.el7.centos \
    	docker-ce-selinux-17.03.2.ce-1.el7.centos
	systemctl start docker && systemctl enable docker

	cat << EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
	systemctl daemon-reload && systemctl restart docker && echo "Docker install OK"
}

# 安装k8s 1.8.4
function k8s_install(){
	#download k8s rpm
	cd /usr/local/src
	mkdir -p k8s && cd k8s
	wget https://github.com/TaurusFruit/docker_k8s1.8.4/raw/master/rpms/aeaad1e283c54876b759a089f152228d7cd4c049f271125c23623995b8e76f96-kubeadm-1.8.4-0.x86_64.rpm
	wget https://github.com/TaurusFruit/docker_k8s1.8.4/raw/master/rpms/a9db28728641ddbf7f025b8b496804d82a396d0ccb178fffd124623fb2f999ea-kubectl-1.8.4-0.x86_64.rpm
	wget https://github.com/TaurusFruit/docker_k8s1.8.4/raw/master/rpms/1acca81eb5cf99453f30466876ff03146112b7f12c625cb48f12508684e02665-kubelet-1.8.4-0.x86_64.rpm
	wget https://github.com/TaurusFruit/docker_k8s1.8.4/raw/master/rpms/79f9ba89dbe7000e7dfeda9b119f711bb626fe2c2d56abeb35141142cda00342-kubernetes-cni-0.5.1-1.x86_64.rpm
	yum -y localinstall *.rpm
	yum -y install socat
	systemctl daemon-reload && systemctl restart kubelet && systemctl enable kubelet && systemctl status kubelet
	curl https://raw.githubusercontent.com/TaurusFruit/docker_k8s1.8.4/master/script/pull_k8s_img.sh | sh
}

# 初始化kubele
function kubelet_init(){
	kubeadm init --apiserver-advertise-address=${master_ip} --kubernetes-version=v1.8.4 --pod-network-cidr=10.244.0.0/16 > /root/kubelet.log 2>&1
	mkdir -p $HOME/.kube && \
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && \
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    kubectl get pod --all-namespaces -o wide
    kubectl get cs
    kubectl apply -f https://raw.githubusercontent.com/TaurusFruit/docker_k8s1.8.4/master/flannel/kube-flannel.yml
    sleep 2
}

function dashboard_install(){
	curl https://raw.githubusercontent.com/TaurusFruit/docker_k8s1.8.4/master/script/pull_k8s_dashboard_img.sh | sh
	kubectl apply -f https://raw.githubusercontent.com/TaurusFruit/docker_k8s1.8.4/master/kubernetes-dashboard-amd64/kubernetes-dashboard.yaml
	kubectl apply -f https://raw.githubusercontent.com/TaurusFruit/docker_k8s1.8.4/master/kubernetes-dashboard-amd64/kubernetes-dashboard-admin.rbac.yaml
	kubectl get pod --all-namespaces -o wide
	sleep 2
	kubectl describe -n kube-system secret/$(kubectl -n kube-system get secret | grep kubernetes-dashboard-admin|awk '{print $1}')

}

function heapster_install(){
	curl https://raw.githubusercontent.com/TaurusFruit/docker_k8s1.8.4/master/script/pull_k8s_heapster_img.sh | sh
	kubectl apply -f https://raw.githubusercontent.com/TaurusFruit/docker_k8s1.8.4/master/heapster-amd64/heapster-rbac.yaml
	kubectl apply -f https://raw.githubusercontent.com/TaurusFruit/docker_k8s1.8.4/master/heapster-grafana-amd64/grafana.yaml
	kubectl apply -f https://raw.githubusercontent.com/TaurusFruit/docker_k8s1.8.4/master/heapster-influxdb-amd64/influxdb.yaml
	kubectl apply -f https://raw.githubusercontent.com/TaurusFruit/docker_k8s1.8.4/master/heapster-amd64/heapster.yaml
}


function run(){
	if [[ -z $master_ip ]] ;then
		show_help
		exit 1
	fi
	
	if [[ $master ]] ;then
		env_init
		docker_install
		k8s_install
		kubelet_init
		dashboard_install
		heapster_install
	fi
	if [[ $node ]] ;then
		env_init
		docker_install
		k8s_install
		echo "go to master and run:"
		echo "token=\`kubeadm token list | grep authentication,signing | awk '{print \$1}'\`"
		echo "sha256=\`openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'\`"
		echo "master_ip=$master_ip"
		echo "echo \"kubeadm join --token \$token \$master_ip:6443 --discovery-token-ca-cert-hash sha256:\$sha256\""
	fi
}


run