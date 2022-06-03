#!/usr/bin/bash
cat >ca-config.json <<EOF
{
  "signing": {
      "default": {
      "expiry": "87600h"
      },
     "profiles": {
         "server": {
             "expiry": "87600h",
             "usages": [
                 "signing",
                 "key encipherment",
                 "server auth",
                 "client auth"
                 ]
	     },
         "client": {
	     "expiry": "87600h",
             "usages": [
                 "signing",
                 "key encipherment",
                 "server auth",
                 "client auth"
            ]
        },
         "peer": {
	    "expiry": "87600h",
            "usages": [
                "signing",
                "key encipherment",
                "server auth",
                "client auth"
            ]
      }
    }
  }
}
EOF

cat >ca-csr.json <<EOF
{
  "CN": "system:masters:etcd",  
  "hosts": [
  ],
  "key": {
      "algo": "ecdsa",
      "size": 256
  },
  "names": [
      {
          "C": "CN",  
          "ST": "Henan",
          "L": "nanyang",
          "O": "system:masters",
          "OU": "system"
    }
  ],
  "ca": {
	  "expiry": "87600h"
  }
}
EOF

echo "start generate  ca.pem and ca-key.pem certification"
cfssl gencert -initca ca-csr.json | cfssljson -bare ca - 
sleep 2
echo "Generate  ca.pem and ca-key.pem certification done"

echo "start generate peer certification"
sed -e "s:clusteradmin:peer:g" template-csr.json > etcdpeer-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer etcdpeer-csr.json |cfssljson -bare peer
sleep 2
echo "Generate peer certification done"


echo "start generate server certification"
sed -e "s:clusteradmin:server:g" template-csr.json > server-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server server-csr.json |cfssljson -bare server
sleep 2
echo "Generate server certification done"
##########################################################
# cleint cert
##########################################################
echo "start generate apiserver-etcd-client certification"
sed -e "s:temp:apiserver-etcd-client:g" temp-client-csr.json > apiserver-etcd-client-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client apiserver-etcd-client-csr.json |cfssljson -bare apiserver-etcd-client
sleep 2
echo "Generate piserver-etcd-client certification done"

echo "start generate apiserver-kubelet-client certification"
sed -e "s:temp:apiserver-kubelet-client:g" temp-client-csr.json > apiserver-kubelet-client-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client apiserver-kubelet-client-csr.json |cfssljson -bare apiserver-kubelet-client
sleep 2
echo "Generate apiserver-kubelet-client certification done"

echo "start generate front-proxy-client certification"
sed -e "s:temp:front-proxy-client:g" temp-client-csr.json > front-proxy-client-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client front-proxy-client-csr.json |cfssljson -bare front-proxy-client
sleep 2
echo "Generate front-proxy-client certification done"

echo "start generate client certification"
sed -e "s:temp:client:g" temp-client-csr.json > client-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client-csr.json |cfssljson -bare client
sleep 2
echo "Generate client certification done"


##########################################################
#  kube-apiserver
##########################################################
echo "start generate kube-apiserver certification"
sed -e "s:clusteradmin:kube-apiserver:g" template-csr.json > kube-apiserver-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server kube-apiserver-csr.json |cfssljson -bare kube-apiserver
sleep 2
echo "Generate kube-apiserver certification done"
##########################################################
#  kube-controller-manager
##########################################################
echo "start generate kube-controller-manager certification"
sed -e "s:clusteradmin:system\:kube-controller-manager:g" template-csr.json > kube-controller-manager-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server kube-controller-manager-csr.json |cfssljson -bare kube-controller-manager
sleep 2
echo "Generate kube-controller-manager certification done"

##########################################################
#  kube-scheduler
##########################################################
echo "start generate kube-scheduler certification"
sed -e "s:clusteradmin:system\:kube-scheduler:g" template-csr.json > kube-scheduler-manager-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server kube-scheduler-manager-csr.json |cfssljson -bare kube-scheduler
sleep 2
echo "Generate kube-scheduler certification done"

##########################################################
#  kubectl
##########################################################
echo "start generate kubectl certification"
sed -e "s:clusteradmin:clusteradmin:g" template-csr.json > kubectl-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server kubectl-csr.json |cfssljson -bare kubectl
sleep 2
echo "Generate kubectl certification done"

##########################################################
#  kube-proxy
##########################################################
echo "start generate kube-proxy certification"
sed -e "s:temp:system\:kubeproxy:g" temp-client-csr.json > kube-proxy-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client kube-proxy-csr.json | cfssljson -bare kube-proxy
sleep 2
echo "Generate kube-proxy certification done"

##########################################################
#  admin
##########################################################
echo "start generate admin certification"
sed -e "s:temp:admin:g" temp-client-csr.json > admin-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server admin-csr.json | cfssljson -bare admin
sleep 2
echo "Generate admin certification done"
##########################################################
#  kubelet
##########################################################
echo "start generate kubelet certification"
sed -e "s:clusteradmin:system\:kubelet:g" template-csr.json > kubelet-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server kubelet-csr.json |cfssljson -bare kubelet
sleep 2
echo "Generate kubelet certification done"
##########################################################
#  flanneld
##########################################################
echo "start generate flanneld certification"
sed -e "s:clusteradmin:system\:flanneld:g" template-csr.json > flanneld-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client flanneld-csr.json | cfssljson -bare flanneld
sleep 2
echo "Generate flanneld certification done"