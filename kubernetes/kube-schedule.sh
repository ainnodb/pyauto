#!/bin/bash
#=============================================================================
# HEADER
#=============================================================================
#% SYNOPSIS
#%    ${prog}
#%
#% DESCRIPTION
#%    Script to deploy kube-scheduler service
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
if ps -ef|grep -i kube-scheduler|grep -v grep|grep -v kube-scheduler.sh; then
  log_info "  kube-scheduler is running,stop it"
  if ! systemctl stop kube-scheduler; then
    sleep 5
    pids=$(ps -ef|grep -i kube-scheduler|grep -v grep|grep -v kube-scheduler.sh| awk '{printf("%s ",$2)}')
    log_warning "   Execute kill -9 ${pids} to stop kube-scheduler"
    kill -9 ${pids} 2>/dev/null
  fi
fi
log_info "  kube-scheduler is not running"
check_file ${CFG_DIR}/kube-scheduler.conf
check_file /usr/lib/systemd/system/kube-scheduler.service

# MASTER_ADDRESS=$1
KUBE_SCHEDULER_OPTS="--kubeconfig=${CFG_DIR}/kube-scheduler.kubeconfig --address=127.0.0.1  --cert-dir=${SSL_DIR} --leader-elect=true \
 --logtostderr=false \
 --v=2  \
 --log-dir=${LOG_DIR}/kube-scheduler \
 --client-ca-file=${SSL_DIR}/ca.pem \
 --authentication-kubeconfig=${CFG_DIR}/kube-scheduler.kubeconfig \
 --authorization-kubeconfig=${CFG_DIR}/kube-scheduler.kubeconfig \
 --requestheader-extra-headers-prefix=X-Remote-Extra- \
 --requestheader-group-headers=X-Remote-Group \
 --requestheader-username-headers=X-Remote-User \
 --requestheader-allowed-names=front-proxy-client"

#--tls-private-key-file=${SSL_DIR}/kube-scheduler.key  this autogenerate by system
#--tls-cert-file=${SSL_DIR}/kube-scheduler.pem \

echo "KUBE_SCHEDULER_OPTS=$KUBE_SCHEDULER_OPTS">${CFG_DIR}/kube-scheduler.conf
log_info "  configure  file kube-scheduler is set as "
log_info "  KUBE_SCHEDULER_OPTS=$KUBE_SCHEDULER_OPTS"
echo 
log_info "  Start generate  kube-scheduler.service file /usr/lib/systemd/system/kube-scheduler.service"
cat <<EOF >/usr/lib/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes
After=network.target network-online.target
Wants=network-online.target

[Service]
EnvironmentFile=-${CFG_DIR}/kube-scheduler.conf
ExecStart=/usr/sbin/kube-scheduler \$KUBE_SCHEDULER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat /usr/lib/systemd/system/kube-scheduler.service
log_info "  Generate  kube-scheduler.service file /usr/lib/systemd/system/kube-scheduler.service done!"
echo 
log_info "  Try to starting  kube-scheduler"
systemctl daemon-reload;systemctl enable kube-scheduler;systemctl restart kube-scheduler;systemctl status kube-scheduler.service
if ps -ef|grep -i kube-scheduler|grep -v kube-scheduler.sh|grep -v grep; then
  log_info "  kube-scheduler is running successfully!"
else
  log_eror "start kube-scheduler failed,pls check in log file /var/log/message"
  log_info "tail -f /var/log/message"
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

# --address：在 127.0.0.1:10251 端口接收 http /metrics 请求；kube-scheduler 目前还不支持接收 https 请求；
# --kubeconfig：指定 kubeconfig 文件路径，kube-scheduler 使用它连接和验证 kube-apiserver；
# --leader-elect=true：集群运行模式，启用选举功能；被选为 leader 的节点负责处理工作，其它节点为阻塞状态；
#
#folowing is v1 version
#KUBE_SCHEDULER_OPTS="--kubeconfig=${CFG_DIR}/kube-scheduler.kubeconfig --address=127.0.0.1  --cert-dir=${SSL_DIR} --leader-elect=true \
# --logtostderr=false \
# --v=2  \
# --log-dir=${LOG_DIR}/kube-scheduler \
# --client-ca-file=${SSL_DIR}/ca.pem \"
# mark kube-scheduler.key is autogenerate by k8s.