#返回函数是指一个函数内部，它返回的数据是另外一个函数，把这样的操作称为 返回函数
def getfunc(flag):

    def sum(a,b,c):
        return a+b+c

    def jian(a,b,c):
        return a-b-c

    if flag=="+":
        return sum
    elif flag=="-":
        return jian

result=getfunc("+")
print(result)
print(getfunc)

print(result(1, 3, 5))

result=getfunc("-")
print(result(5,1,2))