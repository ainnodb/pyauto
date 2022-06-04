#!/bin/bash
#=============================================================================
# HEADER
#=============================================================================
#% SYNOPSIS
#%    ${prog}
#%
#% DESCRIPTION
#%    Script to deploy Docker service
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


# rpm -e podman-1.0.0-2.git921f98f.module+el8+2785+ff8a053f.x86_64 --force
# rpm -e podman-1.0.0-2.git921f98f.module+el8+2785+ff8a053f.x86_64
# rpm -e buildah-1.5-3.gite94b4f9.module+el8+2769+577ad176.x86_64 --force
# rpm -e buildah-1.5-3.gite94b4f9.module+el8+2769+577ad176.x86_64
# rpm -e fuse-overlayfs --force
# rpm -e slirp4netns --force
# rpm -e pcp-testsuite-4.3.0-3.el8.x86_64 --force
# rpm -e pcp-pmda-docker-4.3.0-3.el8.x86_64 --force
# rpm -ivh /mnt/hgfs/kubernetes/package/Docker/package/first/fuse-overlayfs-0.7.8-1.module_el8.3.0+479+69e2ae26.x86_64.rpm
# rpm -ivh /mnt/hgfs/kubernetes/package/Docker/package/first/slirp4netns-0.4.2-3.git21fdece.module_el8.3.0+479+69e2ae26.x86_64.rpm
# rpm -Uvh /mnt/hgfs/kubernetes/package/Docker/package/second/*
# rpm -Uvh /mnt/hgfs/kubernetes/package/Docker/package/third/libseccomp-2.5.1-1.el8.x86_64.rpm
# rpm -ivh /mnt/hgfs/kubernetes/package/Docker/package/third/libseccomp-devel-2.5.1-1.el8.x86_64.rpm

# systemctl start docker && systemctl enable docker &&
{
systemctl stop docker

pids=$(ps -ef | grep -v grep | grep -i docker| awk '{printf("%s ",$2)}')
if [[ -n "${pids}" ]]; then
    log_info "  Docker is running!"
    systemctl stop docker
    if [ $? -eq 0 ];then
      log_info "  Docker is stopped!"
    fi
fi

if [ -d /var/lib/docker ];then
    rm -rf /var/lib/dockershim/*
    rm -rf /var/lib/docker/*
    rm -rf /var/lib/kubelet/*
    log_info "  /var/lib/{dockershim,docker,kubelet} are deleted"
fi

# cat <<EOF >/etc/docker/daemon.json
# {
#     "registry-mirrors": ["https://registry.docker-cn.com"],
#     "exec-opts": ["native.cgroupdriver=systemd"],
#     "insecure-registries": ["win200:5000"],
#     "log-driver": "json-file",
#     "log-opts": {"max-size": "100m"}
# }
# EOF

cat >/etc/docker/daemon.json <<EOF
{
    "registry-mirrors": [
      "https://registry.docker-cn.com",
      "https://docker.mirrors.ustc.edu.cn",
      "http://hub-mirror.c.163.com"
    ],
    "exec-opts": ["native.cgroupdriver=systemd"],
    "max-concurrent-downloads": 10,
    "insecure-registries": ["win200:5000"],
    "log-level": "warn",
    "log-opts": {
      "max-size": "10m",
      "max-file": "3"
    },
    "log-driver": "json-file",
    "data-root": "/var/lib/docker"
}
EOF

cat <<EOF >/usr/lib/systemd/system/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service containerd.service
Wants=network-online.target
Requires=docker.socket containerd.service

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
EnvironmentFile=/etc/kubernetes/flanneld/docker_opts.env
ExecStart=/usr/bin/dockerd \$DOCKER_OPTS -H fd:// --containerd=/run/containerd/containerd.sock
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
RestartSec=2
Restart=always

# Note that StartLimit* options were moved from "Service" to "Unit" in systemd 229.
# Both the old, and new location are accepted by systemd 229 and up, so using the old location
# to make them work for either version of systemd.
StartLimitBurst=3

# Note that StartLimitInterval was renamed to StartLimitIntervalSec in systemd 230.
# Both the old, and new name are accepted by systemd 230 and up, so using the old name to make
# this option work for either version of systemd.
StartLimitInterval=60s

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not support it.
# Only systemd 226 and above support this option.
TasksMax=infinity

# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes

# kill only the docker process, not all processes in the cgroup
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload;systemctl start docker
if [ $? -eq 0 ]; then
  log_info  "  Docker is running successfully! "
else
  log_error "  Start docker,pls check in log file /var/log/message"
  log_info  "  tail -f /var/log/message"
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