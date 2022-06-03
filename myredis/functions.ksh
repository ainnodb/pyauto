#!/usr/bin/ksh
#================================================================
# Common Functions used by uc4scripts
# import this this file with . ${RUNDIR}/functions.ksh
#================================================================

#================================================================
# VARIABLES
#================================================================
prog="$(basename ${0})"
RUNDIR="$( cd "$(dirname "${0}")" && pwd )"
if ! [ -d /var/redis ] ;then
    mkdir -p /var/redis/logs
fi
LOGDIR="/var/redis/logs"
LOG_FILE_DIR="/var/redis/logs"
# Set FUNCITONS_IMPORTED to do not import functions.ksh again
FUNCTIONS_IMPORTED=1
unset PYTHONHOME
unset PYTHONPATH

#================================================================
# GENERAL
#================================================================
redis_timestamp() {
    date +"%F %T %Z"
}

usage() {
	script_headsize=$(grep -sn "^# END_OF_HEADER" ${0} | head -1 | cut -f1 -d:)
	printf "Usage: \\n\\n"	
	head -${script_headsize:-99} ${0} | grep -e "^#%" | sed -e "s/^#%//g" -e "s/\${prog}/${prog}/g";
}

runas_root() {
    if [[ ! "root" == "$(id | cut -f 2 -d '(' | cut -f1 -d ')')" ]]; then
        "$(${RUNDIR})" ${RUNDIR}/${prog} "${@}"
        exit
    fi
}

exec_counter() {
    date +"%F %T %Z ${ORACLE_SID:-}" >> ${LOGDIR}/${prog}.stat
}

#================================================================
# MOUNT Share
#================================================================
mount_share() {
    MNT_FOLDER="/workdata"

    if [ ! -d ${MNT_FOLDER} ]; then
        mkdir -p ${MNT_FOLDER}
    fi
    if [ -d ${MNT_FOLDER} ]; then
        if mount|grep -q " ${MNT_FOLDER}";then
          log_info "Something is already mounted on ${MNT_FOLDER}"
          return 1
        elif ! ${RUNDIR}/run_timeout 30 "mount -o vers=4 ${MNT_EXPORT} ${MNT_FOLDER}" > /dev/null 2>&1; then
          log_error "No mount of ${MNT_EXPORT} possible"
          /usr/bin/sendmail.py -t ${AUTOMAIL} -s "${prog}: No mount of ${MNT_EXPORT} possible"
          return 8
        else
          log_info "${MNT_EXPORT} mounted on ${MNT_FOLDER}"
        fi
    fi
}
umount_share() { # $1->mount_export_name
    if [[ "${1}" == "" ]]; then
        MNT_FOLDER="/workdata"
    else
        MNT_FOLDER="${1}"
    fi
    mount | grep -q "${MNT_FOLDER}"
    if [ $? -eq '0' ]; then
        umount ${MNT_FOLDER}
    fi
}
check_software_share() {
    if [[ ! -f /software/AIX/PROD_VERSION.TXT ]]; then
        if ! ${RUNDIR}/run_timeout 30 "mount /workdata" > /dev/null 2>&1; then
            /usr/bin/sendmail.py -t ${AUTOMAIL} -s "${prog}: No /software share available!"
            return 1
        else
            log_info "Mounted /workdata"
        fi
    fi

    # Everything fine
    return 0
}
#================================================================
# UTILITIES
#================================================================
is_reachable() { # $1->host
    if [[ -f /usr/bin/ncat ]]; then
#         /usr/bin/netcat -z -w 1 "${1}" 22 > /dev/null 2>&1
         /usr/bin/ncat -z -w 1 "${1}" 22 > /dev/null 2>&1
    else
        ${RUNDIR}/check_port.py "${1}" 22  > /dev/null 2>&1
    fi
    return ${?}
}

get_ip() { # $1->host
    # dig ${1} +search | awk '/^;; ANSWER SECTION:$/ { getline ; print $5 ; exit }'
    nslookup ${1} | awk '/^Address: / { print $2 }'
}

create_dir() { # $1->path $2->user [$3->group] [$4->mode]
    if [[ -f "${1}" ]]; then
        # Delete if path is file
        rm -f "${1}"
    fi
    if [[ ! -d "${1}" ]]; then
        # Create folder
        mkdir "${1}"
    fi
    if [[ -n "${2}" ]]; then
        # set owner
        chown "${2}" "${1}"
    fi
    if [[ -n "${3}" ]]; then
        # set group
        chgrp "${3}" "${1}"
    fi
    if [[ -n "${4}" ]]; then
        # set mode
        chmod "${4}" "${1}"
    fi
}

check_file() {  # $1 ->file name
    if [ -f $1 ];then
        log_info "  $1  is exist and will be delete"
        rm -rf $1
        log_info "  $1  is delete"
    fi
}

check_ssh() { # ${1}->ssh_cmd ${2}->host ${3}->user
  result=$($DIRECT_RSH -o StrictHostKeyChecking=no ${1} "env" 2>/dev/null 0</dev/null)
  if echo "${result}" | grep SHELL >/dev/null; then
    if [[ -n ${3} ]]; then
      log_info "ssh to ${2} (with user ${3}) possible" 1>&2
    else
      log_info "ssh to ${2} possible" 1>&2
    fi
    echo ${1}

    # Check Host Keys
    if echo "$result" | grep -q "host key"; then
      log_debug "host key cleanup required"
      IP=$(get_ip ${2})

      # Cleanup of current user
      ssh-keygen -R ${2} >/dev/null 2>&1
      ssh-keygen -R ${IP} >/dev/null 2>&1
      # Cleanup of SSH USER
      if [[ -n "${3}" ]]; then
        ssh-keygen -R ${2} -f /home/${3}/.ssh/known_hosts >/dev/null 2>&1
        ssh-keygen -R ${IP} -f /home/${3}/.ssh/known_hosts >/dev/null 2>&1
      fi

      # Add Key again
      $DIRECT_RSH_Q -o StrictHostKeyChecking=no ${1} "env" >/dev/null 2>&1 0</dev/null
    fi

    # CUST EXPORT
    if [[ -n "$EXPORT_CUST" ]]; then
      echo "${result}" | grep CUSTOMER | cut -f2 -d'=' | tr "[:lower:]" "[:upper:]" >${EXPORT_CUST}
    fi

    return 0
  else
    log_debug "no ssh to ${2} possible (ssh args: ${1})" 1>&2
    return 8
  fi
}

