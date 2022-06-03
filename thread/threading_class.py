"""
通过继承threading.Thread的子类创建线程
"""
import time
import threading


class TestThread(threading.Thread):
    def __init__(self, para='hi', sleep=3):
        # 重写threading.Thread的__init__方法时，确保在所有操作之前先调用threading.Thread.__init__方法
        super().__init__()
        self.para = para
        self.sleep = sleep

    def run(self):
        """线程内容"""
        time.sleep(self.sleep)
        print(self.para)


def main():
    # 创建线程
    thread_hi = TestThread()
    thread_hello = TestThread('hello', 1)
    # 启动线程
    thread_hi.start()
    thread_hello.start()
    print('Main thread has ended!')


if __name__ == '__main__':
    main()