class Mymeta(type):

    def __new__(cls, *args, **kwargs):
        print('type 调用了Mymetar的 new 方法-->生成一个空对象，即People类\n' \
              '这里调用的是 type 的 new 方法，传入参数需要注意全部给 type 元类')
        return super().__new__(cls, *args, **kwargs)

    def __init__(self,class_name,class_bases,class_dict):
         print('初始化这个对象--People类，给People类添加额外的功能')
         super().__init__(class_name,class_bases,class_dict)
         #自定义的类功能
         if not class_name.istitle():
             raise TypeError('classname %s请修改为首字母大写'%class_name)

         if '__doc__' not in class_dict or len(class_dict['__doc__'].strip('\n'))==0:
             raise TypeError('类中必须有文档注释，并且文档注释不能为空')
         # print(self)
         # print(class_bases)
         # print(self.__base__)

    #传入Mymeta的参数：People， 以及传入Peopler的参数
    def __call__(self, *args, **kwargs):
        """
        self ---<class '__main__.Peopole'>
        :param args: (1,)
        :param kwargs: {'y',2}
        :retrun: 返回最终初始好的代码
        """
        print('调用了Mymetar 的call 方法')
        #调用People类里的__new__方法，生成空对象
        People_obj=self.__new__(self, *args, **kwargs)
        print(self)
        print(args)
        print(kwargs)
        # print(People_obj.type)
        print(People_obj)

        #调用People类城的__init__ 方法，初始化空对象 ，注意：第一个传入的参数是生成好的空对象
        self.__init__(People_obj, *args, **kwargs)

        #给People类生成的对象obj 添加额外的功能
        print('给People类生成的 obj 添加额外的功能')
        People_obj.__dict__["new_propert"]=None
        #返回初始化对象
        return People_obj


class People(metaclass=Mymeta):
    """this People class """

    def __new__(cls, *args, **kwargs):
        #在这里定制功能
        print('生成People类的空对象')
        print('传入的位置参数', args)
        print('传入的位置参数', kwargs)
        #调用所继承的父类的__new__方法，这里就是object 类,一定要传入cls（当前这个类）
        #这里要区别于自定义元类的new方法，自定义元类调用 的是type的new方法,传入参数是不一样的
        return super().__new__(cls)


    def __init__(self, x, y=None):
        print('初始化Peopleod 类的对象')
        self.x=x
        self.y=y
        print("初始化People类的对象结束")


obj=People(1,y=2)
print(obj.__dict__)
# print('最终的对象字典',obj.__dict__)