#option force delete does not bypass protectedlist
remove_recursive_dir() { # $1->path [$2 -force]
    if [[ ${2} != "force" ]]; then
        forcedelete=n
    else
        forcedelete=y
    fi
    #exists?
    if [[ ! -d "${1}" ]]; then
        # doesn't exist
        log_warning "${1} does not exist"
        return 4
    fi
    #is not in protected list
    if grep -Fxq "${1}" ${RUNDIR}/protected_dir_list ; then
        # is in list
        log_warning "${1} is in protected list - skipping"
        return 4
    fi
    #is empty?
    size="$(du -sm ${1} | awk '{print $1}')"
    if [[ "${size}" != "0.00" && "$forcedelete" != "y" ]]; then
        log_info "${1} size not 0 but ${size} and force not selected - skipping"
        return 4
    fi
    log_info "removing ${1}"
    rm -rf "${1}"
}

###############################################################################
# Ask question that should be answered with y/n. Return value is dependend on
# answer:
#   y -> 0
#   n -> 1
#   other -> 8
#
# Globals:
#   
# Arguments:
#   question
#   auto
#   logfile
#
###############################################################################
ask_yn() {
    answer=n
    if [[ -z ${2} || "${2}" != "y" ]]; then
        log_info "${1} (y/n)?"
        read -r answer 
        if [[ -n ${3} ]]; then
            print "\n${1} (y/n) : $answer" >>${3}
        fi
    else
      answer=y
    fi

    case "${answer}" in
        y|Y|yes|Yes)
            return 0
            ;;
        n|N|no|No)
            return 1
            ;;
        *)
            return 8
            ;;
    esac
}


###############################################################################
# Ask question that should be answered with y/n/a. Return value is dependend on
# answer:
#   y -> 0
#   n -> 1
#   a -> 0
#   c -> exit
#   other -> 8
# If a is entered the variable auto will be set to y
#
# Globals:
#   
# Arguments:
#   question
#   logfile
#
###############################################################################
ask_ynac() {
    answer=n
    if [[ "${auto}" != "y" ]]; then
        log_info "${1} [(y)es/(n)o/(a)uto/(c)ancel]?"
        read -r answer 
        if [[ -n ${2} ]]; then
            print "\n${1} (y/n) : $answer" >>${2}
        fi
    else
      answer=y
    fi

    case "${answer}" in
        y|Y|yes|Yes)
            return 0
            ;;
        a|A|auto|Auto)
            auto="y"
            return 0
            ;;
        n|N|no|No)
            return 1
            ;;
        c|C|cancel|Cancel)
            log_error "Cancel execution of script"
            do_exit 8
            exit 8
            ;;
        *)
            return 8
            ;;
    esac
}

#================================================================
# LOGGING
#================================================================
log() { # $1->level $2->message
    printf "[%s] [%-12.20s] [%-5.5s] %s\\n" "$(redis_timestamp)" "${prog}" "${1}" "${2}"
}
log_debug() {
    if [[ "${LOGLEVEL}" == "DEBUG" ]]; then
        log "DEBUG" "$@"
    fi
}
log_info() {
    log "INFO" "$@"
}
log_warning() {
    log "WARN" "$@"
}
log_error() {
    log "ERROR" "$@"
}
log_trace() {
    log "TRACE" "$@"
}
logrename ()
{
filecreatedate=`date +%Y%m%d%H%M%S`
 if [ -f $1 ] ;then
   mv $1 $1${filecreatedate}
   log_info "  $1 move to $1${filecreatedate} "
 else
   log_error " $1 not exist "
   exit 16
 fi
}
#================================================================
# packages
#================================================================
isInstalled() {
    if rpm -q $1 &> /dev/null; then
        log_info   "$1 is installed "
        return 1
    else
        log_info   "$1 is not installed"
        return 0
    fi
}
mywget() {
  while true
    do
       sleep 5
       wget $1
       if [ $? -eq 0 ]; then
         log_info "download $1 successfully."
          break;
       fi
    done
}

#================================================================
# parall run
#================================================================
parall() {
#2. 遍历集群所有机器
tmpfile=$$.fifo   # 创建管道名称
mkfifo /tmp/$tmpfile   # 创建管道
exec 6<>/tmp/$tmpfile  # 创建文件标示4，以读写方式操作管道$tmpfile
rm /tmp/$tmpfile       # 将创建的管道文件清除
thred=${#NODE_NAMES[@]}
	
# 为并发线程创建相应个数的占位
for (( i = 1;i<=${thred};i++ ));do echo;done >&6 # 将占位信息写入管道

Count=0
for host in `seq 0 ${#NODE_NAMES[@]}`
    do
        if test -z ${NODE_NAMES[$host]} ; then
            break
        else
            read -u6
            let Count+=1
            {
                log_info "  Parallel execute $Count"
                log_info "Exectue $1 in server ${NODE_NAMES[$host]}  "
                ssh  ${NODE_NAMES[$host]} "sh $1"
                echo >&6
            } &
        fi
    done 
    wait
    exec 6>&-   # 关闭管道
} 