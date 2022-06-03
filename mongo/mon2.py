import pymongo
import datetime
import dns

#pip3 install pymongo[srv]
dns.resolver.default_resolver=dns.resolver.Resolver(configure=False)
dns.resolver.default_resolver.nameservers=["10.10.10.200"]
uri = "mongodb+srv://admin:Lenovo%402020@win74.inno.com/mongo?retryWrites=True&ssl=false"
# uri = "mongodb+srv://admin:lenovo%402020@win74.inno.com/?replicaSet=rs0?authSource=admin?retryWrites=true"
# uri = "mongodb://admin:Lenovo%402020@win72.inno.com:37017/?authSource=admin&readPreference=primary&directConnection=true&ssl=false"
# uri = "mongodb://admin:Lenovo%402020@win72.inno.com:37017/?authSource=admin&readPreference=secondary&directConnection=true&ssl=false"

client = pymongo.MongoClient(uri)

db = client["company"]
collection = db["employee"]
# for data in collection.find():
#     print(data)
data = [
    {
        "first_name": "Robin",
        "last_name": "Jackman",
        "title": "Software Engineer",
        "salary": 5500,
        "hire_date": "2001-10-12",
        "hobby": ["book", "movie"],
        "contact": {
            "email": "rj@jackman.com",
            "phone": 1111
        }
    },
    {
        "first_name": "Taylor",
        "last_name": "Edward",
        "title": "Software Architect",
        "salary": 7200,
        "hire_date": "2002-09-21",
        "hobby": ["travel", "hiking"],
        "contact": {
            "email": "te@edward.com",
            "phone": 2222
        }
    },
    {
        "first_name": "Vivian",
        "last_name": "Dickens",
        "title": "Database Administrator",
        "salary": 6000,
        "hire_date": "2012-08-29",
        "hobby": ["travel", "music"],
        "contact": {
            "email": "vd@dickens.com",
            "phone": 3333
        }
    },
    {
        "first_name": "Harry",
        "last_name": "Clifford",
        "title": "Database Administrator",
        "salary": 6800,
        "hire_date": "2015-12-10",
        "hobby": ["book", "gym"],
        "contact": {
            "email": "hc@clifford.com",
            "phone": 4444
        }
    }
]

# collection.insert_one(data)
# print(collection.write_concern.acknowledged)
collection.insert_many(data)

for x in collection.find():
    print(x)

new_user = {"username": "nina", "password": "xxxx", "email":"123456@qq.com "}

collection=db["user"]
result=collection.insert_one(new_user)

for x in collection.find():
    print(x)