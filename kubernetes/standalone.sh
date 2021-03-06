#!/usr/bin/bash

# 生成 EncryptionConfig 所需的加密 key
#export ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)


##########################################################
#  cluster IP and hostname list
##########################################################
MASTERIP=$(nslookup $(hostname)|grep -i Address|awk '{print $2}'|grep -v '#')
export APPNAME="kubernets"
#export KUBERNETESVERSION=$(kubectl version --short|grep -i server|awk '{print $3}')
export NODE_IPS=${MASTERIP}
export NODE_IP=${MASTERIP}
export MASTER_IPS=${MASTERIP}
export MASTERIP=${MASTERIP}
export BACKUPIP=${MASTERIP}
export K8STYPE=ST

export NODE_NAMES_DOMAIN=$(hostname)
export NODE_NAMES=$(hostname -s)
export MASTERNODE=$(hostname)
export BACKUPNODE=$(hostname)


##########################################################
#  KUBE_APISERVER
##########################################################
export MASTER_ADDRESS=${MASTERIP}
export APISERVER=${MASTERIP}
export KUBE_APISERVER="https://${APISERVER}:6443"

##########################################################
#  cluster config directory
##########################################################
if ! [ -d /etc/kubernetes ]; then
	mkdir /etc/kubernetes/{cfg,ssl,logs,flanneld,manifests,json}  -p
	mkdir /etc/kubernetes/logs/{kubelet,kube-proxy,kube-scheduler,kube-apiserver,kube-controller-manager,flanneld} -p
fi

if ! [ -d /var/kubernetes/logs ]; then
	mkdir /var/kubernetes/logs -p
fi

if ! [ -d /etc/etcd ]; then
	mkdir /etc/etcd/{data,cfg,ssl} -p
fi

export EXE_DIR=/etc/kubernetes/exe
export SSL_DIR=/etc/kubernetes/ssl
export LOG_DIR=/etc/kubernetes/logs
export CFG_DIR=/etc/kubernetes/cfg
export JSON_DIR=/etc/kubernetes/json
export ETCD_SSL_DIR=/etc/etcd/ssl
export ETCD_CFG_DIR=/etc/etcd/cfg
export LOG_FILE_DIR=/var/kubernetes/logs

export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/usr/local/etcd/bin


##########################################################
# etcd 集群服务地址列表
##########################################################
export ETCD_NODE_NAMES_DOMAIN=$(hostname)
export ETCD_NODE_NAMES=$(hostname -s)

ETCD_CLUSTER=''
i=0
for  i in `seq 0 ${#ETCD_NODE_NAMES_DOMAIN[@]}` ;
	do
		if test -z ${ETCD_NODE_NAMES_DOMAIN[$i]} ; then
			break
		else
			ETCD_CLUSTER=${ETCD_NODE_NAMES[$i]}"=https://"${ETCD_NODE_NAMES_DOMAIN[$i]}:2380","$ETCD_CLUSTER
		fi
	done
export ETCD_CLUSTER=${ETCD_CLUSTER:0:${#ETCD_CLUSTER}-1}  ##trim last ","
export ETCD_ENDPOINTS=${ETCD_CLUSTER}

#######ETCD_SERVERS
# etcd 集群间通信的 IP 和端口
ETCD_SERVERS=""
i=0
for  i in `seq 0 ${#NODE_IPS[@]}` ;
	do
		if test -z ${NODE_IPS[$i]} ; then
			break
		else
			ETCD_SERVERS="https://"${NODE_IPS[$i]}":2379,"$ETCD_SERVERS
		fi
	done

ETCD_SERVERS=${ETCD_SERVERS:0:${#ETCD_SERVERS}-1}
export ETCD_SERVERS=$ETCD_SERVERS

# kube-apiserver 的反向代理(kube-nginx)地址端口
#echo "export KUBE_APISERVER=\"https://10.10.10.100:8443\"">> ~/.bash_profile

# 节点间互联网络接口名称
export IFACE=ens224

# etcd 数据目录
export ETCD_DATA_DIR=/etc/etcd/data

# etcd WAL 目录，建议是 SSD 磁盘分区，或者和 ETCD_DATA_DIR 不同的磁盘分区
export ETCD_WAL_DIR=/etc/etcd/data/wal

# k8s 各组件数据目录
#echo "export K8S_DIR=/data/k8s/k8s

# docker 数据目录
export DOCKER_DIR=/workdata/data/docker

## 以下参数一般不需要修改

# TLS Bootstrapping 使用的 Token，可以使用命令 head -c 16 /dev/urandom | od -An -t x | tr -d ' ' 生成
#BOOTSTRAP_TOKEN="41f7e4ba8b7be874fcff18bf5cf41a7c"


# 服务网段，部署前路由不可达，部署后集群内路由可达(kube-proxy 保证)
export SERVICE_CIDR="10.96.0.0/16"

# Pod 网段，建议 /16 段地址，部署前路由不可达，部署后集群内路由可达(flanneld 保证)
export CLUSTER_CIDR="10.244.0.0/16"

# 服务端口范围 (NodePort Range)
export NODE_PORT_RANGE="30000-50000"

# flanneld 网络配置前缀
export FLANNEL_ETCD_PREFIX="/atomic.io/network"

# kubernetes 服务 IP (一般是 SERVICE_CIDR 中第一个IP)
export CLUSTER_KUBERNETES_SVC_IP="10.96.0.1"

# 集群 DNS 服务 IP (从 SERVICE_CIDR 中预分配)
export CLUSTER_DNS_SVC_IP="10.96.0.10"

# 集群 DNS 域名（末尾不带点号）
export CLUSTER_DNS_DOMAIN="cluster.local"