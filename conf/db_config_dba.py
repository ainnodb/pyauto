import os
#os.environ['NLS_LANG'] = 'SIMPLIFIED CHINESE_CHINA.UTF8'
#os.environ['NLS_LANG'] = 'AMERICAN_AMERICA.AL32UTF8'

import cx_Oracle
username= "sys"
password= "xxxxxx"
host= "xxxx.inno.com"
port= 1523
instance= "c193"
tns = cx_Oracle.makedsn(host,port,instance)
con=cx_Oracle.connect(username,password,tns)
#con=cx_Oracle.connect(username,password,tns, mode=cx_Oracle.SYSDBA, encoding="UTF-8" ,nencoding="UTF-8")
vs=con.version.split('.')
print(vs)
