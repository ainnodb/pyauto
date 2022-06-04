
import datetime
import gc
import os
import sys
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  
# __file__获取执行文件相对路径，整行为取上一级的上一级目录
sys.path.append(BASE_DIR)
from conf import pymysql_conf
from conf import logconf
# import conf.pymysql_conf,conf.logconf

def timecost(func):
    def inner(*args, **kwargs):
        starttime = datetime.datetime.now()
        func_name = str(func).split(' ')[1]
        logger.info('Start doing %s ', func_name)
        logger.info('Start doing %s and detail parameter: %s ', func_name,(args or kwargs or ('No parameter')))
        result = func(*args, **kwargs)
        func_name = str(func).split(' ')[1]
        logger.info('%s done', func_name)
        logger.info('Execute {} using times: {}s'.format(func_name, datetime.datetime.now() - starttime))
        logger.info("%s is done successfully with detail parameter: %s '\n'", func_name,(args or kwargs or ('No parameter')))

        return result
    return inner

@timecost
def threefor(sql,name='get three length password library'):
    # three=[]
    with pymysql_conf.UsingMysql(log_time=True) as um:
        for key1 in word:
            for key2 in word:
                for key3 in word:
                    for key4 in word:
                        # for key5 in word:
                            # for key6 in word:
                        # three.append({'wordkey': key1 + key2 + key3 + key4})
                        um.cursor.execute(sql,key1+key2+key3+key4)
                um.cursor.execute("commit")

                                # three.append({'wordkey': key1 + key2 + key3 + key4 + key5 + key6})
                        # um.cursor.execute(sql, key1 + key2 + key3 + key4 + key5 + key6)
                        # um.cursor.execute("commit")
    # return three

@timecost
def getword(name='get password character sets'):
    lowercase = 'abcdefghijklmnopqrstuvwxyz'
    uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    digits = '0123456789'
    special = """!"#$%&'( )*+,-./:;<=>?@[]^_`{|}~"""
    word = lowercase + uppercase + digits + special
    logger.info('word content is: %s and total with %d', word,len(word))
    return word

@timecost
def executesql(sql,args=None):
    sql_reslut=0
    with pymysql_conf.UsingMysql(log_time=True) as um:
        um.cursor.execute(sql,args=None)
        sql_reslut=um.cursor.rowcount
    return sql_reslut


if __name__ == "__main__":

    gc.collect()
    logtarget = os.path.basename(__file__).split('.')[0]
    logger = logconf.logconf(logtarget)        #init log config
    word = getword()                           #get password character set

    sql= 'drop table if exists dict4'
    result = executesql(sql)
    print(result)

    sql = 'create table dict4 (id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,wordkey char(20))'
    # sql = 'create table dict6 (id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,wordkey varchar(20))'
    executesql(sql)
    sql = 'insert into dict4 (wordkey) values (%s)'
    threefor(sql)

    # verfication the key number's as the sql result is tuple, so we should use row[0]
    sql = 'select count(*) from dict4'
    print(executesql(sql))