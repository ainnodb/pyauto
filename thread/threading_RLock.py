"""
在普通锁中可能造成死锁的情况，可以考虑使用递归锁解决
"""
import time
import threading

# 如果是使用的两个普通锁，那么就会造成死锁的情况，程序一直阻塞而不会退出
# rlock_hi = threading.Lock()
# rlock_hello = threading.Lock()

# 使用成一个递归锁就可以解决当前这种死锁情况
rlock_hi = rlock_hello = threading.RLock()

def test_thread_hi():
    # 初始时锁内部的递归等级为1
    rlock_hi.acquire()
    print('线程test_thread_hi获得了锁rlock_hi')
    time.sleep(2)
    # 如果再次获取同样一把锁，则不会阻塞，只是内部的递归等级加1
    rlock_hello.acquire()
    print('线程test_thread_hi获得了锁rlock_hello')
    # 释放一次锁，内部递归等级减1
    rlock_hello.release()
    # 这里再次减，当递归等级为0时，其他线程才可获取到此锁
    rlock_hi.release()

def test_thread_hello():
    rlock_hello.acquire()
    print('线程test_thread_hello获得了锁rlock_hello')
    time.sleep(2)
    rlock_hi.acquire()
    print('线程test_thread_hello获得了锁rlock_hi')
    rlock_hi.release()
    rlock_hello.release()

def main():
    thread_hi = threading.Thread(target=test_thread_hi)
    thread_hello = threading.Thread(target=test_thread_hello)
    thread_hi.start()
    thread_hello.start()

if __name__ == '__main__':
    main()