#!/usr/bin/ksh
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
# wget https://cdn.mysql.com//Downloads/MySQL-8.0/mysql-8.0.22-el7-x86_64.tar.gz
# wget https://cdn.mysql.com//Downloads/MySQL-8.0/mysql-8.0.22.tar.gz
# wget https://cdn.mysql.com/archives/mysql-8.0/mysql-8.0.21-el7-x86_64.tar.gz
# wget https://cdn.mysql.com//Downloads/MySQL-8.0/mysql-8.0.21.tar.gz
# wget https://cdn.mysql.com/archives/mysql-8.0/mysql-8.0.20-el7-x86_64.tar.gz
# wget https://cdn.mysql.com/archives/mysql-8.0/mysql-8.0.20.tar.gz
# wget https://cdn.mysql.com/archives/mysql-8.0/mysql-8.0.19-el7-x86_64.tar.gz
# wget https://cdn.mysql.com/archives/mysql-8.0/mysql-8.0.19.tar.gz
# wget https://cdn.mysql.com/archives/mysql-8.0/mysql-8.0.18-el7-x86_64.tar.gz
# wget https://cdn.mysql.com/archives/mysql-8.0/mysql-8.0.14-el7-x86_64.tar.gz
# wget https://cdn.mysql.com/archives/mysql-8.0/mysql-8.0.11-el7-x86_64.tar.gz
# wget https://cdn.mysql.com/archives/mysql-8.0/mysql-8.0.11.tar.gz
# wget https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.31.tar.gz
# wget https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.30.tar.gz
# wget https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.26.tar.gz
# wget https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.22.tar.gz
# wget https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.20.tar.gz
# wget https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.10.tar.gz
# wget https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.9.tar.gz
# }

export installPath="/home"
if  [ ! -d ${installPath} ] ;then
    mkdir -p ${installPath}
    log_info "${installPath} is created"
fi

#mysql port
let port=3300+$(nslookup $(hostname)|grep -i Address|awk '{print $2}'|grep -v '#'|cut -d. -f4)
export  port=${port}
let mysqlx_port=$port*10
export mysqlServerid="${port}"
#mysql password
# defaultPassword=$(openssl rand -base64 12)

if  [ ! -d ${installPath}/${port} ] ;then
    mkdir -p "${installPath}/${port}/data"
    mkdir -p "${installPath}/${port}/binlog"
    mkdir -p "${installPath}/${port}/logs"
    mkdir -p "${installPath}/${port}/undo"
    mkdir -p "${installPath}/${port}/tmp"
    mkdir -p "${installPath}/${port}/pid"
fi

export data_default=${installPath}/${port}
export mysql_binlog_dir="${data_default}/binlog"
export mysql_data_dir="${data_default}/data"
export mysql_log_dir="${data_default}/logs"
export mysql_tmp_dir="${data_default}/tmp"
export mysql_pid_dir="${data_default}/pid"
export mysql_undo_dir="${data_default}/undo"
if ! [ -f ${data_default}/my.cnf ];then
    touch ${data_default}/my.cnf
fi 
export mysqlcnf="${data_default}/my.cnf"
export basedir="/usr/local/mysql"
export datadir="${data_default}/data"

# if  [ -d ${data_default} ] ;then
#     if [ $(du -s  ${data_default}  |  awk 'NR==1{print $1}') -gt 0 ] ;then
#         mv  ${data_default}  ${data_default}"`date +%Y%m%d%H%M`"
#     fi
# fi
