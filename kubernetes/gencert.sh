#!/usr/bin/ksh
#
#=============================================================================
# HEADER
#=============================================================================
#% SYNOPSIS
#%    ${prog}
#%
#% DESCRIPTION
#%    Script to generatea cerrification for
#%                        etcd
#%                        kube-apiserver kube-controller-manager kube-scheduler
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
source ~/.bash_profile

#=============================================================================
#  FUNCTIONS
#=============================================================================

prepareca()
{
cat >${JSON_DIR}/ca-config.json <<EOF
{
  "signing": {
      "default": {
      "expiry": "87600h"
      },
     "profiles": {
         "server": {
             "expiry": "87600h",
             "usages": [
                 "signing",
                 "key encipherment",
                 "server auth",
                 "client auth"
                 ]
	     },
         "client": {
	     "expiry": "87600h",
             "usages": [
                 "signing",
                 "key encipherment",
                 "server auth",
                 "client auth"
            ]
        },
         "peer": {
	    "expiry": "87600h",
            "usages": [
                "signing",
                "key encipherment",
                "server auth",
                "client auth"
            ]
      }
    }
  }
}
EOF

cat >${JSON_DIR}/ca-csr.json <<EOF
{
  "CN": "system:masters:etcd",  
  "hosts": [
  ],
  "key": {
      "algo": "ecdsa",
      "size": 256
  },
  "names": [
      {
          "C": "CN",  
          "ST": "Henan",
          "L": "nanyang",
          "O": "system:masters",
          "OU": "system"
    }
  ],
  "ca": {
	  "expiry": "87600h"
  }
}
EOF

}
#######################################################################################################################
######             Generate certification programmer                                                       ############
######             usage:     certtype: client|server|peer                                                 ############
######                        jsonfile: usefor generate certification                                      ############
######                        targetcert: location of generated certification                              ############
#######################################################################################################################
gencert()
{
  let i=i+1
  {
  certtype=$1
  jsonfile=$2
  targetcert=$3
  log_info  "                 [$i]                      "
  log_info  "=====  Start generate $1 certification $3 in ${SSL_DIR}    ====="
  # cfssl gencert -ca=${SS_DIR}/ca.pem -ca-key=${SS_DIR}/ca-key.pem -config=ca-config.json -profile=${certtype} ${jsonfile} |cfssljson -bare ${SS_DIR}/${targetcert}
  cfssl gencert -ca=${SSL_DIR}/ca.pem -ca-key=${SSL_DIR}/ca-key.pem -config=${JSON_DIR=}/ca-config.json -profile=${certtype} ${JSON_DIR}/${jsonfile} |cfssljson -bare ${SSL_DIR}/${targetcert}
  if [ $? -eq 0 ] ; then
      log_info "=====  Generate $1 certification $3  in ${SSL_DIR}/${targetcert}    ====="
  else
      log_error "ERROR!!!!!!!!"
      do_exit 8
  fi
  sleep 2
  echo -e "\n"
  } 2>&1 | tee -a $LogFile
}

#######################################################################################################################
## MAIN
#######################################################################################################################
do_exit() {
  RC=$1
  echo "$RC" >/tmp/RC.$$
  exit $RC
}

