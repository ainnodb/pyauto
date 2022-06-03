"""
事件对象使用实例
"""
import time
import threading

# 创建事件对象，内部标志默认为False
event = threading.Event()

def student_exam(student_id):
    print('学生%s等监考老师发卷。。。' % student_id)
    event.wait()
    print('开始考试了！')

def invigilate_teacher():
    time.sleep(5)
    print('考试时间到，学生们可以开始考试了！')
    # 设置内部标志为True，并唤醒所有等待的线程
    event.set()

def main():
    for student_id in range(3):
        threading.Thread(target=student_exam, args=(student_id, )).start()
    threading.Thread(target=invigilate_teacher).start()

if __name__ == '__main__':
    main()