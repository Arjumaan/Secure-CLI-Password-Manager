import os
import csv
import string
import random


# generate a strong random password
def generate_password(length=16, use_upper=True, use_digits=True, use_symbols=True):
    # make sure password is at least 8 characters
    if length < 8:
        length = 8

    # start with lowercase letters
    characters = string.ascii_lowercase

    if use_upper:
        characters += string.ascii_uppercase
    if use_digits:
        characters += string.digits
    if use_symbols:
        characters += "!@#$%^&*()-_=+[]{}|;:,.<>?/"

    # generate the password
    password = ""
    for i in range(length):
        password += random.choice(characters)

    return password


# print the app banner
def print_banner():
    print()
    print("=" * 50)
    print("   SecureVault - CLI Password Manager")
    print("=" * 50)


# print the main menu
def print_menu():
    print()
    print("======= MAIN MENU =======")
    print("1. Add Credential")
    print("2. View Credential")
    print("3. List All Sites")
    print("4. Update Credential")
    print("5. Delete Credential")
    print("6. Search")
    print("7. Generate Strong Password")
    print("8. Export to CSV")
    print("9. Exit")
    print("==========================")


# display credentials in a nice format
def print_credentials(entries, show_password=False):
    if len(entries) == 0:
        print("No entries found.")
        return

    print()
    print(f"{'Website':<20} {'Username':<20} {'Password':<20} {'Added On':<15}")
    print("-" * 75)

    for entry in entries:
        website = entry["website"]
        username = entry["username"]
        added = entry.get("added_on", "N/A")[:10]  # just show the date part

        if show_password:
            password = entry["password"]
        else:
            password = "********"

        print(f"{website:<20} {username:<20} {password:<20} {added:<15}")

    print()


# export credentials to a csv file
def export_to_csv(entries, filepath=None):
    if filepath is None:
        data_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
        if not os.path.exists(data_dir):
            os.makedirs(data_dir)
        filepath = os.path.join(data_dir, "export.csv")

    with open(filepath, "w", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=["website", "username", "password", "added_on"])
        writer.writeheader()
        for entry in entries:
            writer.writerow(entry)

    return os.path.abspath(filepath)
