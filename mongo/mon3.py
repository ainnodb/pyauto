# Requires the PyMongo package.
# https://api.mongodb.com/python/current
from datetime import datetime, tzinfo, timezone
from pymongo import MongoClient

client = MongoClient('mongodb://admin:Lenovo%402020@win74.inno.com:37017/?authSource=admin&readPreference=primary&appname=MongoDB+Compass+Beta&directConnection=true&ssl=false')
result = client['mock']['orders'].aggregate([
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
])
print(result)