print("""welcome to the api chat project verison 0.0.0.0
property of Luis A Marcu from 9b, tutor group 9s/Ma5
do not redirstribute with changed permissions and/ or features without my consent
===============""")
 
import requests as api
import time, random, uuid
 
API_URL = "https://retoolapi.dev/BsXrF1/data"
nerd_mode = False
 
def post(DATA):
    print("...")
    gmt = time.gmtime()
    d, h, m = gmt.tm_mday, gmt.tm_hour, gmt.tm_min
    DATA["time"] = d, h, m
    if nerd_mode:
        print(DATA)
    response = api.post(API_URL, json=DATA)
    if nerd_mode:
        print(f"posted to api with code {response.status_code}")
    print("loaded\n===============")
 
def delete(ID):
    if nerd_mode:
        print(f"deleting entry: {ID}")
    api.delete(API_URL+"/"+ID)
 
def output_messages():
    response = api.get(API_URL)
    if response.status_code == 200:
        data = response.json()
 
        if len(data) > 5:
            delete(data[1].get("id"))
            if nerd_mode:
                print(f"deleted message from user: {data[1].get("user")} id: {data[1].get("id")}")
 
        for item in data:
            id_value = item.get("id")
            if id_value == "user: hello? (645)":
                continue
            user_value = item.get("user")
            time_value = item.get("time")
            data_value = item.get("data")
            print(f"{user_value}\n{data_value}\nday: {time_value[0]} hour: {time_value[1]} min: {time_value[2]}\n===============")
 
 
username = input("what is your name >>")
user_id = random.randint(100, 1000)
welcome_messages = [
    "welcome",
    "say hello to",
    "all hail",
    "the end is near,",
    "thy end is NOW,",
    "maroi da flee flee"
]
post({
    "id":str(uuid.uuid4()),
    "user": "SERVER",
    "data": f"{welcome_messages[random.randint(0,5)]} {username} ({user_id})!"
})
 
print("write !help for a list of commands\n===============")
while True:
    message_id = str(uuid.uuid4())
    entry_data = input("message >>")
    data = {
        "id": message_id,
        "data": entry_data
    }
    if entry_data == "!help":
        print("!ping = show messages")
        print("!help = show commands")
        print("!nerd mode on/ off = shows dev info")
        continue
    elif entry_data == "!ping":
        output_messages()
        continue
    elif entry_data == "!nerd mode on":
        nerd_mode = True
        continue
    elif entry_data == "!nerd mode off":
        nerd_mode = False
        continue
    data = {
        "id": str(uuid.uuid4()),
        "user": f"{username} ({user_id})",
        "data": entry_data
    }
    post(data)
 
    output_messages