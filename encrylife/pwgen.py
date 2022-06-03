import random
from random import shuffle
import string

def generatepassword():
    key=''
    for i in range(requirement['lowercase']):
        key=key+random.choice(lowercase)

    for i in range(requirement['uppercase']):
        key=key+random.choice(uppercase)

    for i in range(requirement['digits']):
        key=key+random.choice(digits)

    for i in range(requirement['special']):
        key=key+random.choice(special)

    for i in range(requirement['length']-requirement['lowercase']-requirement['uppercase']-requirement['digits']-requirement['special']):
        key=key+random.choice(fulltable)

    key=list(key)

    generatekey=random.shuffle(key)
    return ''.join(key)

if __name__ == "__main__":
    print("默认的密码是16位,有2位大写,2位小写,2个特殊字符,2个数字\n")
    lowercase='abcdefghijklmnopqrstuvwxyz'
    uppercase='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    digits='0123456789'
    special= """!"#$%&'()*+,-./:;<=>?@[]^_`{|}~"""
    fulltable = lowercase+uppercase+digits+special
    requirement = {'lowercase' : 2 ,'uppercase': 2,'digits' :2,'special' : 2,'length':12}
    for j in range(10):
        print(generatepassword())