     build mysql 
     ---install mysql with scripts
    deploy inst    "initial mysql and start mysql"
         - post    "reset initial password and setup loging-path=root
         - stop     "stop mysqldb"
         - start    "start mysqldb
         - restart   "restart mysql"
         - 
     ============================================================================================
     
    ---deploy mysql slaves
    ---running in the master host and  copy db to target slave host and start db"---
    replicate targethost /directory    
    ---setup login-paht for superman and start slave 
    replicatepost     

    ---install xtrabackup tool
    backuptool                                          

    ---backup for mysql db
    backup_mysql   directory(default /data/mysqldata)   

    ---restore mysql db
    restore_mysql  directory                             

    ---run sql command or sqlfile direclty"
    sqlexec sqlfile/sql                                  
 
