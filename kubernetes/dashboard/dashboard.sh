#!/bin/bash
echo "...............apply dashboard.................."
kubectl apply -f 1_dashboard-rbac.yml
kubectl apply -f 2_dashboard.yaml
echo "...............apply dashboard done .................."
echo "Wait for dashboard "
sleep 5
#APISERVER=10.10.10.100
#SSL_DIR=/etc/kubernetes/ssl
if [ -f standalone.sh ]; then
   source ~/standalone.sh
fi
kadmin=`kubectl get secrets -n kube-system|grep dashboard-admin|awk 'NR=1{print$1}'`
echo $kadmin
token=`kubectl describe -n kube-system secrets ${kadmin}|grep -i token:`
echo $token
DASH_TOKEN=`echo $token|awk 'NR=1{print$2}'`
echo -e "-------Find token is"
echo -e "-------$DASH_TOKEN"
export KUBE_APISERVER="https://${APISERVER}:6443"
kubectl config set-cluster kubernetes --server=${KUBE_APISERVER} --kubeconfig=${APISERVER}-dashboard-admin.conf
kubectl config set-credentials admin --token=${DASH_TOKEN} --kubeconfig=${APISERVER}-dashboard-admin.conf
kubectl config set-context admin --cluster=kubernetes --user=admin --kubeconfig=${APISERVER}-dashboard-admin.conf
kubectl config use-context admin --kubeconfig=${APISERVER}-dashboard-admin.conf