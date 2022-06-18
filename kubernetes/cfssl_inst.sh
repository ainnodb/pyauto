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
log_info "    Start install cfssl"
mywget https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssl_1.6.1_linux_amd64 cfssl
if [ $? -eq 0 ]; then
    echo -y|cp -p ${DOWNLOADDIR}/cfssl /usr/sbin/cfssl
    chmod +x /usr/sbin/cfssl
    log_info "    cfssl install with version $(cfssl version) successfully"
else
    log_error " cfssl install falied"
    do_exit 8
fi
echo;echo

log_info "    Start install cfssl-certinfo"
mywget https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssl-certinfo_1.6.1_linux_amd64 cfssl-certinfo

if [ $? -eq 0 ]; then
    echo -y|cp -p ${DOWNLOADDIR}/cfssl-certinfo /usr/sbin/cfssl-certinfo
    chmod +x /usr/sbin/cfssl-certinfo
    log_info "    cfssl-certinfo install successfully"
else
    log_error " cfssl-certinfo install falied"
    do_exit 8
fi

echo;echo

log_info "    Start install cfssljson"
mywget https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssljson_1.6.1_linux_amd64 cfssljson
if [ $? -eq 0 ]; then
    log_info "    cfssljson install successfully"
else
    log_error " cfssljson install falied"
    do_exit 8
fi
echo -y|cp -p ${DOWNLOADDIR}/cfssljson /usr/sbin/cfssljson
chmod +x /usr/sbin/cfssljson

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