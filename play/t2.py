class Person():
    __personCount=0

    def __init__(self):
        print("count +1")
        Person.__personCount+=1

    def __del__(self):
        print("count -1")
        self.__class__.__personCount-=1

    @classmethod
    def log(cls):
        print("num of count %d" %cls.__personCount)


p=Person()
p2=Person()
Person.log()
del p
Person.log()
del p2
Person.log()