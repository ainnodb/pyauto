#!/bin/bash
#=============================================================================
# HEADER
#=============================================================================
#% SYNOPSIS
#%    ${prog}
#%
#% DESCRIPTION
#%    Script to deploy etcd service
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
# example: bash etcd.sh etcd01 192.168.0.101 etcd01=https://192.168.0.101:2380,etcd02=https://192.168.0.102:2380
# ETCD_CLUSTER="win70=https://win70.inno.com:2380,win71=https://win71.inno.com:2380,win72=https://win72.inno.com:2380"

#######################################################################################################################
## MAIN
#######################################################################################################################
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

export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/usr/local/etcd/bin
{

ETCD_NAME=$(hostname -s)
ETCD_IP=$(nslookup $(hostname)|grep -i Address|awk '{print $2}'|grep -v '#')
ETCD_VERSION=3.5.0

# if ps -ef|grep -i etcd| grep -v grep|grep -v flanneld|grep -v etcd_conf.sh; then
#   log_info "    ETCD is running ,stop it "
#   if ! systemctl stop etcd; then
#     sleep 5
#     pids=$(ps -ef|grep -i etcd| grep -v grep|grep -v flanneld|grep -v etcd_conf.sh| awk '{printf("%s ",$2)}')
#     log_warning "   Execute kill -9 ${pids} to stop etcd"
#     kill -9 ${pids} 2>/dev/null
#   fi
# fi
echo "${ETCD_CFG_DIR}/etcd.yml"
log_info "  Delete old etcd file "
check_file /usr/lib/systemd/system/etcd.service
check_file ${ETCD_CFG_DIR}/etcd.yml


# if [ $(hostname) != ${MASTERNODE} ];then
#   log_info "  Update certification from master"
#   scp -rp ${MASTERNODE}:${ETCD_SSL_DIR}/* ${ETCD_SSL_DIR}
#   scp -rp ${MASTERNODE}:${SSL_DIR}/* ${SSL_DIR}
#   log_info "  Update certification from master done"
# fi

log_info "  Generate ${ETCD_CFG_DIR}/etcd.yml"
cat <<EOF >${ETCD_CFG_DIR}/etcd.yml
#etcd ${ETCD_VERSION}
name: ${ETCD_NAME}
data-dir: /etc/etcd/data
listen-peer-urls: https://${ETCD_IP}:2380
listen-client-urls: https://${ETCD_IP}:2379,http://127.0.0.1:2379

advertise-client-urls: https://${ETCD_NAME}:2379
initial-advertise-peer-urls: https://${ETCD_NAME}:2380
initial-cluster: ${ETCD_CLUSTER}
initial-cluster-token: etcd-cluster
initial-cluster-state: new
enable-v2: true

client-transport-security:
  cert-file: ${ETCD_SSL_DIR}/server.pem
  key-file: ${ETCD_SSL_DIR}/server-key.pem
  client-cert-auth: true 
  trusted-ca-file: ${ETCD_SSL_DIR}/ca.pem
  auto-tls: true 

peer-transport-security:
  cert-file: ${ETCD_SSL_DIR}/peer.pem
  key-file: ${ETCD_SSL_DIR}/peer-key.pem
  client-cert-auth: true
  trusted-ca-file: ${ETCD_SSL_DIR}/ca.pem
  auto-tls: true

debug: false
logger: zap
log-outputs: [stderr]
EOF

log_info "    ${ETCD_CFG_DIR}/etcd.yml generated as below:"
cat   ${ETCD_CFG_DIR}/etcd.yml
log_info "    Generate etcd.service file "
cat <<EOF >/usr/lib/systemd/system/etcd.service
[Unit]
Description=Etcd Server
Documentation=https://github.com/etcd-io/etcd
Conflicts=etcd.service
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
LimitNOFILE=65536
Restart=on-failure
RestartSec=5s
TimeoutStartSec=0
ExecStart=/usr/local/etcd/bin/etcd --config-file=/etc/etcd/cfg/etcd.yml

[Install]
WantedBy=multi-user.target
EOF
log_info "    Generate etcd.service /usr/lib/systemd/system/etcd.service done "
log_info "    Trying to start etcd.service......"
systemctl daemon-reload;systemctl enable etcd;systemctl restart etcd;systemctl status etcd.service
sleep 3
if ps -ef|grep -i etcd| grep -v grep|grep -v flanneld|grep -v etcd_conf.sh; then
  log_info "  ETCD is running successfully! \n"
else
  log_info "  start etcd failed,pls check in log file /var/log/message"
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