import functools

def test(a,b,c,d=3):
    return a+b+c+d

newfunc=functools.partial(test,c=15)
print(newfunc,type(newfunc))
print(newfunc(1, 2))

numstr='100010'
int2=functools.partial(int,base=2)
print(int2(numstr))