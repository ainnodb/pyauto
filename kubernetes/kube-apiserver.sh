#!/bin/bash
#=============================================================================
# HEADER
#=============================================================================
#% SYNOPSIS
#%    ${prog}
#%
#% DESCRIPTION
#%    Script to deploy kube-apiservice service
#%
#% ARGUMENTS
#%    NONE
#%
#% EXAMPLES
#%    ${prog}
#%
#=============================================================================
#  HISTORY
#     20220104  innod motingxia@163.com
#=============================================================================
#  NOTES
#=============================================================================
# END_OF_HEADER
#=============================================================================

#=============================================================================
#  IMPORT COMMON FUNCTIONS AND VARIABLES
#=============================================================================
RUNDIR="$(cd "$(dirname "${0}")" && pwd)"
if [ -z "${FUNCTIONS_IMPORTED}" ]; then
  . ${RUNDIR}/functions.ksh
fi

#=============================================================================
#  FUNCTIONS
#=============================================================================
#=============================================================================
#  FUNCTIONS
#=============================================================================
do_exit() {
  RC=$1
  echo "$RC" >/tmp/RC.$$
  exit $RC
}

if [ $# -gt 0 ]; then
  usage
  exit 8
fi
RC=0
scriptname=$(basename $0)
starttime=$(date +%s)
if ! [ -f ${LOG_FILE_DIR}/${scriptname}.log  ];then
  touch ${LOG_FILE_DIR}/${scriptname}.log
  LogFile=${LOG_FILE_DIR}/${scriptname}.log
else
  rm -rf ${LOG_FILE_DIR}/${scriptname}.log
  touch ${LOG_FILE_DIR}/${scriptname}.log
  LogFile=${LOG_FILE_DIR}/${scriptname}.log
fi
export LogFile=${LOG_FILE_DIR}/${scriptname}.log
log_info  "    logfile: ${LogFile}"

source ~/.bash_profile
{
# MASTER_ADDRESS=$1
# ETCD_SERVERS="${MASTER_ADDRESS}:2379"
if ps -ef|grep -i kube-apiserver|grep -v kube-apiserver.sh|grep -v grep; then
  log_warning "  kube-apiserver is running,stop it"
  if ! systemctl stop kube-apiserver; then
    sleep 5
    pids=$(ps -ef|grep -i kube-apiserver|grep -v kube-apiserver.sh|grep -v grep| awk '{printf("%s ",$2)}')
    log_warning "   Execute kill -9 ${pids} to stop kube-apiserver"
    kill -9 ${pids} 2>/dev/null
  fi
fi
log_info "  kube-apiserver is not running"

check_file ${CFG_DIR}/kube-apiserver.conf
check_file ${CFG_DIR}/audit-policy.yaml
check_file /usr/lib/systemd/system/kube-apiserver.service

log_info "  Start generate ${CFG_DIR}/kube-apiserver.conf"
KUBE_APISERVER_OPTS="\"--logtostderr=false \
    --advertise-address=${MASTER_ADDRESS} \
    --authorization-mode=RBAC,Node \
    --audit-log-maxage=30 \
    --audit-log-maxbackup=3  \
    --audit-log-maxsize=100 \
    --audit-log-truncate-enabled=true  \
    --audit-log-path=${LOG_DIR}/k8s-audit.log \
    --audit-policy-file=${CFG_DIR}/audit-policy.yaml \
    --allow-privileged=true \
    --anonymous-auth=false \
    --bind-address=0.0.0.0 \
    --client-ca-file=${SSL_DIR}/ca.pem \
    --enable-aggregator-routing=true \
    --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,NodeRestriction \
    --etcd-servers=${ETCD_SERVERS} \
    --etcd-cafile=${SSL_DIR}/ca.pem \
    --etcd-certfile=${SSL_DIR}/apiserver-etcd-client.pem \
    --etcd-keyfile=${SSL_DIR}/apiserver-etcd-client-key.pem \
    --kubelet-client-certificate=${SSL_DIR}/apiserver-kubelet-client.pem \
    --kubelet-client-key=${SSL_DIR}/apiserver-kubelet-client-key.pem \
    --tls-cert-file=${SSL_DIR}/kube-apiserver.pem  \
    --tls-private-key-file=${SSL_DIR}/kube-apiserver-key.pem \
    --service-cluster-ip-range=10.96.0.0/16 \
    --secure-port=6443 \
    --service-node-port-range=30000-50000  \
    --service-account-key-file=${SSL_DIR}/ca-key.pem \
    --service-account-signing-key-file=${SSL_DIR}/ca-key.pem \
    --service-account-issuer=https://kubernetes.default.svc.cluster.local \
    --requestheader-client-ca-file=${SSL_DIR}/ca.pem \
    --requestheader-extra-headers-prefix=X-Remote-Extra- \
    --requestheader-group-headers=X-Remote-Group \
    --requestheader-username-headers=X-Remote-User \
	--requestheader-allowed-names=front-proxy-clien \
    --runtime-config=api/all=true \
	--proxy-client-key-file=${SSL_DIR}/front-proxy-client-key.pem \
	--proxy-client-cert-file=${SSL_DIR}/front-proxy-client.pem \
	--feature-gates=RemoveSelfLink=false \
	--log-dir=${LOG_DIR}/kube-apiserver \
	--v=2\""

echo "KUBE_APISERVER_OPTS=$KUBE_APISERVER_OPTS">${CFG_DIR}/kube-apiserver.conf
log_info "  Generate ${CFG_DIR}/kube-apiserver.conf done!"

export KUBE_APISERVER_OPTS

log_info "  Start generate  ${CFG_DIR}/audit-policy.yaml"
cat  <<EOF >${CFG_DIR}/audit-policy.yaml
apiVersion: audit.k8s.io/v1 # This is required.
kind: Policy
# Don't generate audit events for all requests in RequestReceived stage.
omitStages:
  - "RequestReceived"
rules:
  # Log pod changes at RequestResponse level
  - level: RequestResponse
    resources:
    - group: ""
      # Resource "pods" doesn't match requests to any subresource of pods,
      # which is consistent with the RBAC policy.
      resources: ["pods"]
  # Log "pods/log", "pods/status" at Metadata level
  - level: Metadata
    resources:
    - group: ""
      resources: ["pods/log", "pods/status"]

  # Don't log requests to a configmap called "controller-leader"
  - level: None
    resources:
    - group: ""
      resources: ["configmaps"]
      resourceNames: ["controller-leader"]

  # Don't log watch requests by the "system:kube-proxy" on endpoints or services
  - level: None
    users: ["system:kube-proxy"]
    verbs: ["watch"]
    resources:
    - group: "" # core API group
      resources: ["endpoints", "services"]

  # Don't log authenticated requests to certain non-resource URL paths.
  - level: None
    userGroups: ["system:authenticated"]
    nonResourceURLs:
    - "/api*" # Wildcard matching.
    - "/version"

  # Log the request body of configmap changes in kube-system.
  - level: Request
    resources:
    - group: "" # core API group
      resources: ["configmaps"]
    # This rule only applies to resources in the "kube-system" namespace.
    # The empty string "" can be used to select non-namespaced resources.
    namespaces: ["kube-system"]

  # Log configmap and secret changes in all other namespaces at the Metadata level.
  - level: Metadata
    resources:
    - group: "" # core API group
      resources: ["secrets", "configmaps"]

  # Log all other resources in core and extensions at the Request level.
  - level: Request
    resources:
    - group: "" # core API group
    - group: "extensions" # Version of group should NOT be included.

  # A catch-all rule to log all other requests at the Metadata level.
  - level: Metadata
    # Long-running requests like watches that fall under this rule will not
    # generate an audit event in RequestReceived.
    omitStages:
      - "RequestReceived"
# refer to https://kubernetes.io/docs/tasks/debug-application-cluster/audit/
EOF
log_info "  Generate ${CFG_DIR}/audit-policy.yaml done"

log_info "  Start generate /usr/lib/systemd/system/kube-apiserver.service"
cat <<EOF >/usr/lib/systemd/system/kube-apiserver.service
[Unit]
Documentation=https://github.com/kubernetes/kubernetes
Description=Kubernetes:Apiserver
After=network.target network-online.target
Wants=network-online.target
[Install]
WantedBy=multi-user.target
[Service]
RestartSec=5
Restart=on-failure
EnvironmentFile=-/etc/kubernetes/cfg/kube-apiserver.conf
ExecStart=/usr/sbin/kube-apiserver \$KUBE_APISERVER_OPTS
EOF

# if [ -f ${RUNDIR}/kubeapi_update.sh ];then
#     echo "ExecStartPre=${RUNDIR}/kubeapi_update.sh" >>/usr/lib/systemd/system/kube-apiserver.service
# fi

log_info "  Generate /usr/lib/systemd/system/kube-apiserver.service"

log_info "  Try to start and enable kube-apiserver.service"
echo
systemctl daemon-reload && systemctl enable kube-apiserver && systemctl restart kube-apiserver;systemctl status kube-apiserver
echo
if ps -ef|grep -i kube-apiserver|grep -v kube-apiserver.sh|grep -v grep; then
  log_info "  kube-apiserver is running successfully!"
else
  log_info "  Start kube-apiserver failed,pls check in log file /var/log/message"
  log_info "  tail -f /var/log/message"
  do_exit 8
fi

echo "${RC}" >/tmp/RC.$$
log_info ""
log_info "   RC=${RC}"
log_info ""
} 2>&1 | tee -a $LogFile

if [ -f /tmp/RC.$$ ]; then
    RC=$(cat /tmp/RC.$$)
    rm -f /tmp/RC.$$
fi
if [ "$RC" == "0" ]; then
    log_info   "OK: EndofScript ${scriptname} "    | tee -a $LogFile
else
    log_error  "ERROR: EndofScript ${scriptname} " | tee -a $LogFile
fi

ende=$(date +%s)
diff=$((ende - starttime))
log_info     "$(date)   Runtime      :   $diff"  | tee -a $LogFile
log_info     "Save log to ${LogFile}         "   | tee -a $LogFile
logrename  ${LogFile}
exit ${RC}

#--authorization-mode=Node,RBAC： 开启 Node 和 RBAC 授权模式，拒绝未授权的请求；
#--enable-admission-plugins：启用 ServiceAccount 和 NodeRestriction；
#--service-account-key-file：签名 ServiceAccount Token 的公钥文件，kube-controller-manager 的 --service-account-private-key-file 指定私钥文件，两者配对使用；
#--tls-*-file：指定 apiserver 使用的证书、私钥和 CA 文件。--client-ca-file 用于验证 client (kue-controller-manager、kube-scheduler、kubelet、kube-proxy 等)请求所带的证书；
#--kubelet-client-certificate、--kubelet-client-key：如果指定，则使用 https 访问 kubelet APIs；需要为证书对应的用户(上面 kubernetes*.pem 证书的用户为 kubernetes) 用户定义 RBAC 规则，否则访问 kubelet API 时提示未授权；
#--bind-address： 不能为 127.0.0.1，否则外界不能访问它的安全端口 6443；
#--insecure-port=0：关闭监听非安全端口(8080)；
#--service-cluster-ip-range： 指定 Service Cluster IP 地址段；
#--service-node-port-range： 指定 NodePort 的端口范围；
#--runtime-config=api/all=true： 启用所有版本的 APIs，如 autoscaling/v2alpha1；
#--enable-bootstrap-token-auth：启用 kubelet bootstrap 的 token 认证；
#--apiserver-count=3：指定集群运行模式，多台 kube-apiserver 会通过 leader 选举产生一个工作节点，其它节点处于阻塞状态；
#kubelet-port not using here
#--service-cluster-ip-rang					  address using for service
#--allow-privileged       					  If true, allow privileged containers. [default=false]
#--master is not using
##--apiserver-count int					      The number of apiservers running in the cluster, must be a positive number. \
#												(In use when --endpoint-reconciler-type=master-count is enabled.) (default 1)
#--endpoint-reconciler-type string             Use an endpoint reconciler (master-count, lease, none) (default "lease")		
#--kubelet-preferred-address-types strings     List of the preferred NodeAddressTypes to use for kubelet connections. \
# 		     									(default [Hostname,InternalDNS,InternalIP,ExternalDNS,ExternalIP])	
#—feature-gates=PodShareProcessNamespace=true 1.11后已经默认开启了
#
#
# ---------------------enable PodPreset
#修改原[ - --runtime-config=api/all=true]为[- --runtime-config=api/all=true,settings.k8s.io/v1alpha1=true], 新加一行[- --enable-admission-plugins=PodPreset]
#not work for v1225
