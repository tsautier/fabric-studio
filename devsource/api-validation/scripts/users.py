import json
import random
from faker import Faker

fake = Faker()

# Generate 100 random users
users = [
    { "firstName": fake.first_name(), "lastName": fake.last_name(), "email": fake.email() }
    for _ in range(12000)
]

# Save to a JSON file
file_path = "/tmp/random_users.json"
with open(file_path, "w") as json_file:
    json.dump(users, json_file, indent=2)

file_path
