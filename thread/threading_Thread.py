"""
通过实例化threading.Thread类创建线程
"""
import time
import threading


def test_thread(para='hi', sleep=0):
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
    print('Main thread has ended!')


if __name__ == '__main__':
    main()