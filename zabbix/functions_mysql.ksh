#!/usr/bin/ksh
#================================================================
# Common Functions used by uc4scripts
# import this this file with . ${RUNDIR}/functions.ksh
#================================================================

#================================================================
# VARIABLES
#================================================================
prog="$(basename ${0})"
RUNDIR="$(cd "$(dirname "${0}")" && pwd)"

if [ -z "${SETVAR_IMPORTED}" ]; then
    . ${RUNDIR}/setvar.ksh
fi

check_port()
{
    log_info  "prepare 0: Check which port is available for use"
    checkport=$(ss -antlp|grep -i $port|wc -l)

    if [ $checkport -ge 1 ]; then
        log_warnings "The port $port is already used"
        log_info " Increate port by 1 and check again"
        let port=${port}+1
        export port=${port}
        check_port
    else 
        log_info "This port $port can be use..."
        let mysqlPort=$port
        let mysqlx_port=$port*10
        export mysqlx_port=${mysqlx_port}
        log_info "This mysql port will take $mysqlPort ...."
        log_info "This mysqlx_port will take $mysqlx_port.. "
        log_info "parepare 1: Check port done.............."
    fi
}

sqlexe() {
    mysql --login-path=root -e "$1;" >>/tmp/mysql_result
    if [ $? -eq 0 ];then
            log_info "$1 exectue successfully ok"
    else
            log_error "$1 runnning failed"
            do_exit 8
    fi
}

version_select()
{
log_info "you can select following version:" 
echo -e "===============================================================================================\n"  
echo -e "\e[1;32m 8.0.11 8.0.12 8.0.13 8.0.14 8.0.15 8.0.16 8.0.17 8.0.18 8.0.19 8.0.20 8.0.21 8.0.22 \e[0m" 
#echo -e "\e[1;32m 5.7.9 5.7.10 5.7.11 5.7.12 5.7.13  5.7.14 5.7.15 5.7.16 5.7.17 5.7.18 5.7.19 5.7.20 \e[0m" 
#echo -e "\e[1;32m 5.7.21 5.7.22 5.7.23 5.7.24 5.7.25  5.7.26 5.7.27 5.7.28 5.7.29 5.7.30 5.7.31       \e[0m" 
echo -e "===============================================================================================\n"
log_info "please input verson like 8.0.18 "
read -p "Which version do you want to insatll:  " VERISON
log_info "you are going to download mysql-${VERISON}-el7-x86_64.tar.gz"
}

createmysqlenv() 
{
if [ $( cat /etc/security/limits.conf  | grep "mysql" | wc -l )  -lt 1 ] ;then
cat >>/etc/security/limits.conf << EOF
* soft nproc 65536
* hard nproc 65536
* soft nofile 65536
* hard nofile 65536
mysql soft nproc 65536
mysql hard nproc 65536
mysql soft nofile 65536
mysql hard nofile 65536
EOF
fi

if [ -e /etc/security/limits.d/20-nproc.conf ]; then
    if [ $( cat /etc/security/limits.d/20-nproc.conf  | grep "mysql" | wc -l )  -lt 1 ] ;then
cat >>/etc/security/limits.d/20-nproc.conf<<EOF
mysql       soft    nproc     unlimited
EOF
    fi
fi

if [ -e /etc/security/limits.d/90-nproc.conf ]; then
    if [ $( cat /etc/security/limits.d/90-nproc.conf  | grep "mysql" | wc -l )  -lt 1 ]; then
cat >>/etc/security/limits.d/90-nproc.conf<<EOF
mysql       soft    nproc     unlimited
EOF
    fi
fi

if [ -e /etc/sysctl.conf ];then
    fs_file=$( cat /proc/sys/fs/file-max)
    if [ ${fs_file} -lt 65535 ] ;then
        sed -i "s/${fs_file}/65535/g" /etc/sysctl.conf
        /usr/sbin/sysctl -p 
    fi
fi

if [ ! $(id -u "mysql") ]; then
    echo "mysql user is not exists for to created"
    /usr/sbin/groupadd mysql
    /usr/sbin/useradd -g mysql -r -s /sbin/nologin -M mysql
fi
chown -R mysql:mysql /usr/local/mysql
log_info "step 2:  configure mysql runing enviroment done."
}

