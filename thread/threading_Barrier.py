"""
栅栏对象使用示例
"""
import time
import threading


def test_action():
    print('所有栅栏线程释放前调用此函数！')


# 创建线程数为3的栅栏对象，当“拦住”3个线程的wait后放行，然后又继续“拦”（如果有的话）
barrier = threading.Barrier(3, test_action)


def barrier_thread(sleep):
    time.sleep(sleep)
    print('barrier thread-%s wait...' % sleep)
    # 阻塞线程，直到阻塞线程数达到栅栏指定数量
    barrier.wait()
    print('barrier thread-%s end!' % sleep)


def main():
    # 这里开启了6个线程，则一次会拦截3个
    for sleep in range(6):
        threading.Thread(target=barrier_thread, args=(sleep, )).start()


if __name__ == '__main__':
    main()