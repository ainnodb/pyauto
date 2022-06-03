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
log_info  "logfile: ${LogFile}"
source ~/.bash_profile

{
check_file ~/component.sh
if which kube-apiserver; then
    apiversion=`echo $(kube-apiserver --version)|cut -d" " -f2|cut -c2,4,5,7`
    echo "export KUBE_APISERVER_VERSION=${apiversion}"    >>~/component.sh
fi
if which kube-controller-manager; then
    apiversion=`echo $(kube-controller-manager --version)|cut -d" " -f2|cut -c2,4,5,7`
    echo "export KUBE_CONTROLLER_MANAGER_VERSION=${apiversion}"   >>~/component.sh
fi
if which kube-scheduler; then
    apiversion=`echo $(kube-scheduler --version)|cut -d" " -f2|cut -c2,4,5,7`
    echo "export KUBE_SCHEDULER_VERSION=${apiversion}"  >>~/component.sh
fi
if which kubelet; then
    apiversion=`echo $(kubelet --version)|cut -d" " -f2|cut -c2,4,5,7`
    echo "export KUBELET_VERSION=${apiversion}"      >>~/component.sh
fi
if which kube-proxy; then
    apiversion=`echo $(kube-proxy --version)|cut -d" " -f2|cut -c2,4,5,7`
    echo "export KUBE_PROXY_VERSION=${apiversion}"   >>~/component.sh
fi
echo "export KUBE_VERSION=${apiversion}"   >>~/component.sh

echo "${RC}" >/tmp/RC.$$
log_info ""
log_info "RC=${RC}"
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