import os
import json
import getpass
import base64
import bcrypt
from crypto import generate_salt, derive_key


# paths for storing config
DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
CONFIG_FILE = os.path.join(DATA_DIR, "config.json")

MAX_ATTEMPTS = 3


# make sure the data folder exists
def ensure_data_dir():
    if not os.path.exists(DATA_DIR):
        os.makedirs(DATA_DIR)


# load config from file
def load_config():
    if not os.path.exists(CONFIG_FILE):
        return None
    with open(CONFIG_FILE, "r") as file:
        data = json.load(file)
    return data


# save config to file
def save_config(config):
    ensure_data_dir()
    with open(CONFIG_FILE, "w") as file:
        json.dump(config, file, indent=2)


# check if this is the first time the app is being used
def is_first_launch():
    config = load_config()
    if config is None:
        return True
    return False


# first time setup - ask user to create a master password
def setup_master_password():
    print("\n--- First Time Setup ---")
    print("You need to create a master password to protect your vault.\n")

    while True:
        password = getpass.getpass("Create a master password: ")

        # make sure its at least 6 characters
        if len(password) < 6:
            print("Password too short! Use at least 6 characters.\n")
            continue

        confirm = getpass.getpass("Confirm your master password: ")

        if password != confirm:
            print("Passwords don't match! Try again.\n")
            continue

        # if we get here, password is good
        break

    # hash the password with bcrypt
    hashed = bcrypt.hashpw(password.encode(), bcrypt.gensalt())

    # generate a salt for encryption key derivation
    salt = generate_salt()

    # save the hash and salt to config file
    config = {
        "master_hash": hashed.decode(),
        "salt": base64.urlsafe_b64encode(salt).decode()
    }
    save_config(config)

    print("\nMaster password created successfully!\n")

    # derive and return the encryption key
    key = derive_key(password, salt)
    return key


# verify the master password when user comes back
def verify_master_password():
    config = load_config()
    stored_hash = config["master_hash"].encode()
    salt = base64.urlsafe_b64decode(config["salt"])

    for attempt in range(1, MAX_ATTEMPTS + 1):
        password = getpass.getpass(f"\nEnter master password (attempt {attempt}/{MAX_ATTEMPTS}): ")

        # check if password matches the stored hash
        if bcrypt.checkpw(password.encode(), stored_hash):
            print("Authentication successful!\n")
            key = derive_key(password, salt)
            return key
        else:
            remaining = MAX_ATTEMPTS - attempt
            if remaining > 0:
                print(f"Wrong password! {remaining} attempt(s) left.")
            else:
                print("\nToo many failed attempts. Application locked!")
                print("Exiting...\n")

    # if we get here, all attempts failed
    return None
