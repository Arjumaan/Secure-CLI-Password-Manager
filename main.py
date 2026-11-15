import sys
import getpass
from auth import is_first_launch, setup_master_password, verify_master_password
from vault import add_credential, view_credential, list_all, update_credential, delete_credential, search_credentials, get_all_decrypted
from utils import generate_password, print_banner, print_menu, print_credentials, export_to_csv


# --- option 1: add a new credential ---
def handle_add(key):
    print("\n--- Add New Credential ---")
    website = input("Enter website: ").strip()
    if website == "":
        print("Website cannot be empty!")
        return

    username = input("Enter username: ").strip()
    if username == "":
        print("Username cannot be empty!")
        return

    password = getpass.getpass("Enter password (or press Enter to auto-generate): ")

    if password == "":
        password = generate_password()
        print(f"Generated password: {password}")

    success = add_credential(website, username, password, key)
    if success:
        print(f"\nCredential for {website} saved successfully!")


# --- option 2: view a credential ---
def handle_view(key):
    print("\n--- View Credential ---")
    website = input("Enter website name: ").strip()
    if website == "":
        print("Website cannot be empty!")
        return

    results = view_credential(website, key)
    if len(results) > 0:
        print_credentials(results, show_password=True)
    else:
        print(f"No credentials found for '{website}'.")


# --- option 3: list all ---
def handle_list():
    print("\n--- All Stored Credentials ---")
    entries = list_all()
    if len(entries) > 0:
        print_credentials(entries, show_password=False)
    else:
        print("Your vault is empty!")


# --- option 4: update a credential ---
def handle_update(key):
    print("\n--- Update Credential ---")
    website = input("Enter website to update: ").strip()
    username = input("Enter current username: ").strip()

    if website == "" or username == "":
        print("Website and username are required!")
        return

    new_username = input("New username (press Enter to keep current): ").strip()
    new_password = getpass.getpass("New password (press Enter to keep current): ")

    # if both are empty, nothing to update
    if new_username == "" and new_password == "":
        print("Nothing to update!")
        return

    # pass None if empty so the function knows not to change it
    if new_username == "":
        new_username = None
    if new_password == "":
        new_password = None

    result = update_credential(website, username, new_username, new_password, key)
    if result:
        print(f"\nCredential for {website} updated!")
    else:
        print(f"\nNo matching credential found for {website} / {username}.")


# --- option 5: delete a credential ---
def handle_delete():
    print("\n--- Delete Credential ---")
    website = input("Enter website to delete: ").strip()
    username = input("Enter username: ").strip()

    if website == "" or username == "":
        print("Website and username are required!")
        return

    # ask for confirmation
    confirm = input(f"Are you sure you want to delete {username}@{website}? (y/n): ").strip().lower()
    if confirm != "y":
        print("Cancelled.")
        return

    result = delete_credential(website, username)
    if result:
        print(f"\nCredential for {website} deleted!")
    else:
        print("No matching credential found.")


# --- option 6: search ---
def handle_search(key):
    print("\n--- Search Credentials ---")
    query = input("Enter search query: ").strip()
    if query == "":
        print("Query cannot be empty!")
        return

    results = search_credentials(query, key)
    if len(results) > 0:
        print(f"Found {len(results)} result(s):")
        print_credentials(results, show_password=True)
    else:
        print(f"No results found for '{query}'.")


# --- option 7: generate password ---
def handle_generate():
    print("\n--- Password Generator ---")

    length_input = input("Password length (default 16): ").strip()
    if length_input == "":
        length = 16
    else:
        try:
            length = int(length_input)
        except ValueError:
            print("Invalid number, using default 16.")
            length = 16

    upper = input("Include uppercase letters? (Y/n): ").strip().lower()
    digits = input("Include digits? (Y/n): ").strip().lower()
    symbols = input("Include symbols? (Y/n): ").strip().lower()

    use_upper = upper != "n"
    use_digits = digits != "n"
    use_symbols = symbols != "n"

    password = generate_password(length, use_upper, use_digits, use_symbols)
    print(f"\nGenerated password: {password}\n")


# --- option 8: export to csv ---
def handle_export(key):
    print("\n--- Export to CSV ---")
    print("WARNING: The exported file will contain UNENCRYPTED passwords!")
    confirm = input("Do you want to proceed? (y/n): ").strip().lower()

    if confirm != "y":
        print("Cancelled.")
        return

    entries = get_all_decrypted(key)
    if len(entries) == 0:
        print("Vault is empty, nothing to export!")
        return

    path = export_to_csv(entries)
    print(f"\nExported {len(entries)} credential(s) to: {path}\n")


# --- main function ---
def main():
    print_banner()

    # check if first time or returning user
    if is_first_launch():
        key = setup_master_password()
    else:
        key = verify_master_password()
        if key is None:
            sys.exit(1)

    # main menu loop
    while True:
        print_menu()
        choice = input("Choice: ").strip()

        if choice == "1":
            handle_add(key)
        elif choice == "2":
            handle_view(key)
        elif choice == "3":
            handle_list()
        elif choice == "4":
            handle_update(key)
        elif choice == "5":
            handle_delete()
        elif choice == "6":
            handle_search(key)
        elif choice == "7":
            handle_generate()
        elif choice == "8":
            handle_export(key)
        elif choice == "9":
            print("\nGoodbye! Stay secure.\n")
            break
        else:
            print("Invalid choice! Please enter a number between 1 and 9.")


if __name__ == "__main__":
    main()
