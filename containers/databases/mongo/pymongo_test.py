import pymongo 
import pprint
mongo_uri = "mongodb://localhost:27017/" 
dbclient = pymongo.MongoClient(mongo_uri)
appdb = dbclient["blog"]
appcoll = appdb["blogcollection"]
document = {"user_id": 1, "user": "test"}
print(appcoll.insert_one(document))
print(dbclient.list_database_names())
pprint.pprint(appcoll.find_one())
