#noupdate
from pickle import NONE
import pymysql
from timeit import default_timer

host = 'win88.inno.com'
port = 3308
db = 'eygle'
user = 'root'
password = 'Lenovo@2020'



# ---- 用pymysql 操作数据库
def get_connection():
    conn = pymysql.connect(host=host, port=port, db=db, user=user, password=password)
    return conn


class mysqlrun(object):

    def __init__(self, host=host, port=port, db=db, user=user, password=password,commit=True, log_time=True, log_label='总用时'):
        """
        :param commit: 是否在最后提交事务(设置为False的时候方便单元测试)
        :param log_time:  是否打印程序运行总时间
        :param log_label:  自定义log的文字
        """
        # 在进入的时候自动获取连接和cursor
        self.conn = pymysql.connect(host,user,password,db)
        # 设置字符编码
        self.conn.set_charset('utf8')
        # 设置游标对象
        self.cursor = self.conn.cursor()
        self._log_time = log_time
        self._commit = commit
        self._log_label = log_label
        self.conn.autocommit = True
        self._conn = conn
        self._cursor = cursor

    def __enter__(self):
       # 如果需要记录时间
        if self._log_time is True:
            self._start = default_timer()
        return self

    def __exit__(self, *exc_info):
        # 提交事务
        if self._commit:
            self._conn.commit()
        # 在退出的时候自动关闭连接和cursor
        self._cursor.close()
        self._conn.close()

        if self._log_time is True:
            diff = default_timer() - self._start
            print('-- %s: %.6f 秒' % (self._log_label, diff))
    
    def select(self,sql,one=True):
        self.execute(sql)
        if one:
            return self.cursor,fetchone()
        else:
            return self.cursor.fetchall()
    

    def execute(self,sql,args=NONE):
        try:
            self.cursor.execute(sql,args)
            self.conn.commit()
        except:
            self.conn.rollbac()
        return

    @property
    def cursor(self):
        return self._cursor

if __name__ == "__main__":
    A=mysqlrun(host=host, port=port, db=db, user=user, password=password)
    sql= "select count(*) from dict4"
    A.select(sql)