Generatet_Mysql_cnf() {
if  [ -f ${mysqlcnf} ] ;then
    #mv  ${mysqlcnf}  ${mysqlcnf}"`date +%Y%m%d%H%M`"
    rm -rf ${mysqlcnf}
fi
check_mysql_bin
cat >${mysqlcnf}<<EOF
[mysqld_safe]
user = mysql
nice = 0
[client]                           
socket                             = ${mysql_pid_dir}/mysql.sock
port                               = ${port}

[mysqld]
############# GENERAL #############
skip_ssl
skip-name-resolve
autocommit                         =ON
character_set_server               =utf8mb4
collation_server                   =utf8mb4_bin
explicit_defaults_for_timestamp    =ON
lower_case_table_names             =1
port                               =${port}
read_only                          =OFF
transaction_isolation              =READ-COMMITTED
open_files_limit                   =65535
max_connections        = 2000
#expire_logs_days                  =10
binlog_expire_logs_seconds         =51840000
default-time_zone                  ='+8:00'
socket                             = ${mysql_pid_dir}/mysql.sock
# hostname                           = "$(hostname)"
####### CACHES AND LIMITS #########
interactive_timeout                =600 
lock_wait_timeout                  =300
max_connect_errors                 =1000000

table_definition_cache             =2000
table_open_cache                   =2000 
table_open_cache_instances         =8

thread_cache_size                  =32
thread_stack                       =256K

tmp_table_size                     =32M
max_heap_table_size                =64M

#query_cache_size                  =0
#query_cache_type                  =0

sort_buffer_size                   =10M
max_length_for_sort_data           =4096   
join_buffer_size                   =10M
read_rnd_buffer_size               =2M

innodb_io_capacity                 =1000 
innodb_io_capacity_max             =2000

max_allowed_packet                 =1024M
slave_max_allowed_packet           =1024M
slave_pending_jobs_size_max        =1024M


############# SAFETY ##############
local_infile                       =OFF
skip_name_resolve                  =ON
sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION,ANSI_QUOTES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO'
############# LOGGING #############
general_log                        =0
log_queries_not_using_indexes      =ON
log_slow_admin_statements          =ON
#log_warnings                      =2
long_query_time                    =1  #1????
slow_query_log                     =ON

############# REPLICATION #############

server_id                          =${port}  #ip+3???
binlog_checksum                    =CRC32
binlog_format                      =ROW
binlog_rows_query_log_events       =ON

enforce_gtid_consistency           =ON
gtid_mode                          =ON
log_slave_updates                  =ON

master_info_repository             =TABLE
master_verify_checksum             =ON

max_binlog_size                    =512M
max_binlog_cache_size              =1024M   #???,??1024
binlog_cache_size                  =8M

relay_log_info_repository          =TABLE
skip_slave_start                   =ON
slave_net_timeout                  =10
slave_sql_verify_checksum          =ON
auto_increment_increment		   =2
auto_increment_offset              =1
sync_binlog                        =1
sync_master_info                   =1
sync_relay_log                     =1
sync_relay_log_info                =1
report_host                        =$(hostname)
############### PATH ##############
basedir                            =/usr/local/mysql

datadir                            =${mysql_data_dir}
tmpdir                             = ${mysql_tmp_dir}
socket                             = ${mysql_pid_dir}/mysql.sock
pid_file                           = ${mysql_pid_dir}/mysql.pid
innodb_data_home_dir               = ${mysql_data_dir}

mysqlx_socket                      = ${mysql_pid_dir}/mysqlx.sock
mysqlx_port                        = $mysqlx_port

log_error                          = ${mysql_log_dir}/error.log
general_log_file                   = ${mysql_log_dir}/general.log
slow_query_log_file                = ${mysql_log_dir}/slow.log

log_bin                            = ${mysql_binlog_dir}/mysql-bin
log_bin_index                      = ${mysql_binlog_dir}/mysql-bin.index
relay_log                          = ${mysql_binlog_dir}/relay-log
relay_log_index                    = ${mysql_binlog_dir}/relay-log.index

# undo settings
innodb_undo_directory              = ${mysql_undo_dir}
innodb_undo_log_truncate           = 1 
innodb_max_undo_log_size           = 16M
#innodb_undo_tablespaces            = 2

############# INNODB #############
#innodb_file_format                 = barracuda
innodb_flush_method                = O_DIRECT

innodb_buffer_pool_size            = 512M
innodb_buffer_pool_instances       = 4 
innodb_thread_concurrency          = 0

innodb_log_file_size               = 128M
innodb_log_files_in_group          = 2
innodb_flush_log_at_trx_commit     = 1
#innodb_support_xa                  = ON
innodb_strict_mode                 = ON

innodb_data_file_path              = ibdata1:32M;ibdata2:16M:autoextend
innodb_temp_data_file_path         = ibtmp1:1G:autoextend:max:30G
innodb_checksum_algorithm          = strict_crc32
innodb_lock_wait_timeout           = 600

innodb_log_buffer_size             = 8M
innodb_open_files                  = 65535

innodb_page_cleaners               = 1
innodb_lru_scan_depth              = 256
innodb_purge_threads               = 4
innodb_read_io_threads             = 4
innodb_write_io_threads            = 4 

innodb_print_all_deadlocks         = 1

[mysql]
############# CLIENT #############                            
max_allowed_packet                 = 16M
socket                             = ${mysql_pid_dir}/mysql.sock
no-auto-rehash
#mysqlx_socket                      = ${mysql_pid_dir}/mysqlx.sock
#mysqlx_port                        = $mysqlx_port
prompt = (\u@\h) [\d]>\_

[mysqldump]                        
max_allowed_packet                 = 16M
EOF
touch ${mysql_log_dir}/error.log
touch ${mysql_log_dir}/general.log
touch ${mysql_log_dir}/slow.log
chown -R mysql:mysql ${mysqlcnf}
chown -R mysql:mysql ${data_default}
chmod 700 ${mysql_tmp_dir}
log_info "mysql configure file ${data_default}/my.cnf is generated"
}

