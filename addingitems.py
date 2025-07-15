import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("serviceAccountKey.json")  # Replace with your key
firebase_admin.initialize_app(cred)

db = firestore.client()

items = [
    ("ITEM016", "Shezwan Rice", 40),
    ("ITEM017", "Shezwan Rice Mix", 50),
    ("ITEM018", "Zeera Rice Mix", 45),
    ("ITEM019", "Hong Kong Rice", 50),
    ("ITEM020", "Hong Kong Rice Mix", 55),
    ("ITEM021", "Noodles Mix", 50),
    ("ITEM022", "Paneer Noodles Mix", 60),
    ("ITEM023", "Shezwan Noodles", 50),
    ("ITEM024", "Shezwan Noodles Mix", 55),
    ("ITEM025", "Gobi 65", 40),
    ("ITEM026", "Spring Roll", 50),
    ("ITEM027", "Sandwich Roll", 55),
    ("ITEM028", "Pastha", 45),
    ("ITEM029", "Pastha Mix", 55),
]

for itemId, name, price in items:
    db.collection("menuItems").document(itemId).set({
        "itemId": itemId,
        "name": name,
        "price": price,
        "category": "Chinese",
        "description": "",
        "imageUrl": None,
        "isSpecial": False,
        "availability": True,
        "orderCount": 0
    })

print("Items added successfully.")
