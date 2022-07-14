#高阶函数 当一个函数A的参数，接收的又是另一个函数时，则把这个函数A称为是高阶函数
l=[{"name":"zs","age":18},{"name":"kaka","age":30},{"name":"xiaoyan","age":50}]

def getkey(x):
    return x["name"]
result=sorted(l,key=getkey)
print(result)

def cal(a,b,func):
    return func(a,b)

def sum(a,b):
    return a+b

def jian(a,b):
    return a-b


print(cal(3, 2, sum))
print(cal(3, 2, jian))