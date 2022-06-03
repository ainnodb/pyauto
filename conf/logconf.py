import logging
import os,sys
from conf import newfile
def logconf(logtarget):
    logger = logging.getLogger('main')
    logger.setLevel(logging.INFO)
    formatter = logging.Formatter(fmt='%(asctime)s - %(name)s - %(filename)s - %(funcName)s - %(levelname)s - %(message)s',datefmt="%d-%m-%Y %H:%M:%S")
    # # standoutput
    stream_handler = logging.StreamHandler(sys.stdout)
    stream_handler.setLevel(level=logging.INFO)
    stream_handler.setFormatter(formatter)
    logger.addHandler(stream_handler)

    logfile=newfile.newfile(logtarget)
    file_handler = logging.FileHandler(logfile)
    file_handler.setLevel(level=logging.INFO)           # 设置日志级别
    file_handler.setFormatter(formatter)                # 添加日志格式
    logger.addHandler(file_handler)                     # 添加处理器
    return logger