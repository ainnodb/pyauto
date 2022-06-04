#!/bin/bash
# HEADER
#================================================================
#% SYNOPSIS
#%    ${prog}
#%
#% DESCRIPTION
#%    setup kubernetes kubelet services
#%
#% ARGUMENTS
#%     use hostname as default
#%
#% EXAMPLES
#%    ${prog}
#%
#================================================================
#  HISTORY
#     20220104  innod motingxia@163.com
#================================================================
#  NOTES
#================================================================
# END_OF_HEADER
#================================================================

#================================================================
#  IMPORT COMMON FUNCTIONS AND VARIABLES
#================================================================
RUNDIR="$(cd "$(dirname "${0}")" && pwd)"
if [ -z "${FUNCTIONS_IMPORTED}" ]; then
  . ${RUNDIR}/functions.ksh
fi

#================================================================
#  FUNCTIONS
#================================================================
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


myinstall haproxy 
myinstall keepalived
if [ $MASTERNODE = $HOSTNAME ] ;then
    nodepriority=100
    keepstat="MASTER"
    routid="kubenetes1"
else
    nodepriority=80
    keepstat="BACKUP"
    routid="kubenetes2"
fi

keepconf() {
cat >/etc/keepalived/keepalived.conf <<EOF
global_defs {
  router_id LVS_DEVEL
  script_user root
  enable_script_security
  router_id  ${routid}
}
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 5
  weight -5
  fall 2 
  rise 1
  timeout 2
}
vrrp_instance VI_1 {
  state ${keepstat}
  interface ens224
  mcast_src_ip $(get_ip $(hostname))
  virtual_router_id 51
  priority ${nodepriority}
  advert_int 2
  authentication {
      auth_type PASS
      auth_pass K8SHA_KA_AUTH
  }
  virtual_ipaddress {
      ${APISERVER}
  }
  track_script {
      check_apiserver.sh
  }
}
EOF

cat >/etc/keepalived/check_apiserver.sh <<EOF
#!/bin/bash
err=0
for k in \$(seq 1 3)
do
  check_code=\$(pgrep haproxy)
  if [[ \$check_code == "" ]]; then
      err=\$(expr \$err + 1)
      sleep 1
      continue
  else
      err=0
      break
  fi
done

if [[ \$err != "0" ]]; then
  echo "systemctl stop keepalived"
  systemctl stop keepalived
  exit 1
else
  exit 0
fi
EOF
}


#haproxy.cfg配置文件
haproxyconf () {
cat >/etc/haproxy/haproxy.cfg <<EOF
global
  maxconn 2000
  ulimit-n 16384
  log 127.0.0.1 local0 err
  stats timeout 30s

defaults
  log global
  mode http
  option httplog
  timeout connect 5000
  timeout client 50000
  timeout server 50000
  timeout http-request 15s
  timeout http-keep-alive 15s

frontend monitor-in
  bind *:33305
  mode http
  option httplog
  monitor-uri /monitor

listen admin_stats                               
  mode http
  bind :8888
  log 127.0.0.1 local0 err
  stats enable
  stats hide-version                    
  stats uri     /stats  
  stats realm   welcome login\ Haproxy
  stats auth    admin:admin
  stats admin if TRUE

frontend k8smaster
  bind *:16443
  mode tcp
  timeout client 1h
  log global
  option tcplog
  default_backend k8smaster
  tcp-request inspect-delay 5s
  acl is_websocket hdr(Upgrade) -i WebSocket
  acl is_websocket hdr_beg(Host) -i ws


backend k8smaster
  mode tcp
  option tcplog
  stats enable
  stats uri     /kubernetes?stats  
  stats realm   Haproxy\ Statistics
  stats auth    admin:admin
  option tcp-check
  balance roundrobin
  default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
  server  ${MASTERNODE}  ${MASTERIP}:6443 check
  server  ${BACKUPNODE}  ${BACKUPIP}:6443 check
EOF
}

{
if ps -ef|grep -i keepalived|grep -v grep; then
  log_alert "  keepalived is running,stop it"
  if ! systemctl stop keepalived; then
    sleep 5
    pids=$(ps -ef|grep -i keepalived|grep -v grep| awk '{printf("%s ",$2)}')
    log_warning "   Execute kill -9 ${pids} to stop keepalived"
    kill -9 ${pids} 2>/dev/null
  fi
fi
log_alert "  keepalived is not running"

if ps -ef|grep -i haproxy|grep -v grep; then
  log_alert "  haproxy is running,stop it"
  if ! systemctl stop haproxy; then
    sleep 5
    pids=$(ps -ef|grep -i haproxy|grep -v grep| awk '{printf("%s ",$2)}')
    log_alert "   Execute kill -9 ${pids} to stop haproxy"
    kill -9 ${pids} 2>/dev/null
  fi
fi
log_info "  haproxy is not running"

check_file /etc/keepalived/check_apiserver.sh
check_file /etc/keepalived/keepalived.conf
check_file /etc/haproxy/haproxy.cfg

keepconf
haproxyconf

chmod 755 /etc/keepalived/check_apiserver.sh
log_info "   Trying to start keepalived"
systemctl start keepalived && systemctl enable keepalived
echo 
if ps -ef|grep -i keepalived|grep -v grep; then
  echo
  log_info "  Start  keepalived successfully!!"
  echo 
else
  log_error "start keepalived failed,pls check in log file /var/log/message"
  log_error "tail -f /var/log/message"
  echo
  do_exit 8
fi

log_info "   Trying to start haproxy"
systemctl start haproxy && systemctl enable haproxy
echo
if ps -ef|grep -i haproxy|grep -v grep; then
  echo
  log_info "  Start  haproxy successfully!!"
  echo 
else
  log_error "start haproxy failed,pls check in log file /var/log/message"
  log_error "tail -f /var/log/message"
  echo
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