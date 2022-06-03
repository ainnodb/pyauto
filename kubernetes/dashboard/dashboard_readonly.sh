#!/bin/bash
cat >readonly-ca-config.json<<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
EOF
cat >readonly-csr.json<<EOF
{
  "CN": "readonly",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "bj",
      "L": "bj",
      "O": "readonly-group",
      "OU": "System"
    }
  ]
}
EOF
cfssl gencert -ca=./ca.crt -ca-key=./ca.key -config=./read-ca-config.json -profile=kubernetes readonly-csr.json | cfssljson -bare readonly

APISERVER=10.10.10.100
SSL_DIR=/etc/kubernetes/ssl
kadmin=`kubectl get secrets -n kube-system|grep dashboard-admin|awk 'NR=1{print$1}'`
echo $kadmin
token=`kubectl describe -n kube-system secrets ${kadmin}|grep -i token:`
echo $token
DASH_TOKEN=`echo $token|awk 'NR=1{print$2}'`
echo "find token is"
echo $DASH_TOKEN
export KUBE_APISERVER="https://${APISERVER}:6443"
# 拷贝admin文件信息到readonly
cat admin.conf > readonly.conf
# 设置用户信息
kubectl config set-credentials readonly --client-certificate=readonly.pem --client-key=readonly-key.pem --embed-certs=true --kubeconfig=readonly.conf 
# 设置上下文信息
kubectl config set-context kubernetes --cluster=kubernetes --user=readonly --kubeconfig=readonly.conf
# 设置当前的上下文
kubectl config use-context kubernetes --kubeconfig=readonly.conf