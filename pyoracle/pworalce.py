import datetime
import gc
import os
from conf import db_config_dba,logconf


def timecost(func):
    def inner(*args, **kwargs):
        starttime = datetime.datetime.now()
        func_name = str(func).split(' ')[1]
        # logger.info('Start doing %s ', func_name)
        logger.info('Start doing %s and detail parameter: %s ', func_name,(args or kwargs or ('No parameter')))
        result = func(*args, **kwargs)
        # func_name = str(func).split(' ')[1]
        # logger.info('%s done', func_name)
        logger.info('Execute {} using times: {}s'.format(func_name, datetime.datetime.now() - starttime))
        logger.info("%s is done successfully with detail parameter: %s '\n'", func_name,(args or kwargs or ('No parameter')))

        return result
    return inner

@timecost
def threefor(name='get three length password library'):
    three=[]
    for key1 in word:
        for key2 in word:
            for key3 in word:
                three.append({'wordkey': key1 + key2 + key3})
    return three

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
def executesql(sql):
    try:
        cursor.execute(sql)
    except Exception:
        logger.error('Faild to execute %s', sql,exc_info=True)
    else:
        # logger.info("Execute %s successfully", sql)
        pass

@timecost
def executemanysql(name='executemany'):
    try:
        logger.info('Start batch execute %s',sql)
        cursor.executemany(sql,threefor())
    except Exception:
        logger.error('Faild to  batch execute %s', sql,exc_info=True)
    else:
       pass

@timecost
def sqlcommit(name='commit sql in this module'):
    try:
        db.commit()
    except Exception:
        logger.error("Faild to commit: %s", sql, exc_info=True)
    else:
        pass

@timecost
def condb(name="connect to oracle database"):       #create oracle db connection
    try:
        db = db_config_dba.con
    except Exception:
        logger.error('Faild to gconnection to oracle Database', exc_info=True)
    else:
        cursor = db.cursor()
        return db,cursor

@timecost
def closedb():
    try:
        cursor.close()
        db.close()
    except Exception :
        logger.error('Faild to gconnection to oracle Database', exc_info=True)

if __name__ == "__main__":

    gc.collect()
    logtarget = os.path.basename(__file__).split('.')[0]
    logger = logconf.logconf(logtarget)        #init log config
    word = getword()                  #get password character set
    db,cursor=condb()                         #connect to oracle db

    sql = 'drop table librarykey purge'
    executesql(sql)
    sql = 'create table librarykey ( wordkey varchar(20),CONSTRAINT work_key primary key (wordkey))'
    executesql(sql)
    sql = 'insert into librarykey (wordkey) values (:wordkey)'
    executemanysql(sql)

    # verfication the key number's as the sql result is tuple, so we should use row[0]
    sql = 'select count(*) from  librarykey'
    executesql(sql)
    for threekey in cursor:
        threekey[0]
    if threekey[0] == len(word)*len(word)*len(word):
        logger.info('total password number should be %d:',threekey[0])
        sqlcommit()
    else:
        print("not all the password is generate,pls try again")
        logger.error('password library set in oracle db is failed', exc_info=True)
    closedb()
    gc.collect()