#/bin/bin/ksh
# HEADER
#================================================================
#% SYNOPSIS
#%    ${prog}
#%
#% DESCRIPTION
#%    setup kubernetes kubelet services
#%
#% ARGUMENTS
#%     use hostname as default
#%
#% EXAMPLES
#%    ${prog}
#%
#================================================================
#  HISTORY
#     20220104  innod motingxia@163.com
#================================================================
#  NOTES
#================================================================
# END_OF_HEADER
#================================================================

#================================================================
#  IMPORT COMMON FUNCTIONS AND VARIABLES
#================================================================
RUNDIR="$(cd "$(dirname "${0}")" && pwd)"
if [ -z "${FUNCTIONS_IMPORTED}" ]; then
  . ${RUNDIR}/functions.ksh
fi

#================================================================
#  FUNCTIONS
#================================================================
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
echo ${LogFile}

source ~/.bash_profile


version_select()
{
log_info "you can select following version:\n" 
log_info "please input verson like 5.0.6\n\n"
log_info "===============================================================================================\n"
echo -e "\e[1;32m 4.0.0 4.0.1 4.0.2 4.0.3 4.0.4 4.0.5 4.0.6 4.0.7 4.0.8 4.0.9 4.0.10 4.0.11 4.0.12 4.0.13 4.0.14 \e[0m"
echo -e "\e[1;32m 5.0.0 5.0.1 5.0.2 5.0.3 5.0.4 5.0.5 5.0.6 5.0.7 5.0.8 5.0.9 5.0.10 \e[0m"
echo -e "\e[1;32m 6.0.0 6.0.1 6.0.2 6.0.3 6.0.4 6.0.5 6.0.6 6.0.7 6.0.8 6.0.9 6.0.10 \e[0m"
log_info "===============================================================================================\n"
read -p "Which version do you want to insatll:  " VERISON
log_info "your are going to download redis-${VERISON}.tar.gz \n\n"
}

checkredis()
{
if [ `ps -ef|grep -i redis|grep -v grep|wc -l` -eq 1 ];then
   log_info "redis already installed"
   exit
fi

echo 
if ps -ef|grep -i redis|grep -v kubernetes|grep -v metrics|grep -v grep|grep -v inst_redis.sh; then
  echo 
  log_warning "  redis is running,stop it"
  if ! systemctl stop redis; then
    sleep 5
    pids=$(ps -ef|grep -i redis|grep -v kubernetes|grep -v metrics|grep -v grep|grep -v inst_redis.sh| awk '{printf("%s ",$2)}')
    log_warning "   Execute kill -9 ${pids} to stop redis"
    kill -9 ${pids} 2>/dev/null
  fi
fi
log_info "  redis is not running"
}

#创建用户
craete_user()
{
redisid=$(cat /etc/passwd|grep -i redis|wc -l)
if [ $redisid -eq 1 ];then
  log_info "user redis already exist"
else
  groupadd redis                  
  useradd -g redis redis          
  if [ $? -eq 0 ];then
  log_info "user redis is created"   
  fi
fi
}


#安装环境
prepqreenv()
{

##redis path
if ! [ -d ${REDISDIR} ] ; then
    rm -rf ${REDISDIR}
    mkdir -p ${REDISDIR}
    log_info " folder /data/redis is created" 
fi

#sysctl
if ! [ -e /etc/sysctl.d/98-redis.conf ]; then
cat >> /etc/sysctl.d/98-redis.conf <<EOF
net.core.somaxconn = 2048
vm.overcommit_memory = 1
EOF
sysctl -p                                 |tee -a  >> ${LOGFILE}
fi

#disable Transparent Huge Pages (THP) support 
thg=$(cat  /sys/kernel/mm/transparent_hugepage/enabled | grep -i enver |wc -l)
if [ ${thg} -ne 1 ] ; then
    echo never > /sys/kernel/mm/transparent_hugepage/enabled
    cat /sys/kernel/mm/transparent_hugepage/enabled|grep -i 'never' >>/etc/rc.local
fi
        
if ! [ $( cat /etc/security/limits.conf  | grep "redis" | wc -l )  -lt 1 ] ;then
cat >>/etc/security/limits.conf << EOF
redis   soft    nproc   65535
redis   hard    nproc   65535
redis   soft    nofile  65535
redis   hard    nofile  65535
EOF
fi
}

