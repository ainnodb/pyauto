import paramiko
from timeit import default_timer
from conf import logconf
import os
import re

import  datetime

user = 'root'
password = 'xxxxxxx'
#pkey = r'"F:\myauto\pysh\id_rsa"'





class linuxs(object):

    def __init__(self, ip, username, password, timeout=30):
        self.ip = ip
        self.username = username
        self.password = password
        self.timeout = timeout
        # transport和chanel
        self.t = ''
        self.chan = ''
        # 链接失败的重试次数
        self.try_times = 3
        self._log_time = log_time
        self._log_label = log_label

    def timecost(func):
        def inner(*args, **kwargs):
            starttime = datetime.datetime.now()
            func_name = str(func).split(' ')[1]
            logger.info('Start execute %s at %s', func_name, starttime.strftime('%Y-%m-%d %H:%M:%S.%f'))
            logger.info('Execute %s with parameter: %s ', func_name, (args or kwargs or ('No parameter')))
            result = func(*args, **kwargs)
            func_name = str(func).split(' ')[1]
            endtime = datetime.datetime.now()
            logger.info('Execute %s end at %s', func_name, endtime.strftime('%Y-%m-%d %H:%M:%S.%f'))
            logger.info('Execute %s is successfully finish with parameter: %s done', func_name,
                        (args or kwargs or ('No parameter')))
            logger.info('Execute {} using times: {}s'.format(func_name, endtime - starttime))
            return result

        return self.timeout.inner

    @timecost
    def get_connection(self):
        while True:
            # 连接过程中可能会抛出异常，比如网络不通、链接超时
            try:
                self.t = paramiko.Transport(sock=(self.ip, 22))
                logger.info('start connection %s' % self.ip)
                self.t.connect(username=self.username, password=self.password)
                self.chan = self.t.open_session()
                self.chan.settimeout(self.timeout)
                self.chan.get_pty()
                self.chan.invoke_shell()
                # 如果没有抛出异常说明连接成功，直接返回
                logger.info('connect to %s successfully!' % self.ip)

                # 接收到的网络数据解码为str
                logger.info(self.chan.recv(65535).decode('utf-8'))
                return
            # 这里不对可能的异常如socket.error, socket.timeout细化，直接一网打尽
            except Exception as ConnectionError:
                if self.try_times != 0:
                    logger.info(u'连接%s失败，进行重试' % self.ip)
                    self.try_times -= 1
                else:
                    logger.info('重试3次失败，结束程序')
                    exit(1)


    def __enter__(self):

        # 如果需要记录时间
        if self._log_time is True:
            self._start = default_timer()

        # 在进入的时候自动获取连接和cursor
        self.get_connection()

        logfile = logtarget +'.' + server.split('.')[0]+'_'+str(os.getpid())
        logger = logconf.logconf(logfile)  # init log config
        return self

    @timecost
    def execute(self,sudo=False):

        commands=""
        path = os.path.dirname(os.getcwd())
        with open("f:\pyauto\conf\command.txt", 'r', encoding='utf-8') as batch:
            commands = batch.readlines()
        logger.info("following command will be execute %s" % (commands))

        for command in commands:
            command = command.strip("\n")
            try:
                starttime = datetime.datetime.now()
                self.logger.info('Start execute command: (%s) on host (%s) ',command,self.server)
                stdin, stdout, stderr = self.ssh_client.exec_command(command,timeout=180)
                self.logger.info('Following is the (%s) result \n',command)
                self.logger.info(stdout.read().decode(encoding='utf-8'))
                self.logger.info('Execute ({}) used times: ({}s) \n'.format(command, datetime.datetime.now() - starttime))
            except paramiko.SSHException:
                self.logger.error(stderr.read().decode(encoding='utf-8'),exc_info=True)
                self.logger.info("End of  execute on server (%s)",self.server)
                self.logger.error("Pls check the reason and run agin", self.server)
                exit()
                if sudo:
                    stdin.write(self.password + '\n')
                    stdin.flush()
            if stderr.read().decode(encoding='utf-8'):
                self.logger.error(stderr.read().decode(encoding='utf-8'), exc_info=True)
                self.logger.info("End of  execute on server (%s)", self.server)
                self.logger.error("Pls check the command (%s) and run agin",command)
                self.status = False
                break
        if self.status == False:
            self.logger.info("One of the command is run failed  on (%s),pls check the logfile (%s) for detail information !!! \n", self.server,os.path.join(os.path.dirname(os.getcwd()),'worklog',self.logfile))
        else:
            self.logger.info("all the batch process running successfully on (%s) \n", self.server)

    def __exit__(self, *exc_info):
       self._conn.close()
       if self._log_time is True:
           diff = default_timer() - self._start
           print('-- %s: %.6f 秒' % (self._log_label, diff))