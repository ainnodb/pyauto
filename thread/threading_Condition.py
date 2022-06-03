"""
让一个线程等待，直到另一个线程通知
"""
import time
import threading

# 创建条件变量对象
condition_lock = threading.Condition()

PRE = 0

# predicate可调用函数
def pre():
    print(PRE)
    return PRE

def test_thread_hi():
    # 在使用wait/wait_for之前必须先获得锁
    condition_lock.acquire()

    print('等待线程test_thread_hello的通知')
    # 先执行一次pre，返回False后释放掉锁，等另一个线程释放掉锁后再次执行pre，返回True后再次获取锁
    # wait_for的返回值不是True和False，而是predicate参数的返回值
    condition_lock.wait_for(pre)
    # condition_lock.wait()
    print('继续执行')

    # 不要忘记使用wait/wait_for之后要释放锁
    condition_lock.release()


def test_thread_hello():
    time.sleep(1)
    condition_lock.acquire()

    global PRE
    PRE = 1
    print('修改PRE值为1')

    print('通知线程test_thread_hi可以准备获取锁了')
    condition_lock.notify()

    # 先notify/notify_all之后在释放锁
    condition_lock.release()
    print('你获取锁吧')

def main():
    thread_hi = threading.Thread(target=test_thread_hi)
    thread_hello = threading.Thread(target=test_thread_hello)
    thread_hi.start()
    thread_hello.start()

if __name__ == '__main__':
    main()