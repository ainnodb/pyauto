#!/usr/bin/bash

# 生成 EncryptionConfig 所需的加密 key
#export ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

##########################################################
#  cluster IP and hostname list
##########################################################
#export NODE_IPS=(10.10.10.70 10.10.10.71 10.10.10.72 10.10.10.73)
export NODE_IPS=(10.10.10.70 10.10.10.71 10.10.10.72 10.10.10.73)
export MASTER_IPS=(10.10.10.70 10.10.10.71 10.10.10.72)
export MASTERIP=10.10.10.100
export K8STYPE=MM

export NODE_NAMES_DOMAIN=("win70.inno.com" "win71.inno.com" "win72.inno.com" "win73.inno.com")
export NODE_NAMES=("win70" "win71" "win72" "win73")
export MS_NODE_NAMES=("win70" "win71" "win72")
#export MASTERNODE="win70.inno.com"
#export BACKUPNODE="win71.inno.com"

##########################################################
#  KUBE_APISERVER
##########################################################
# export MASTER_ADDRESS="10.10.10.100"
# export APISERVER="10.10.10.100"
# export KUBE_APISERVER="https://${APISERVER}:6443"


##########################################################
#  cluster config directory
##########################################################
if ! [ -d /etc/kubernetes ]; then
	mkdir /etc/kubernetes/{cfg,ssl,logs,flanneld,manifests,json,exe}  -p
	mkdir /etc/kubernetes/logs/{kubelet,kube-proxy,kube-scheduler,kube-apiserver,kube-controller-manager,flanneld} -p
fi

if ! [ -d /var/kubernetes/logs ]; then
	mkdir /var/kubernetes/logs -p
fi

if ! [ -d /etc/etcd ]; then
	mkdir /etc/etcd/{data,cfg,ssl} -p
fi


export SSL_DIR=/etc/kubernetes/ssl
export LOG_DIR=/etc/kubernetes/logs
export CFG_DIR=/etc/kubernetes/cfg
export JSON_DIR=/etc/kubernetes/json
export ETCD_SSL_DIR=/etc/etcd/ssl
export ETCD_CFG_DIR=/etc/etcd/cfg
export ETCD_DATA_DIR=/etc/etcd/data

# etcd WAL 目录，建议是 SSD 磁盘分区，或者和 ETCD_DATA_DIR 不同的磁盘分区
export ETCD_WAL_DIR=/etc/etcd/data/wal

# docker 数据目录
export DOCKER_DIR=/var/data/docker
export LOG_FILE_DIR=/var/kubernetes/logs
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/usr/local/etcd/bin


##########################################################
# etcd configure variables
##########################################################
export ETCD_NODE_NAMES_DOMAIN=("win72.inno.com" "win71.inno.com" "win70.inno.com")
export ETCD_NODE_NAMES=("win72" "win71" "win70")

##           ETCD_CLUSTER  using for etcd service
ETCD_CLUSTER=""
i=0

for  i in `seq 0 ${#ETCD_NODE_NAMES_DOMAIN[@]}` ;
	do
		if test -z ${ETCD_NODE_NAMES_DOMAIN[$i]} ; then
			break
		else
			ETCD_CLUSTER="$ETCD_CLUSTER${NODE_NAMES[$i]}"=https://"${NODE_NAMES_DOMAIN[$i]}:2380,"
		fi
	done
ETCD_CLUSTER=${ETCD_CLUSTER:0:${#ETCD_CLUSTER}-1}
export ETCD_CLUSTER=${ETCD_CLUSTER}
#ETCD_CLUSTER is using for config etcd.yml

export ETCD_ENDPOINTS=${ETCD_CLUSTER}

# echo "export ETCD_SERVERS=https://win70.inno.com:2379,https://win71.inno.com:2379,https://win72.inno.com:2379">> ~/.bash_profile
#echo "export ETCD_ENDPOINTS=https://win72.inno.com:2379">> ~/.bash_profile

##########################################################
# ETCD_SERVERS  using for flanneld service  & kube-apiserver {etcd-endpoints}
##########################################################

# etcd 集群间通信的 IP 和端口
ETCD_SERVERS=""
i=0
for  i in `seq 0 ${#ETCD_NODE_NAMES_DOMAIN[@]}` ;
	do 
		if test -z ${ETCD_NODE_NAMES_DOMAIN[$i]} ; then
			break
		else
			ETCD_SERVERS="https://"${ETCD_NODE_NAMES_DOMAIN[$i]}":2379,"$ETCD_SERVERS
		fi
	done
ETCD_SERVERS=${ETCD_SERVERS:0:${#ETCD_SERVERS}-1}
export ETCD_SERVERS=${ETCD_SERVERS}

# flanneld 网络配置前缀
export FLANNEL_ETCD_PREFIX="/atomic.io/network"

##########################################################
# others
##########################################################

# 节点间互联网络接口名称
export IFACE=ens224

## 以下参数一般不需要修改
# TLS Bootstrapping 使用的 Token，可以使用命令 head -c 16 /dev/urandom | od -An -t x | tr -d ' ' 生成
#BOOTSTRAP_TOKEN="41f7e4ba8b7be874fcff18bf5cf41a7c"

# 最好使用 当前未用的网段 来定义服务网段和 Pod 网段
# 服务网段，部署前路由不可达，部署后集群内路由可达(kube-proxy 保证)
#echo "SERVICE_CIDR=\"10.96.0.0/16\"">> ~/.bash_profile

# Pod 网段，建议 /16 段地址，部署前路由不可达，部署后集群内路由可达(flanneld 保证)
CLUSTER_CIDR="10.244.0.0/16"

# 服务端口范围 (NodePort Range)
export NODE_PORT_RANGE="30000-50000"

# kubernetes 服务 IP (一般是 SERVICE_CIDR 中第一个IP)
#echo "export CLUSTER_KUBERNETES_SVC_IP=\"10.244.0.1\"">> ~/.bash_profile

# 集群 DNS 服务 IP (从 SERVICE_CIDR 中预分配)
#echo "export CLUSTER_DNS_SVC_IP=\"10.244.0.2\"">> ~/.bash_profile

# 集群 DNS 域名（末尾不带点号）
export CLUSTER_DNS_DOMAIN=\"cluster.local\"

# 将二进制目录 /opt/k8s/bin 加到 PATH 中
#export PATH=/usr/sbin:$PATH
##########################################################
# SSH/SCP
##########################################################
export DIRECT_RSH="ssh -o BatchMode=yes"
export DIRECT_RCP="scp -o BatchMode=yes"
export RCPO="scp"
export RSHO="ssh"
export RCP_RSB="scp -o BatchMode=yes"
export RCPO_RSB="scp"