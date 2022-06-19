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
if [ -z "${FUNCTIONS_IMPORTED}" ]; then
    . ${RUNDIR}/functions.ksh
fi
if [ -z "${SETVAR_IMPORTED}" ]; then
    . ${RUNDIR}/setelkvar.ksh
fi

version_select()
{
log_info "you can select following version:" 
echo -e "===============================================================================================\n"  
echo -e "\e[1;32m 8.2.2 8.2.1 8.2.0 8.1.3 8.1.2 8.1.0 8.0.0\e[0m" 
#echo -e "\e[1;32m 5.7.9 5.7.10 5.7.11 5.7.12 5.7.13  5.7.14 5.7.15 5.7.16 5.7.17 5.7.18 5.7.19 5.7.20 \e[0m" 
#echo -e "\e[1;32m 5.7.21 5.7.22 5.7.23 5.7.24 5.7.25  5.7.26 5.7.27 5.7.28 5.7.29 5.7.30 5.7.31       \e[0m" 
echo -e "===============================================================================================\n"
log_info "please input verson like 8.0.18 "
read -p "Which version do you want to insatll:  " VERISON
log_info "you are going to download elsaticsearch-${VERISON}-el7-x86_64.tar.gz"
}

create_elk_env() 
{

if [ ! $(id -u "es") ]; then
    echo "es user is not exists for to created"
    /usr/sbin/groupadd es
    /usr/sbin/useradd -g es -r  -M es
fi
chown -R es:es /usr/local/elasticsearch "${elk_home}"

log_info "configure elasticsearch runing enviroment done."
}

generatet_elk_cnf() {
if  [ -f ${elkcnf} ] ;then
    #mv  ${mysqlcnf}  ${mysqlcnf}"`date +%Y%m%d%H%M`"
    rm -rf ${elkcnf}
fi
cat >${elkcnf}<<EOF
cluster.name: ${cluastername}
node.name: ${HOSTNAME} 
network.host: 0.0.0.0
http.port: 9200
path.data: ${elk_data}
path.logs: ${elk_log}
node.data: true
node.master: true
path.repo: ${elk_repo}
cluster.initial_master_nodes: ["${HOSTNAME}"]
discovery.zen.ping.unicast.hosts: ["${elk_cluster[@]}"]
discovery.zen.minimum_master_nodes: 2 
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate 
xpack.security.transport.ssl.client_authentication: required
xpack.security.transport.ssl.keystore.path:   ${elk_conf}/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: ${elk_conf}/elastic-certificates.p12
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: ${elk_conf}/http.p12
xpack.security.http.ssl.truststore.path: ${elk_conf}/http.p12
xpack.security.http.ssl.client_authentication: optional
EOF
chown -R es:es ${elkcnf}
log_info "elasticsearch configure file ${elkcnf} is generated"
}


#      https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.1.0-linux-x86_64.tar.gz
#      https://artifacts.elastic.co/downloads/kibana/kibana-8.1.0-linux-x86_64.tar.gz
#      https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.1.0-linux-x86_64.tar.gz
#      https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.1.0-linux-x86_64.tar.gz
#      https://artifacts.elastic.co/downloads/beats/packetbeat/packetbeat-8.1.1-linux-x86_64.tar.gz

check_bin(){
    . ~/.bash_profile
    if which ${appname} 1>/dev/null; then
        log_info "${appname} env already setup "
    else
        ask_yn
        if [ $? -eq 0 ];then 
            version_select
        else 
            VERISON="8.2.2"
            log_warning "default version  ${appname}-${VERISON}-linux-x86_64.tar.gz is select "
        fi
        log_info ">>>start setup ${appname} env......"
        if [ -e ${DOWNLOADDIR}mysql-${VERISON}-el7-x86_64.tar.gz  ];then
            log_info "${DOWNLOADDIR}${appname}-${VERISON}-el7-x86_64.tar.gz alreay exist"
        else 
            mywget https://artifacts.elastic.co/downloads/elasticsearch/${appname}-${VERISON}-linux-x86_64.tar.gz ${appname}-${VERISON}-linux-x86_64.tar.gz

        fi

        if  [ ! -d ${installPath}/${appname}-${VERISON}-linux-x86_64.tar.gz ] ;then

            log_info "Start extract ${appname}-${VERISON}-linux-x86_64.tar.gz"
            check_dir /home/${appname}*
            tar -zxvf ${DOWNLOADDIR}${appname}-${VERISON}-linux-x86_64.tar.gz -C /home/ 1> /dev/null
            log_info "${appname}-${VERISON}-linux-x86_64.tar.gz is exectract to /home/${appname}-${VERISON}-el7-x86_64"
            mv ${installPath}/${appname}*  ${installPath}/${appname}
            chown -R es:es  ${installPath}/${appname}
            echo "export JAVA_HOME=${installPath}/${appname}/jdk/" >> ~/.bash_profile
            echo "export ES_JAVA_HOME=${installPath}/${appname}/jdk" >> ~/.bash_profile
            echo "export PATH=\$PATH:\$ES_JAVA_HOME:\$ES_JAVA_HOME/bin:${installPath}/${appname}/bin:\$JAVA_HOME/bin" >> ~/.bash_profile

            echo "export JAVA_HOME=${installPath}/${appname}/jdk" >> /home/es/.bash_profile
            echo "export ES_JAVA_HOME=${installPath}/${appname}/jdk" >> /home/es/.bash_profile
            echo "export PATH=\$PATH:\$ES_JAVA_HOME:\$ES_JAVA_HOME/bin:${installPath}/${appname}/bin:\$JAVA_HOME/bin" >> /home/es/.bash_profile

            source ~/.bash_profile
            log_info "<<<${appname} env setup done."
        fi
    fi
}