check_mysql_bin(){
    if which mysql >/dev/null; then
        log_info "mysql env already setup "
    else
        createmysqlenv
        ask_ynac
        if [ $? -eq 0 ];then 
            version_select
        else 
            VERISON="8.0.18"
        fi
        log_info ">>>start setup mysql env......"
        if [ -e ${DOWNLOADDIR}mysql-${VERISON}-el7-x86_64.tar.gz  ];then
            log_info "${DOWNLOADDIR}mysql-${VERISON}-el7-x86_64.tar.gz alreay exist"
        else 
            mywget https://cdn.mysql.com/archives/mysql-8.0/mysql-${VERISON}-el7-x86_64.tar.gz mysql-${VERISON}-el7-x86_64.tar.gz
        fi

        if  [ ! -d ${installPath}/mysql-${VERISON}-el7-x86_64 ] ;then
            log_info "Start extract mysql-${VERISON}-el7-x86_64.tar.gz"
            tar -zxvf ${DOWNLOADDIR}mysql-${VERISON}-el7-x86_64.tar.gz -C /usr/local/ &> /dev/null
            log_info "extract mysql-${VERISON}-el7-x86_64.tar.gz is exectract to /usr/local/${VERISON}-el7-x86_64"
            if [ -d /usr/local/mysql ]; then
                rm -rf /usr/local/mysql
            fi
            mv /usr/local/mysql-${VERISON}-el7-x86_64 /usr/local/mysql
            echo "PATH=\$PATH:/usr/local/mysql/bin" >> ~/.bash_profile
            source ~/.bash_profile
            log_info "<<<mysql env setup done."
        fi
    fi

    ln -sf /usr/lib64/libncurses.so.6.1 /usr/lib64/libncurses.so.5
    ln -sf /usr/lib64/libtinfo.so.6.1 /usr/lib64/libtinfo.so.5
    echo /usr/local/mysql/lib             >>/etc/ld.so.conf
    echo /usr/local/mysql/lib/mysqlrouter >>/etc/ld.so.conf
    ldconfig
    myinstall expect
    # yum install libaio
    check_file /etc/profile.d/mysql.sh
    echo "PATH=$PATH:${basedir}/bin" >> /etc/profile.d/mysql.sh
    chmod +x /etc/profile.d/mysql.sh
}
