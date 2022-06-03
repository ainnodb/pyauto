import paramiko
import threading
import sys
import os
import time
import datetime
import getpass
from conf import logconf

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

def totoalremotehost():
    """
        :return:  hostname list
    """
    try:
        hosts=open("all.txt", "r", encoding='utf-8')
        hosttoal = len(hosts.readlines())
        print("There are  %d target host " % (hosttoal))
        return hosttoal
    except (FileNotFoundError,LookupError,UnicodeDecodeError) as e :
        print("file can't open reason ",e)
    finally:
        if hosts:
            hosts.close()

class Remoteserver(object):

    """
    Container class for SSH functionality. Needs to be used in a with statement.
    """

    def __init__(self):
        ssh_client = None
        user = None
        password = None
        self.ssh_client = paramiko.SSHClient()
        self.ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    def __setattr__(self, key, value):
        self.__dict__[key]=value

    def __exit__(self, exc_type, exc_val, exc_tb):
        try:
            if self.ssh_client is not None:
                logging.warning('will exit remote server %s' %(self.server))
                self.ssh_client.close()
        except:
            print ("received an exception closing the ssh connection.")
        finally:
            self.ssh_client = None

    def connect(self, server, user, password,port=22):

        try:
            logger.info("Trying to server %s "%(server))
            self.ssh_client.connect(server, 22,self.user, self.password)
            logger.info("Connect to server %s "%(server))

        except paramiko.AuthenticationException:
            logging.warning('username or password not correct')
            try:
                self.ssh_client.connect(server,22, username=self.user, password=self.password)
            except:
                logging.warning('username or password not correct,excting')
                sys.exit(1)
        except:
            logging.warning('connect to remote server %s failed' %(self.server))
            now = time.strftime("%Y%m%d%H%M%S", time.localtime(time.time()))
            with open(self.server + "_" + now + "ERROR.txt", "w+", encoding="utf+8") as output:
                LOG_WARNING("result is write to log file %s_%sERROR.txt" % (self.server, now))
            exit()

    @timecost
    def execute(self, command, sudo=False):
        self.connect(self.server, self.user, self.password)
        out= threading.local()
        out=''
        time_start = time.time()
        for m in command:
            m=m.strip("\n")
            now = time.strftime("%Y%m%d%H%M%S", time.localtime(time.time()))
            out=out+m+" :\t"
            try:
                logging.info("Start execute command %s in %s at %s " %(m,self.server,now))
                stdin, stdout, stderr = self.ssh_client.exec_command(m)
                out = out + "\n\n" + str(stdout.read().decode(encoding='utf-8')) + "\n"
            except paramiko.SSHException:
                out = out + "\n\n"+ str(stderr.read().decode(encoding='utf-8'))+"\n"
            time_end = time.time()
            logging.info("end at: %s " %(time_end))
            out = out + str(time_end) +"程序总共运行%d秒"%int(time_end-time_start)+"\n"
        if sudo:
            stdin.write(self.password + '\n')
            stdin.flush()
        with open(self.server+"_"+now+"SUCCESS.txt","w+",encoding="utf+8") as output:
            print("result is write to log file %s_%sSUCCESS.txt" %(self.server,now))
            output.write(out)
        logging.info('will exit remote server %s' % (self.server))
        #print('will exit remote server %s' % (self.server))
        self.ssh_client.close()

if __name__ == '__main__':
    # sys.path.append('f:\\pyauto\\pysh')
    curPath = os.path.abspath(os.path.dirname(__file__))
    rootPath = os.path.split(curPath)[0]
    sys.path.append(rootPath)

    hostlist=[]
    threads=[]
    host=Remoteserver()
    with open("all.txt",'r',encoding='utf-8') as batch:
        remotehosts = batch.readlines()

    with open("command.txt",'r',encoding='utf-8') as batch:
        command = batch.readlines()

    username = 'root'
    password = getpass.getpass('please type password of %s :' %username)
    out= threading.local()
    i = 0
    for targethost in remotehosts:
        targethost=targethost.strip("\n")
        hostlist.append(host)        
        hostlist[i].server=targethost
        hostlist[i].port=22
        hostlist[i].user=username
        hostlist[i].password=password
        threads.append(threading.Thread(hostlist[i].execute(command=command),name = targethost))
        threads[i].start()
        threads[i].join()
        i=i+1