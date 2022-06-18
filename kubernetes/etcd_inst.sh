#!/usr/bin/ksh
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

{
log_info "Start  install GOLANG"
mywget https://go.dev/dl/go1.16.10.linux-amd64.tar.gz go1.16.10.linux-amd64.tar.gz
tar -xf ${DOWNLOADDIR}/go1.16.10.linux-amd64.tar.gz -C /usr/local
chown root:root -R /usr/local/go
if which go;then
    log_info "go enviroment is already setup"
else
    log_warning  "go enviroment is not setup"
    echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bash_profile
    log_info "go enviroment setup done"
fi

go version
if [ $? -eq 0 ]; then
  log_info "GOLANG install successfully"
fi

log_info "Start install etcd"
mywget https://github.com/etcd-io/etcd/archive/v3.5.0.zip etcd.zip
unzip -q ${DOWNLOADDIR}/etcd.zip -d /usr/local
mv /usr/local/etcd-3.5.0 /usr/local/etcd

cd /usr/local/etcd/ && go env -w GOPROXY=https://goproxy.cn && make 
if [ $? -eq 0 ]; then
  log_info "etcd install successfully"
  etcd --version
else 
  log_error "etcd install failed,pls check the error"
  do_exit 8
fi
if which etcd; then
    log_info "etcd enviroment is already setup"
else
    log_warning  "etcd enviroment is not setup"
    echo "export PATH=\$PATH:/usr/local/etcd/bin" >> ~/.bash_profile
    log_info "etcd enviroment is setup done"
fi
if [ ${#ETCD_NODE_NAMES_DOMAIN[@]} -gt 1 ]; then
    log_info "   copy /usr/local/go and /usr/local/etcd to other etcd server"
    sh ${RUNDIR}/xsync -h "${ETCD_NODE_NAMES[@]}" -d /usr/local/go
    sh ${RUNDIR}/xsync -h "${ETCD_NODE_NAMES[@]}" -d /usr/local/etcd
    log_info "   copy /usr/local/go and /usr/local/etcd to other etcd server done"
fi
cd ${RUNDIR}
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