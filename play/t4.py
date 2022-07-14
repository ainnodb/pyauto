import objgraph
import gc
import weakref

class Person:
    def __del__(self):
        print("Person object is released")
    pass

class Dog:
    def __del__(self):
        print("Dog object is released")
    pass

p=Person()
d=Dog()

print(objgraph.count("Person"))

print(objgraph.count("Dog"))
p.pet=d
d.master=weakref.ref(p)  #弱引用避免循环引用产生
# pets=weakref.WeakValueDictionary({"dog":d1,"cat":c1})

print(objgraph.count("Person"))

print(objgraph.count("Dog"))
del p
del d
print(objgraph.count("Person"))
print(objgraph.count("Dog"))
gc.collect()
print(objgraph.count("Person"))
print(objgraph.count("Dog"))
