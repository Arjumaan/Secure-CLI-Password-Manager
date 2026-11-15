import os
import json
from datetime import datetime
from crypto import encrypt, decrypt


# file paths
DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
VAULT_FILE = os.path.join(DATA_DIR, "vault.json")


# make sure data folder exists
def ensure_data_dir():
    if not os.path.exists(DATA_DIR):
        os.makedirs(DATA_DIR)


# load all credentials from the vault file
def load_vault():
    if not os.path.exists(VAULT_FILE):
        return []
    with open(VAULT_FILE, "r") as file:
        data = json.load(file)
    return data


# save credentials to the vault file
def save_vault(entries):
    ensure_data_dir()
    with open(VAULT_FILE, "w") as file:
        json.dump(entries, file, indent=2)


# add a new credential
def add_credential(website, username, password, key):
    entries = load_vault()

    # check if this credential already exists
    for entry in entries:
        if entry["website"].lower() == website.lower() and entry["username"].lower() == username.lower():
            print("This credential already exists! Use update instead.")
            return False

    # encrypt the password before storing
    encrypted_password = encrypt(password, key)

    new_entry = {
        "website": website,
        "username": username,
        "password": encrypted_password,
        "added_on": str(datetime.now())
    }

    entries.append(new_entry)
    save_vault(entries)
    return True


# view credentials for a specific website (decrypted)
def view_credential(website, key):
    entries = load_vault()
    results = []

    for entry in entries:
        if entry["website"].lower() == website.lower():
            decrypted_password = decrypt(entry["password"], key)
            results.append({
                "website": entry["website"],
                "username": entry["username"],
                "password": decrypted_password,
                "added_on": entry.get("added_on", "N/A")
            })

    return results


# list all credentials (passwords are hidden)
def list_all():
    entries = load_vault()
    result = []

    for entry in entries:
        result.append({
            "website": entry["website"],
            "username": entry["username"],
            "password": "********",
            "added_on": entry.get("added_on", "N/A")
        })

    return result


# update an existing credential
def update_credential(website, username, new_username, new_password, key):
    entries = load_vault()
    found = False

    for entry in entries:
        if entry["website"].lower() == website.lower() and entry["username"].lower() == username.lower():
            if new_username:
                entry["username"] = new_username
            if new_password:
                entry["password"] = encrypt(new_password, key)
            found = True
            break

    if found:
        save_vault(entries)
    return found


# delete a credential
def delete_credential(website, username):
    entries = load_vault()
    new_entries = []

    for entry in entries:
        # keep everything except the one we want to delete
        if entry["website"].lower() == website.lower() and entry["username"].lower() == username.lower():
            continue  # skip this one (delete it)
        new_entries.append(entry)

    if len(new_entries) < len(entries):
        save_vault(new_entries)
        return True
    return False


# search credentials by website or username
def search_credentials(query, key):
    entries = load_vault()
    results = []

    for entry in entries:
        # check if query matches website or username (case insensitive)
        if query.lower() in entry["website"].lower() or query.lower() in entry["username"].lower():
            decrypted_password = decrypt(entry["password"], key)
            results.append({
                "website": entry["website"],
                "username": entry["username"],
                "password": decrypted_password,
                "added_on": entry.get("added_on", "N/A")
            })

    return results


# get all credentials decrypted (for export)
def get_all_decrypted(key):
    entries = load_vault()
    result = []

    for entry in entries:
        result.append({
            "website": entry["website"],
            "username": entry["username"],
            "password": decrypt(entry["password"], key),
            "added_on": entry.get("added_on", "N/A")
        })

    return result