comp_redis()
{
  #解压安装包
mywget http://download.redis.io/releases/redis-${VERISON}.tar.gz  
echo ${VERISON}
tar -zxvf redis-${VERISON}.tar.gz -C ${INSTALLDIR}

#编译

log_info "  Start compile redis ${VERISON} "
cd ${INSTALLDIR}/redis-${VERISON} && make
if [ $? -eq 0 ];then
  echo
  log_info "    make done! "                                
else
  log_error "    make failed with $RC,pls check reasib! "
  do_exit 8
fi

cd ${INSTALLDIR}/redis-${VERISON}/src && make all && make test 

if [ $? -lt 4 ];then
  echo 
  log_info "    make test done! "
else
  echo
  log_error "    make test failed with ${RC},pls check reasib! " 
  do_exit 8
fi

make install PREFIX=${INSTALLDIR}/redis    
if [ $? -eq 0 ];then
  log_info "    make install done!\n "   
else
  log_error "   make install failed with $?,pls check reason! " 
  do_exit 8
fi

if ! [ -d ${INSTALLDIR}/redis/8000 ]
then
    mkdir -p  ${INSTALLDIR}/redis/8000/{data,tmp,logs}
fi

if ! [ -d ${INSTALLDIR}/redis/etc ]
then
    mkdir -p  ${INSTALLDIR}/redis/etc/
fi

}

config_start() {
#修改配置文件
check_file /data/redis/etc/redis.conf

cat >> ${INSTALLDIR}/redis/etc/redis.conf <<EOF
bind 0.0.0.0
port 8000
daemonize yes
supervised systemd 
pidfile "/data/redis/8000/tmp/redis-8000.pid"
logfile "/data/redis/8000/logs/redis-8000.log"
dir "/data/redis/8000/data"
requirepass "123456"
protected-mode yes
tcp-backlog 511
timeout 0
tcp-keepalive 300
loglevel notice
databases 16
always-show-logo yes
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
rdb-del-sync-files no
replica-serve-stale-data yes
replica-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-diskless-load disabled
repl-disable-tcp-nodelay no
replica-priority 100
acllog-max-len 128
requirepass foobared
lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
replica-lazy-flush no
lazyfree-lazy-user-del no
# oom-score-adj no
#oom-score-adj-values 0 200 800
appendonly no
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
stream-node-max-bytes 4096
stream-node-max-entries 100
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
dynamic-hz yes
aof-rewrite-incremental-fsync yes
rdb-save-incremental-fsync yes
jemalloc-bg-thread yes
EOF

REDISDIR=/data/redis
check_file /usr/bin/redis-server
check_file /usr/bin/redis-cli
cp -p ${REDISDIR}/bin/redis-server /usr/bin
cp -p ${REDISDIR}/bin/redis-cli /usr/bin

chown -R  redis:redis ${REDISDIR}
chmod -R  755 ${REDISDIR}

check_file /usr/lib/systemd/system/redis.service

log_info "   Generate redis start service file /usr/lib/systemd/system/redis.service "
cat  >> /usr/lib/systemd/system/redis.service << EOF
[Unit]
Description=Redis persistent key-value database
Documentation=https://redis.io/documentation
After=network.target

[Service]
#ExecStart=/usr/bin/redis-server /data/redis/etc/redis.conf --supervised systemd
ExecStart=/usr/bin/redis-server /data/redis/etc/redis.conf
ExecStop=/usr/bin/redis-cli shutdown
Type=forking
Restart=always
LimitNOFILE=10032
User=redis
Group=redis
RuntimeDirectory=redis
RuntimeDirectoryMode=0755
TimeoutSec=900

[Install]
WantedBy=multi-user.target
EOF
log_info "   Generate redis start service file /usr/lib/systemd/system/redis.service done"

log_info  "    Trying to start redis "
systemctl daemon-reload && systemctl enable redis && systemctl start redis

if ps -ef|grep -i redis|grep -v kubernetes|grep -v metrics|grep -v grep|grep -v inst_redis.sh;then 
    echo
    log_info "   redis is startup\n"   
else    
    log_error "    redis not startup"                  
    do_exit 8
fi
}

#================================================================
#  Main
#================================================================

LOGFILE=/var/log/redis.log
REDISSOURCE=/mnt/hgfs/Redis/
INSTALLDIR=/data
REDISDIR=/data/redis
VERISON=""
PORT=8000
RC=0


{
checkredis
version_select
craete_user
prepqreenv
comp_redis
config_start


# if [ -f /etc/profile.d/redis ] ; then
#     rm -rf /etc/profile.d/redis
#     echo "PATH=$PATH:${INSTALLDIR}/redis/bin" >> /etc/profile.d/redis
#     chmod +x /etc/profile.d/redis
#     source /etc/profile.d/redis
# fi

# ${INSTALLDIR}/redis/bin/redis-server /data/redis/etc/redis.conf &

} 2>&1 | tee -a $LogFile

if [ -f /tmp/RC.$$ ]; then
   RC=$(cat /tmp/RC.$$)
   rm -f /tmp/RC.$$
fi
if [ "$RC" == "0" ]; then
  log_info  "  OK: EndofScript ${scriptname} " | tee -a $LogFile
else
  log_error  "  ERROR: EndofScript ${scriptname} " | tee -a $LogFile
fi
ende=$(date +%s)
diff=$((ende - starttime))
log_info  "  $(date)   Runtime      :   $diff" | tee -a $LogFile
log_info  "  Save log to ${LogFile}             "  | tee -a $LogFile
logrename  ${LogFile}
exit ${RC}