if [ $# -gt 0 ]; then
  usage
  exit 8
fi
i=1

RC=0
starttime=$(date +%s)
scriptname=$(basename $0)
if ! [ -f ${LOG_FILE_DIR}/${APPNAME}${scriptname}.log  ];then
  touch ${LOG_FILE_DIR}/${APPNAME}${scriptname}.log
  LogFile=${LOG_FILE_DIR}/${APPNAME}${scriptname}.log
else
  rm -rf ${LOG_FILE_DIR}/${APPNAME}${scriptname}.log
  touch ${LOG_FILE_DIR}/${APPNAME}${scriptname}.log
  LogFile=${LOG_FILE_DIR}/${APPNAME}${scriptname}.log
fi
LogFile=${LOG_FILE_DIR}/${APPNAME}${scriptname}.log
log_info  "    logfile: ${LogFile}"

{
prepareca

log_info  "================== $i =================" | tee -a ${LogFile}
log_info  "=====  Start generate  ca.pem and ca-key.pem certification in ${SSL_DIR}    ====="
# cfssl gencert -initca ca-csr.json | cfssljson -bare ${SS_DIR}/ca - 
cfssl gencert -initca ${JSON_DIR}/ca-csr.json | cfssljson -bare ${SSL_DIR}/ca -
if [ $? -eq 0 ] ; then
    log_info  "    ===== Generate  ca.pem and ca-key.pem certification done and put in ${SSL_DIR}   ====="
else
    log_error "    ERROR!!!!!!!!" | tee -a ${LogFile}
    do_exit 8
fi
sleep 2

sed -e "s:clusteradmin:peer:g" ${RUNDIR}/template-csr.json > ${JSON_DIR}/etcdpeer-csr.json
#cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer etcdpeer-csr.json |cfssljson -bare peer
gencert peer etcdpeer-csr.json peer

sed -e "s:clusteradmin:server:g" ${RUNDIR}/template-csr.json                       > ${JSON_DIR}/server-csr.json
#cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server server-csr.json |cfssljson -bare server
gencert server server-csr.json server

sed -e "s:temp:apiserver-etcd-client:g" ${RUNDIR}/temp-client-csr.json              > ${JSON_DIR}/apiserver-etcd-client-csr.json
#cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client apiserver-etcd-client-csr.json |cfssljson -bare apiserver-etcd-client
gencert client apiserver-etcd-client-csr.json apiserver-etcd-client

sed -e "s:temp:apiserver-kubelet-client:g" ${RUNDIR}/temp-client-csr.json            > ${JSON_DIR}/apiserver-kubelet-client-csr.json
#cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client apiserver-kubelet-client-csr.json |cfssljson -bare apiserver-kubelet-client
gencert client apiserver-kubelet-client-csr.json apiserver-kubelet-client

sed -e "s:temp:front-proxy-client:g" ${RUNDIR}/temp-client-csr.json                  > ${JSON_DIR}/front-proxy-client-csr.json
#cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client front-proxy-client-csr.json |cfssljson -bare front-proxy-client
gencert client front-proxy-client-csr.json front-proxy-client

sed -e "s:temp:client:g" ${RUNDIR}/temp-client-csr.json                              > ${JSON_DIR}/client-csr.json
#cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client-csr.json |cfssljson -bare client
gencert client client-csr.json client

sed -e "s:clusteradmin:system\:kube-apiserver:g" ${RUNDIR}/template-csr.json         > ${JSON_DIR}/kube-apiserver-csr.json
#cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server kube-apiserver-csr.json |cfssljson -bare kube-apiserver
gencert server kube-apiserver-csr.json kube-apiserver

sed -e "s:clusteradmin:system\:kube-controller-manager:g" ${RUNDIR}/template-csr.json > ${JSON_DIR}/kube-controller-manager-csr.json
#cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server kube-controller-manager-csr.json |cfssljson -bare kube-controller-manager
gencert server kube-controller-manager-csr.json kube-controller-manager

sed -e "s:clusteradmin:system\:kube-scheduler:g" ${RUNDIR}/template-csr.json          > ${JSON_DIR}/kube-scheduler-csr.json
#cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server kube-scheduler-csr.json |cfssljson -bare kube-scheduler
gencert server kube-scheduler-csr.json kube-scheduler

sed -e "s:clusteradmin:clusteradmin:g" ${RUNDIR}/template-csr.json                    > ${JSON_DIR}/kubectl-csr.json
#cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server kubectl-csr.json |cfssljson -bare kubectl
gencert server kubectl-csr.json kubectl

sed -e "s:temp:system\:kubeproxy:g" ${RUNDIR}/temp-client-csr.json                    > ${JSON_DIR}/kube-proxy-csr.json
#cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client kube-proxy-csr.json | cfssljson -bare kube-proxy
gencert client kube-proxy-csr.json kube-proxy

sed -e "s:temp:admin:g" ${RUNDIR}/temp-client-csr.json                                > ${JSON_DIR}/admin-csr.json
#cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server admin-csr.json | cfssljson -bare admin
gencert server admin-csr.json admin

sed -e "s:clusteradmin:system\:kubelet:g" ${RUNDIR}/template-csr.json                 > ${JSON_DIR}/kubelet-csr.json
#cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server kubelet-csr.json |cfssljson -bare kubelet
gencert server kubelet-csr.json kubelet

sed -e "s:clusteradmin:system\:flanneld:g" ${RUNDIR}/template-csr.json                > ${JSON_DIR}/flanneld-csr.json
#cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client flanneld-csr.json | cfssljson -bare flanneld
gencert client flanneld-csr.json flanneld

log_info  "  Copy ETCD SSL to ${ETCD_SSL_DIR}"
cp -p $SSL_DIR/peer.pem       $ETCD_SSL_DIR
cp -p $SSL_DIR/peer-key.pem   $ETCD_SSL_DIR
cp -p $SSL_DIR/ca.pem         $ETCD_SSL_DIR
cp -p $SSL_DIR/ca-key.pem     $ETCD_SSL_DIR
cp -p $SSL_DIR/server.pem     $ETCD_SSL_DIR
cp -p $SSL_DIR/server-key.pem $ETCD_SSL_DIR
log_info  "  Copy ETCD SSL to ${ETCD_SSL_DIR} done "

# inst_etcd
sh ${RUNDIR}/xsync -d $SSL_DIR
sh ${RUNDIR}/xsync -d $ETCD_SSL_DIR

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

#for i in {70..100}; do echo "\"192.168.1.${i}\",";done
#for i in {70..100}; do echo "\"10.10.10.${i}\",";done
#for i in {70..100}; do echo "\"win${i}\",";done
#for i in {70..100}; do echo "\"win${i}.inno,com\",";done