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

check_file ~/component_new.txt
get_component.sh
. ~/component.sh

if [ -f /workdata/1225/kube-apiserver ]; then
    apiversion=`echo $(/workdata/1225/kube-apiserver --version)|cut -d" " -f2|cut -c2,4,5,7`
    if [ ${apiversion} -gt ${KUBE_VERSION} ]; then
        log_warning "current kube-apiserver version:${KUBE_VERSION} but new version found ${apiversion} "
        echo "lupdate kubernet to new version ${apiversion}"
        echo "mv -p /usr/sbin/kube-apiserver /usr/sbin/kube-apiserver.old"      >>kubeapi_update.sh
        echo "cp -p /workdata/1225/kube-apiserver /usr/sbin"                    >>kubeapi_update.sh
    fi
fi

if [ -f /workdata/1225/kube-controller-manager ]; then
    apiversion=`echo $(/workdata/1225/kube-controller-manager --version)|cut -d" " -f2|cut -c2,4,5,7`
    if [ ${apiversion} -gt ${KUBE_VERSION} ]; then
        log_warning "current kube-controller-manager version:${KUBE_VERSION} but new version found ${apiversion}"
        echo "mv -p /usr/sbin/kube-controller-manager /usr/sbin/kube-controller-manager.old"      >>kubecon_update.sh
        echo "cp -p /workdata/1225/kube-controller-manager /usr/sbin"                             >>kubecon_update.sh
    fi
fi

if [ -f /workdata/1225/kube-scheduler ]; then
    apiversion=`echo $(/workdata/1225/kube-scheduler --version)|cut -d" " -f2|cut -c2,4,5,7`
    if [ ${apiversion} -gt ${KUBE_VERSION} ]; then
        log_warning "current kube-scheduler version:${KUBE_VERSION} but new version found ${apiversion}"
        echo "mv -p /usr/sbin/kube-scheduler /usr/sbin/kube-scheduler.old"      >>kubesch_update.sh
        echo "cp -p /workdata/1225/kube-scheduler /usr/sbin"                    >>kubesch_update.sh
    fi
fi

if [ -f /workdata/1225/kubelet ]; then
    apiversion=`echo $(/workdata/1225/kubelet --version)|cut -d" " -f2|cut -c2,4,5,7`
    if [ ${apiversion} -gt ${KUBE_VERSION} ]; then
        log_warning "current kubelet version:${KUBE_VERSION} but new version found ${apiversion}"
        echo "mv -p /usr/sbin/kubelet /usr/sbin/kubelet.old"      >>kubelet_update.sh
        echo "cp -p /workdata/1225/kubelet /usr/sbin"             >>kubelet_update.sh
    fi
fi

if [ -f /workdata/1225/kube-proxy ]; then
    apiversion=`echo $(/workdata/1225/kube-proxy --version)|cut -d" " -f2|cut -c2,4,5,7`
    if [ ${apiversion} -gt ${KUBE_VERSION} ]; then
        log_warning "current kube-proxy version ${KUBE_VERSION} but new version found ${apiversion}"
        echo "mv -p /usr/sbin/kube-proxy /usr/sbin/kube-proxy.old"      >>kubepro_update.sh
        echo "cp -p /workdata/1225/kube-proxy /usr/sbin"                >>kubepro_update.sh
    fi
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