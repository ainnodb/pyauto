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
log_info "Start install kubernetes"
mywget https://dl.k8s.io/v1.22.4/kubernetes-server-linux-amd64.tar.gz kubernetes-server-linux-amd64.tar.gz

tar -xf ${DOWNLOADDIR}/kubernetes-server-linux-amd64.tar.gz -C ${DOWNLOADDIR}
cp -p ${DOWNLOADDIR}/kubernetes/server/bin/{kubectl,kube-apiserver,kube-controller-manager,kube-scheduler,kube-proxy,kubelet} /usr/sbin

sh ${RUNDIR}/xsync -h "${MS_NODE_NAMES[@]}" -d /usr/sbin/kube-apiserver
sh ${RUNDIR}/xsync -h "${MS_NODE_NAMES[@]}" -d /usr/sbin/kube-controller-manager
sh ${RUNDIR}/xsync -h "${MS_NODE_NAMES[@]}" -d /usr/sbin/kube-scheduler
sh ${RUNDIR}/xsync -h "${NODE_NAMES[@]}" -d /usr/sbin/kube-proxy
sh ${RUNDIR}/xsync -h "${NODE_NAMES[@]}" -d /usr/sbin/kubelet
sh ${RUNDIR}/xsync -h "${NODE_NAMES[@]}" -d /usr/sbin/kubectl

if [ $? -eq 0 ]; then
  log_info "kubernetes install with version $(echo "https://dl.k8s.io/v1.24.0/kubernetes-server-linux-amd64.tar.gz"|cut -d '/' -f 4) successfully"
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