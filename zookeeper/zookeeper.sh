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

#=============================================================================
#  Main
#=============================================================================
ZOO_CFG=/usr/local/apache-zookeeper/conf/zoo.cfg
ZOO_INS=/usr/local/apache-zookeeper
rc=0
rc=$(id zookeeper)
if [ $? -eq 1 ] ; then
  groupadd zookeeper -g 2000
  useradd zookeeper -u 2000 -d /usr/local/apache-zookeeper -g zookeeper -s /sbin/nologin
  chown -R zookeeper:zookeeper ${ZOO_INS}
fi


cat <<EOF >/usr/lib/systemd/system/zookeeper.service
[Unit]
Description=Zookeeper.service
After=network.target

[Service]
#User=zookeeper
#Group=zookeeper
Type=forking
EnvironmentFile=JAVA_HOME=/usr/local/jdk
ExecStart=/usr/local/apache-zookeeper/bin/zkServer.sh start ${ZOO_CFG}
ExecStop=/usr/local/apache-zookeeper/bin/zkServer.sh stop
ExecReload=/usr/local/apache-zookeeper/bin/zkServer.sh restart ${ZOO_CFG}
PIDFile=/usr/local/apache-zookeeper/data/zookeeper_server.pid
KillMode=none
Restart=on-failure
RestartSec=5
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
EOF

systemctl daemon-reload;systemctl start zookeeper;systemctl enable zookeeper;systemctl status zookeeper
if [ $? -eq 0 ]; then
  echo  "  Zookeeper is running successfully!"
else
  echo "  start Zlanneld,pls check in log file /var/log/message"
  echo "  tail -f /var/log/message"
fi
} 2>&1 | tee -a $LogFile

log_info  "  OK: EndofScript ${scriptname} " | tee -a $LogFile
logrename   ${LogFile}
log_info  "  Save log in   ${LogFile}"       | tee -a $LogFile
exit 0
