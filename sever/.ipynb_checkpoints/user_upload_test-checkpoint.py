import requests

url = "http://localhost:8000/detect/"
image_path = r"C:\Users\tnt93\Desktop\FLUTTER\FLUTTER-APP\正式後端\data base photo\得安穩.jpg"

with open(image_path, "rb") as f:
    files = {"file": (image_path, f, "image/jpg")}
    response = requests.post(url, files=files)

print(response.json())