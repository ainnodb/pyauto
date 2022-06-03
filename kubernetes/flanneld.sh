#!/bin/bash
#=============================================================================
# HEADER
#=============================================================================
#% SYNOPSIS
#%    ${prog}
#%
#% DESCRIPTION
#%    Script to deploy flanneld service
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

systemctl stop flanneld;
{

if ps -ef|grep -i flanneld|grep -v flanneld.sh|grep -v grep; then
  log_warning "  flanneld is running,stop it"
  if ! systemctl stop flanneld; then
    sleep 5
    pids=$(ps -ef|grep -i flanneld|grep -v flanneld.sh|grep -v grep| awk '{printf("%s ",$2)}')
    log_warning "   Execute kill -9 ${pids} to stop flanneld"
    kill -9 ${pids} 2>/dev/null
  fi
fi
log_info "  flanneld is not running"

check_file /etc/sysconfig/flanneld 
check_file /usr/lib/systemd/system/flanneld.service 

if [ ${#ETCD_NODE_NAMES_DOMAIN[@]} -eq 1 ]; then
  echo "Configure standalone ETCD_SERVERS for flanneld"
  ETCD_SERVERS=${ETCD_SERVERS},http://127.0.0.1:2379
fi

FLANNEL_OPTIONS="--etcd-cafile=${SSL_DIR}/ca.pem \
   --etcd-certfile=${SSL_DIR}/flanneld.pem \
   --etcd-keyfile=${SSL_DIR}/flanneld-key.pem \
   --etcd-endpoints=${ETCD_SERVERS} \
   --etcd-prefix=/atomic.io/network \
   --iface=ens224 \
   --ip-masq"
if ! [ -d /etc/kubernetes/flanneld ]; then
    mkdir /etc/kubernetes/flanneld
fi

log_info "   Generaget flanneld configure file /etc/sysconfig/flanneld"
echo "FLANNEL_OPTIONS=$FLANNEL_OPTIONS">/etc/sysconfig/flanneld
log_info "   Generaget flanneld configure file /etc/sysconfig/flanneld done"
echo 
log_info "   Generaget flanneld services file /usr/lib/systemd/system/flanneld.service"
cat <<EOF >/usr/lib/systemd/system/flanneld.service
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/flanneld
ExecStart=/usr/sbin/flanneld \$FLANNEL_OPTIONS
ExecStartPost=/usr/sbin/mk-docker-opts.sh -k DOCKER_OPTS -d /etc/kubernetes/flanneld/docker_opts.env
   
Restart=always
RestartSec=5
StartLimitInterval=0
[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
EOF
log_info "   Generaget flanneld services file /usr/lib/systemd/system/flanneld.service"

log_info "   Trying to start and enable flanneld serivice"
systemctl daemon-reload;systemctl start flanneld;systemctl enable flanneld;systemctl status flanneld
sleep 10
echo 
if ps -ef|grep -i flanneld|grep -v flanneld.sh|grep -v grep; then
  echo
  log_info  "  Flanneld is running successfully!"
  echo
else
  log_error "  start Flanneld,pls check in log file /var/log/message"
  log_error "  tail -f /var/log/message"
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

# /usr/local/mk-docker-opts.sh -c
# cp -p /run/docker_opts.env /etc/kubernetes/flanneld/
# systemctl daemon-reload ;systemctl restart docker;systemctl status docker


# FLANNEL_OPTIONS="--etcd-cafile=/etc/kubernetes/ssl/ca.pem \
   # --etcd-certfile=/etc/kubernetes/ssl/flanneld.pem \
   # --etcd-keyfile=/etc/kubernetes/ssl/flanneld-key.pem \
   # --etcd-endpoints=win72=https://win72.inno.com:2379 \
   # --etcd-prefix=/atomic.io/network \
   # --iface=ens224 \
   # --ip-masq"
