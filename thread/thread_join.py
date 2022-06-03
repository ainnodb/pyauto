"""
使用join方法阻塞主线程
"""
import time
import threading

def test_thread(para='hi', sleep=5):
    """线程运行函数"""
    time.sleep(sleep)
    print(para)

def main():
    # 创建线程
    thread_hi = threading.Thread(target=test_thread)
    thread_hello = threading.Thread(target=test_thread, args=('hello', 1))
    # 启动线程
    thread_hi.start()
    thread_hello.start()
    time.sleep(2)
    print('马上执行join方法了')
    # 执行join方法会阻塞调用线程（主线程），直到调用join方法的线程（thread_hi）结束
    thread_hi.join()
    print('线程thread_hi已结束')
    # 这里不会阻塞主线程，因为运行到这里的时候，线程thread_hello已经运行结束了
    thread_hello.join()
    print('Main thread has ended!')

    # 以上代码只是为了展示join方法的效果
    # 如果想要等所有线程都运行完成后再做其他操作，可以使用for循环
    # for thd in (thread_hi, thread_hello):
    #     thd.join()
    # print('所有线程执行结束后的其他操作')


if __name__ == '__main__':
    main()