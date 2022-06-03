import pyttsx3

class Caculator:

    def __say(self,word):
        speaker = pyttsx3.init()
        speaker.say(word)
        speaker.runAndWait()

    def __create_say(word=""):
        def __say_word(func):
            def inner(self,n):
                self.__say(word+str(n))
                return func(self,n)
            return inner
        return __say_word

    def __check_number(func):
        def inneer(self,n):
            if not isinstance(n, int):
                raise TypeError("数据类型应为整形数据")
            return func(self,n)
        return inneer

    @__check_number
    @__create_say("")
    def __init__(self,num):
        self.__result=num

    @__check_number
    @__create_say("add")
    def add(self,n):
        self.__result+=n
        return self

    @__check_number
    @__create_say("minus")
    def mins(self,n):
        self.__result-=n
        return self

    @__check_number
    @__create_say("multiply")
    def multiply(self,n):
        self.__result*=n
        return self

    def show(self):
        self.__say("final result is :%d" %self.__result)
        print("final result is:%d" %self.__result)
        return self

    def clear(self):
        self.__say("clean up to Zero")
        self.__result=0
        print("clean up result to %d" % self.__result)
        return self

    @property
    def result(self):
        return self.__result

c1 = Caculator(10)
c1.add(6).mins(2).multiply(200).show().clear().add(5000).mins(200).multiply(20).show()