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

i=1
RC=0
scriptname=$(basename $0)
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
if ps -ef|grep -i kube-proxy|grep -v grep|grep -v kube-proxy.sh; then
  log_info "  kubelet is running,stop it"
  if ! systemctl stop kube-proxy; then
    sleep 5
    pids=$(ps -ef|grep -i kube-proxy|grep -v grep|grep -v kube-proxy.sh| awk '{printf("%s ",$2)}')
    log_warning "   Execute kill -9 ${pids} to stop kube-proxy"
    kill -9 ${pids} 2>/dev/null
   fi
fi
log_info "  kube-proxy is not running"
NODE_ADDRESS=$(hostname)

check_file ${CFG_DIR}/kube-proxy.yaml
check_file /etc/kubernetes/cfg/kube-proxy.conf
check_file /usr/lib/systemd/system/kube-proxy.service

log_info "  Create kube-proxy config yaml file"
# kubeadm configprint init-defaults --component-configs KubeProxyConfiguration >kube-proxy.conf
cat <<EOF >${CFG_DIR}/kube-proxy.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: 0.0.0.0
clientConnection:
  acceptContentTypes: ""
  burst: 0
  contentType: ""
  kubeconfig: ${CFG_DIR}/kube-proxy.kubeconfig
  qps: 0
clusterCIDR: 10.244.0.0/16
configSyncPeriod: 15m0s
conntrack:
  maxPerCore: 32768
  min: 131072
  tcpCloseWaitTimeout: 1h0m0s
  tcpEstablishedTimeout: 24h0m0s
enableProfiling: false
hostnameOverride: ${NODE_ADDRESS} 
healthzBindAddress: 0.0.0.0:10256
metricsBindAddress: 0.0.0.0:10249
mode: ipvs
ipvs:
  excludeCIDRs: null
  minSyncPeriod: 0s
  scheduler: "rr"
  strictARP: false
  syncPeriod: 0s
  tcpFinTimeout: 0s
  tcpTimeout: 0s
  udpTimeout: 0s  
EOF
log_info "  kube-proxy config yaml file ${CFG_DIR}/kube-proxy.yaml is created"

export KUBE_PROXY_OPTS="--logtostderr=false --v=2 --log-dir=${LOG_DIR}/kube-proxy --config=${CFG_DIR}/kube-proxy.yaml"

log_info "  start generate kube-proxy config file /etc/kubernetes/cfg/kube-proxy.conf"
echo "KUBE_PROXY_OPTS=$KUBE_PROXY_OPTS">/etc/kubernetes/cfg/kube-proxy.conf
log_info "  kube-proxy config file /etc/kubernetes/cfg/kube-proxy.conf is generated"

log_info "  Create kube-proxy service file /usr/lib/systemd/system/kube-proxy.service"
cat <<EOF >/usr/lib/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
EnvironmentFile=-${CFG_DIR}/kube-proxy.conf
ExecStart=/usr/sbin/kube-proxy \$KUBE_PROXY_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
log_info  "  kube-proxy service file /usr/lib/systemd/system/kube-proxy.service is created"


log_info  "  Tring to start kube-proxy service"
systemctl daemon-reload;systemctl enable kube-proxy;systemctl restart kube-proxy;systemctl status kube-proxy.service
#SupportIPVSProxyMode：if not work ,remove this line
#clusterCIDR 后面CNI网络的IP段，不能与任何网络重复，否则获报错

systemctl daemon-reload;systemctl enable kubelet;systemctl restart kubelet
if ps -ef|grep -i kube-proxy|grep -v grep|grep -v kube-proxy.sh; then
  echo
  log_info "  kube-proxy is running successfully!"
  echo
else
  log_error "Start kube-proxy failed,pls check in log file /var/log/message "
  log_info  "${LOG_DIR}"
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