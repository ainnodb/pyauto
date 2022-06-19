#!/usr/bin/sh
#=============================================================================
# HEADER
#=============================================================================
#% SYNOPSIS
#%    ${prog}
#%
#% DESCRIPTION
#%    Script to deploy mysql 
#%
#% ARGUMENTS
#%    NONE
#%
#% EXAMPLES
#%    ${prog}
#%
#=============================================================================
#  HISTORY
#     20220529  innod motingxia@163.com
#=============================================================================
#  NOTES
#=============================================================================
# END_OF_HEADER
#=============================================================================

#=============================================================================
#  IMPORT COMMON FUNCTIONS AND VARIABLES
#=============================================================================
# RUNDIR="$(cd "$(dirname "${0}")" && pwd)"

# download(){
# wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.2.2-linux-x86_64.tar.gz
# wget https://artifacts.elastic.co/downloads/kibana/kibana-8.2.2-linux-x86_64.tar.gz
# wget https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.2.2-linux-x86_64.tar.gz
# wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.2.2-linux-x86_64.tar.gz
# wget https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-8.2.2-linux-x86_64.tar.gz
# wget https://artifacts.elastic.co/downloads/beats/auditbeat/auditbeat-8.2.2-linux-x86_64.tar.gz
# }

export installPath="/home"
export appname="elasticsearch"
export cluastername="datastudio"
export DOWNLOADDIR="/data/packages/"
if  [ ! -d ${installPath} ] ;then
    mkdir -p ${installPath}
    log_info "${installPath} is created"
fi

# defaultPassword=$(openssl rand -base64 12)

if  [ ! -d ${installPath}/${appname} ] ;then
    mkdir -p ${installPath}/${appname}/repo
fi

export elk_home="${installPath}/${appname}"
export elk_data="${elk_home}/data"
export elk_log="${elk_home}/logs"
export elk_repo="${elk_home}/repo"
export elk_conf="${elk_home}/config"
export elk_bin="${installPath}/${appname}/bin"
export JAVA_HOME=${elk_home}/jdk
export ES_JAVA_HOME=${elk_home}/jdk


if ! [ -f ${elk_conf}/elasticsearch.yml ];then
    touch ${elk_conf}/elasticsearch.yml
fi 
export elkcnf="${elk_conf}/elasticsearch.yml"
export elk_cluster=("win88.inno.com" "win89.inno.com" "win90.inno.com")

