import cx_Oracle
import db_config_dba
import time


class DBCON():
    logFileName = "log.txt"

    def __init__(self):
        self.sql = ""
        self.bvid={}
        self.row=""
        self.rows=""
        self.rownum = 0
        self._result=""

    def _log(self, message):
        with open(self.logFileName, "a") as f:
            print(message, file=f)

    def __setattr__(self, key, value):
        self.__dict__[key] = value

    def connection(self):
        self._conn = db_config_dba.con
        self.cursor = self._conn.cursor()
        self._conn.client_identifier = "pythonuser"
        self._conn.action = self.sql[0:64]
        self._conn.module = "CX-Orace TESTING"
        self._log(time.strftime("%Y%m%d%H%M%S", time.localtime(time.time())))
        self._log("Connect to the database")
        self._log(self._conn.edition)

    def querytitle(self):
        if self.sql[0:6] != 'SELECT':
            self.cursor.scrollable = False
            print("You are going to " + self.sql +": ")
            self.insertbatch(self.sql)
        else:
            print("You are going to " + self.sql+": ")
            self._log(time.strftime("%Y%m%d%H%M%S", time.localtime(time.time())))
            self._log("You are going to " + self.sql+": ")
            self.cursor.scrollable = True
            if len(str(self.bvid))>2:
                self.cursor.prepare(self.sql)
                self.cursor.execute(None, self.bvid)
            else:
                self.cursor.execute(self.sql)

            colnames = []
            for i in range(0, len(self.cursor.description)):
                colnames.append(self.cursor.description[i][0])
            return  colnames

    def queryall(self): #打印所有行
        self.sql=self.sql.upper()
        self.querytitle()
        self.allrow= self.cursor.fetchall()
        for self.row in self.allrow:
            if self.row is not None:
                self.printresult()
            else:
                print("\n")

    def queryone(self):  #打印一行
        self.sql=self.sql.upper()
        self.querytitle()
        self.row = self.cursor.fetchone()
        if self.row is not None:
            self.printresult()
        else:
            print("no recorder found")

    def queryoneall(self): #逐行打印
        self.sql = self.sql.upper()
        self.querytitle()
        while 1:
            self.row = self.cursor.fetchone()
            if self.row is not None:
                self.printresult()
            else:
                break

    def querymany(self): #指定打印几行
        self.sql = self.sql.upper()
        self.querytitle()
        for i in range(0,self.rownum):
            print(self.cursor.fetchmany(numRows=self.rownum)[i])

    def srcollrow(self,number=1,mode="absolute"):
        self.sql = self.sql.upper()
        # self.querytitle()
        if mode=="first":
            self.cursor.scroll(mode="first")
            row = self.cursor.fetchone()
            if row is not None:
                print(row)
            else:
                print("no recorder found")
        elif mode=="last":
            self.cursor.scroll(mode="last")
            row = self.cursor.fetchone()
            if row is not None:
                print(row)
            else:
                print("no recorder found")
        else:
            if number>0:
                self.cursor.scroll(number,mode="absolute")
            else:
                self.cursor.scroll(number)
            row = self.cursor.fetchone()
            if row is not None:
                print(row)
            else:
                print("out of cursor")

    def insertbatch(self, sql):
        if len(str(self.bvid)) > 2:
            self.cursor.prepare(self.sql)
            try:
                self.cursor.executemany(None, self.bvid, batcherrors=True, arraydmlrowcounts=True)
            except (cx_Oracle.IntegrityError, cx_Oracle.DatabaseError) as e:
                rowCounts = self.cursor.getarraydmlrowcounts()
                print("Array DML row counts:", rowCounts)
                self._log(time.strftime("%Y%m%d%H%M%S", time.localtime(time.time())))
                self._log("Array DML row counts:", rowCounts)
                errorObj, = e.args
                errors = self.cursor.getbatcherrors()
                self._log(time.strftime("%Y%m%d%H%M%S", time.localtime(time.time())))
                self._log(print("number of errors which took place:", len(errors)))
                for error in errors:
                    self._log(time.strftime("%Y%m%d%H%M%S", time.localtime(time.time())))
                    self._log(print("Error", error.message.rstrip(), "at row offset", error.offset))
                    # self._log(errorObj.message)
            else:
                print(self.sql + " is executed successfully")
                print("with variant: ")
                print(self.bvid)
                rowCounts = self.cursor.getarraydmlrowcounts()
                self._log(time.strftime("%Y%m%d%H%M%S", time.localtime(time.time())))
                self._log(print("Array DML row counts:", rowCounts))
                self.commit()
        else:
            try:
                self.cursor.execute(sql)
            except (cx_Oracle.IntegrityError, cx_Oracle.DatabaseError) as e:
                print("target object not exist", e)
                errorObj, = e.args
                self._log(time.strftime("%Y%m%d%H%M%S", time.localtime(time.time())))
                self._log(errorObj.message)
            else:
                self._log(time.strftime("%Y%m%d%H%M%S", time.localtime(time.time())))
                self._log(print(self.sql + " is executed successfully"))
                self.commit()

    def printresult(self):
        print(self.row)

    def commit(self):
        self._conn.commit()

    def __exit__(self):
        self._log(time.strftime("%Y%m%d%H%M%S", time.localtime(time.time())))
        self._log("disconnect from oracle db")
        if hasattr(self, 'cursor'):
            self.cursor.close()
        if hasattr(self, '_conn'):
            self.close()

if __name__ == '__main__':
    query = DBCON()
    query.connection()

    query.sql = "select * from dba_users"
    print("print all rows")
    query.queryall()

    print("print one rows")
    query.sql = "select * from dba_users"
    query.queryone()

    print("print bind value ")
    query.sql = 'select * from dba_users where user_id = :bvid'
    query.bvid = {'bvid':112}
    query.queryall()

    print("print specifical row ")
    query.sql = 'select * from dba_users'
    query.bvid = {}
    query.rownum = 5
    query.querymany()

    print("测试scroll")
    # query.sql = 'SELECT * FROM DBA_USERS'
    # query.queryall()
    print("going to the first")
    query.srcollrow(mode="first")
    print("GOING to the last")
    query.srcollrow(mode="last")
    print("going to the second line")
    query.srcollrow(number=2,mode="absolute")
    print("skip  10")
    query.srcollrow(number=10)
    print("skip back 5")
    query.srcollrow(number=-5)

    query.bvid = {}
    query.sql='drop table departments purge'
    query.querytitle()

    query.sql='create table departments (department_id number, department_name varchar(100) ,CONSTRAINT DEP_ID ' \
              'primary key (department_id))'
    query.querytitle()

    # query.bvid = {'dept_id':280, 'dept_name': "Facility"}
    query.bvid = [(280, "Facility")]

    query.sql='insert into departments (department_id, department_name) values (:dept_id, :dept_name)'
    query.querytitle()

    query.bvid = {}
    query.sql ='select * from  departments'
    query.queryall()


    query.bvid = [(1, "First"), (2, "Second"),(3, "Third"), (4, "Fourth"), (5, "Fifth"), (6, "Sixth"),
            (7, "Seventh"),(7, None),(3,"Logistical")]
    query.sql='insert into departments (department_id, department_name) values (:dept_id, :dept_name)'
    query.querytitle()

    query.bvid = {}
    query.sql ='select * from  departments'
    query.queryall()

    query.sql="""
        SELECT username, client_identifier, module, action,client_info
        FROM V$SESSION
        WHERE username = 'SYS'"""
    print(query.queryoneall())