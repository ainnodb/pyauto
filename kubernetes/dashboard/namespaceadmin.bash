#!/bin/bash
#https://kubernetes.io/docs/reference/access-authn-authz/rbac/
APISERVER=10.10.10.100
SSL_DIR=/etc/kubernetes/ssl
target_namespace=$1
kubectl create serviceaccount ${target_namespace}-admin -n ${target_namespace}
#kubectl create rolebinding ${target_namespace}-admin-default --clusterrole=admin --serviceaccount=${target_namespace}:${target_namespace}-admin --namespace ${target_namespace}
kubectl create rolebinding ${target_namespace}-admin-default --clusterrole=cluster-admin --serviceaccount=${target_namespace}:${target_namespace}-admin --namespace ${target_namespace}
  
# cat >${target_namespace}rolebinding.yaml <<EOF  
# apiVersion: rbac.authorization.k8s.io/v1
# kind: ClusterRoleBinding
# metadata:
  # annotations:
    # rbac.authorization.kubernetes.io/autoupdate: "true"
  # name: default-${target_namespace}-admin
  # namespace: ${target_namespace}
# roleRef:
  # apiGroup: rbac.authorization.k8s.io
  # kind: ClusterRole
  # name: cluster-amin
# subjects:
# - kind: ServiceAccount
  # name: ${target_namespace}-admin 
# EOF 
#kadmin=`kubectl get secrets -n ${target_namespace}|grep ${target_namespace}-admin|awk 'NR=1{print$1}'`
kadmin=$(kubectl get secrets -n ${target_namespace}|grep ${target_namespace}-admin|awk 'NR=1{print$1}')
echo ${kadmin}

#token=`kubectl describe -n ${target_namespace} secrets ${kadmin}|grep -i token:`
token=$(kubectl describe -n ${target_namespace} secrets ${target_namespace}-admin|grep -i token:)
echo ${token}
#DASH_TOKEN=`echo $token|awk 'NR=1{print$2}'`
DASH_TOKEN=$(echo $token|awk 'NR=1{print$2}')
echo "find token is"
echo $DASH_TOKEN
KUBE_APISERVER="https://${APISERVER}:6443"
kubectl config set-cluster kubernetes --server=${KUBE_APISERVER} --kubeconfig=${target_namespace}-admin.conf
kubectl config set-credentials ${target_namespace}-admin --token=${DASH_TOKEN} --kubeconfig=${target_namespace}-admin.conf
kubectl config set-context ${target_namespace}-admin --cluster=kubernetes --user=${target_namespace}-admin --kubeconfig=${target_namespace}-admin.conf
kubectl config use-context ${target_namespace}-admin --kubeconfig=${target_namespace}-admin.conf

