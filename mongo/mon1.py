import pymongo
from datetime import datetime, tzinfo, timezone

# uri = "mongodb://admin:Lenovo%402020@win74.inno.com:37017/?authSource=admin&readPreference=primary&directConnection=true&ssl=false"
uri = "mongodb://admin:Lenovo%402020@win74.inno.com:37017/?authSource=admin&readPreference=secondary&directConnection=true&ssl=false"

client = pymongo.MongoClient(uri)
dblist = client.list_database_names()

if "company" in dblist:
    print("company db is exist")
else:
    print("company db is not exist")

# db = client["eshop"]
# new_user = {"username": "nina", "password": "xxxx", "email":"123456@qq.com "}
# collection=db["user"]
# result = collection.insert_one(new_user)
# print(result)
# for x in collection.find():
#      print(x)

# result = collection.update_one({"username": "nina"},{ "$set": { "phone": "00123456789"} })
# # result = collection.update_many({"username": "nina"},{ "$set": { "phone": "123456789"} })
# print(result)
# for x in collection.find():
#      print(x)
ordertotalcount = [
    {
        '$match': {
            'status': 'completed',
            'orderDate': {
                '$gte': datetime(2019, 1, 1, 0, 0, 0, tzinfo=timezone.utc),
                '$lt': datetime(2019, 4, 1, 0, 0, 0, tzinfo=timezone.utc)
            }
        }
    }, {
        '$group': {
            '_id': None,
            'total': {
                '$sum': '$total'
            },
            'shippingFee': {
                '$sum': '$shippingFee'
            },
            'count': {
                '$sum': 1
            }
        }
    }, {
        '$project': {
            'grandTotal': {
                '$add': [
                    '$total', '$shippingFee'
                ]
            },
            'count': 1,
            '_id': 0
        }
    }
]
db = client["mock"]
collection = db["order"]
# collection.aggregate(ordertotalcount)
for x in collection.aggregate(ordertotalcount):
      print(x)