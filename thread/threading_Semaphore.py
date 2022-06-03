"""
通过信号量对象管理一次性运行的线程数量
"""
import time
import threading

# 创建信号量对象，初始化计数器值为3
semaphore3 = threading.Semaphore(5)


def thread_semaphore(index):
    # 信号量计数器减1
    semaphore3.acquire()
    time.sleep(2)
    print('thread_%s is running...' % index)
    # 信号量计数器加1
    semaphore3.release()


def main():
    # 虽然会有9个线程运行，但是通过信号量控制同时只能有3个线程运行
    # 第4个线程启动时，调用acquire发现计数器为0了，所以就会阻塞等待计数器大于0的时候
    for index in range(10):
        threading.Thread(target=thread_semaphore, args=(index, )).start()


if __name__ == '__main__':
    main()