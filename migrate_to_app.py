import os
import json
import base64
import shutil

"""
Migration Script: SecureVault CLI -> SecureVault Flutter App
Exports the CLI vault into the Flutter application's local vault data format.
"""

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CLI_DATA_DIR = os.path.join(BASE_DIR, "data")
CLI_VAULT = os.path.join(CLI_DATA_DIR, "vault.json")
CLI_CONFIG = os.path.join(CLI_DATA_DIR, "config.json")

# Windows AppData target directory
APPDATA_DIR = os.environ.get("APPDATA", os.path.expanduser("~"))
APP_STORAGE_DIR = os.path.join(APPDATA_DIR, "SecureVault")


def migrate():
    print("=" * 50)
    print(" SecureVault: CLI -> App Migration Tool")
    print("=" * 50)

    if not os.path.exists(CLI_CONFIG):
        print("[-] No CLI configuration found in data/config.json.")
        return

    os.makedirs(APP_STORAGE_DIR, exist_ok=True)
    target_config = os.path.join(APP_STORAGE_DIR, "config.json")
    target_vault = os.path.join(APP_STORAGE_DIR, "vault_data.json")

    # Copy config
    shutil.copyfile(CLI_CONFIG, target_config)
    print(f"[+] Migrated master configuration to: {target_config}")

    if os.path.exists(CLI_VAULT):
        with open(CLI_VAULT, "r") as f:
            cli_entries = json.load(f)

        app_entries = []
        for idx, entry in enumerate(cli_entries):
            app_entries.append({
                "id": f"cli-import-{idx + 1}",
                "website": entry.get("website", ""),
                "username": entry.get("username", ""),
                "encryptedPassword": entry.get("password", ""),
                "encryptedNotes": None,
                "updatedAt": entry.get("added_on", "2026-01-01T00:00:00.000Z"),
                "isDeleted": False
            })

        with open(target_vault, "w") as f:
            json.dump(app_entries, f, indent=2)

        print(f"[+] Migrated {len(app_entries)} credential(s) to: {target_vault}")

    print("\n[✔] Migration complete! The Flutter app will now load these credentials.")


if __name__ == "__main__":
    migrate()
