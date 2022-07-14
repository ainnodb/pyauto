import sys
class Person:
    pass

p=Person()
print(sys.getrefcount(p))

def log(obj):
    print(sys.getrefcount(obj))

log(p)

for attr in dir(log):
    print(attr)
    print(getattr(log,attr))