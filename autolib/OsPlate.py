import platform

def isWondows():
    '''
    判断当前运行平台
    :return:
    '''
    sysstr = platform.system()
    if (sysstr == "Windows"):
        return True
    elif (sysstr == "Linux"):
        return False
    else:
        print ("Other System ")
    return False
print(isWondows())