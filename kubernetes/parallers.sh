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
#%    sh parallers -h "${NODE_NAMES[@]}" -d {PATH}/command.sh
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

if [ $# -lt 4 ]; then
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

#=============================================================================
#  Main
#=============================================================================

{
nodes=()
i=0
thred=0
while [ $# -gt 0 ]; do
    case ${1} in
    -h)
        shift
        nodes[i]="$1"
        let i=i+1
        shift
        ;;
    -c)
        shift
        break
        ;;
    *)
        echo
        nodes[i]=$1
        let i=i+1
        shift
        continue
        ;;
    esac
done
tmpfile=$$.fifo   # ??????????????????
mkfifo /tmp/$tmpfile   # ????????????
exec 7<>/tmp/$tmpfile  # ??????????????????4??????????????????????????????$tmpfile
rm -rf /tmp/$tmpfile       # ??????????????????????????????

sourcefile=$@
thred=${#nodes[@]}
	
# ??????????????????????????????????????????
for (( i = 1;i<=${thred};i++ ));do echo;done >&7 # ???????????????????????????

Count=0
# for host in `seq 0 ${#nodes[@]}`
# for host in "${#nodes[@]}"
let thred=thred-1

for (( i=0;i<=${thred};i++ ))
    do
        if test -z ${nodes[$i]} ; then
        # if test -z ${host} ; then
            break
        else
            read -u7
            let Count+=1
            {
                log_info "Parallel execute task$Count on  ${nodes[$i]} "
                if [ $(hostname -s) ==  ${nodes[$i]} ]; then
                    log_info "Parallel execute task$Count on localhost: ${nodes[$i]}"
                    sh ${sourcefile}
                else
                    checkssh ${nodes[$i]}
                    ssh ${nodes[$i]} ${sourcefile}
                    echo >&7
                fi
            } &
        fi
    done 
    wait
    exec 7>&-   # ????????????
#=============================================================================
#  Foot
#=============================================================================
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