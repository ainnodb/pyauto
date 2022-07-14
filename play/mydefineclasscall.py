class Mymeta(type):
    def __call__(self, *args, **kwargs):
        print(self)
        print(args)
        print(kwargs)
        return 123

class People(metaclass=Mymeta):

    def __init__(self, x, y=None):
        self.x=x
        self.y=y

obj=People(1,y=3)
print(obj)