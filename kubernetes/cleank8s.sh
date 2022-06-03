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
if [ $# -gt 0 ]; then
  usage
  exit 8
fi
i=1
scriptname=$(basename $0)
if ! [ -f ${LOG_FILE_DIR}/${scriptname}.log  ];then
  touch ${LOG_FILE_DIR}/${scriptname}.log
  LogFile=${LOG_FILE_DIR}/${scriptname}.log
else
  rm -rf ${LOG_FILE_DIR}/${scriptname}.log
  touch ${LOG_FILE_DIR}/${scriptname}.log
  LogFile=${LOG_FILE_DIR}/${scriptname}.log
fi
export LogFile=${LOG_FILE_DIR}/${scriptname}.log
echo ${LogFile}

source ~/.bash_profile

systemctl stop kube-apiserver.service kube-scheduler.service kube-controller-manager.service
systemctl stop kube-proxy.service kubelet.service etcd.service flanneld.service
systemctl stop docker.service
systemctl disable etcd kubelet kube-proxy kube-apiserver kube-contorl-manager kube-scheduler flanneld
{
rm -rf /etc/etcd 
rm -rf /etc/kubernetes
rm -rf /usr/local/etcd
rm -rf /usr/local/go
rm -rf /usr/sbin/{flanneld,mk-docker-opts.sh,kubelet,kube-proxy}
rm -rf /usr/sbin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl}
rm -rf /usr/sbin/{cfssljson,cfssl-certinfo,cfssl}
rm -rf /var/kubernetes/logs
rm -rf /usr/lib/systemd/system/{kube-apiserver.service,kube-controller-manager.service,kube-scheduler.service,kube-proxy.service,kubelet.service}
rm -rf ${RUNDIR}/{go1.16.10.linux-amd64.tar.gz,v3.5.0.zip,kubernetes-server-linux-amd64.tar.gz,cfssljson_1.6.1_linux_amd64,cfssl-certinfo_1.6.1_linux_amd64,cfssl_1.6.1_linux_amd64,flannel-v0.15.1-linux-amd64.tar.gz,kubernetes,flanneld,mk-docker-opts.sh,README.md}
rm -rf ${DOWNLOADDIR}/{go1.16.10.linux-amd64.tar.gz,v3.5.0.zip,kubernetes-server-linux-amd64.tar.gz,cfssljson_1.6.1_linux_amd64,cfssl-certinfo_1.6.1_linux_amd64,cfssl_1.6.1_linux_amd64,flannel-v0.15.1-linux-amd64.tar.gz,kubernetes,flanneld,mk-docker-opts.sh,README.md}

} 2>&1 | tee -a $LogFile

log_info  "  OK: EndofScript ${scriptname} " | tee -a $LogFile
log_info  "  Save log in   ${LogFile}"       | tee -a $LogFile
exit 0