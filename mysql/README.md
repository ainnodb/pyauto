build mysql :

    deploy inst    "initial mysql and start mysql"
         - post    "reset initial password and setup loging-path=root
         - stop     "stop mysqldb"
         - start    "start mysqldb
         - restart   "restart mysql"
         - plus      "install plugus"  example: <sh deploy plus semisync_master.so>
  
    replicate targethost /directory    "running in the master host and  copy db to target slave host and start db"
    replicatepost     "setup login-paht for superman and start slave 

    backuptool                                          "install xtrabackup tool"
    backup_mysql   directory(default /data/mysqldata)   "backup for mysql db"
    restore_mysql  directory                             "restore mysql db" 



 
