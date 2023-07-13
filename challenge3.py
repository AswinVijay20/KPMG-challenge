# Online Python compiler (interpreter) to run Python online.
# Write Python 3 code in this online editor and run it.
# object = {"a":
#             {"b”:
#                 {
#                     "c":"d"
#                 }
#             }
# }

# import json
import ast

object = ast.literal_eval(input("enter the object:"))
# object = json.loads(input("enter the object:"))

key = str(input("enter the key:"))
keylist = key.split('/')
count=len(keylist)
print (count)
try:
    print(object[keylist[count-3]][keylist[count-2]][keylist[count-1]])
except KeyError:
    print("provided key is invalid")
    print("key provided: ",keylist)
    print("object in scope is: ",object)