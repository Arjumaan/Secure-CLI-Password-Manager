import os
import base64
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes


# generate a random salt (16 bytes)
def generate_salt():
    return os.urandom(16)


# this function takes the master password and salt,
# and creates an encryption key using PBKDF2
def derive_key(master_password, salt):
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=480000,
    )
    # we need to encode the password to bytes first
    key = base64.urlsafe_b64encode(kdf.derive(master_password.encode()))
    return key


# encrypt a plain text string using the key
def encrypt(text, key):
    f = Fernet(key)
    encrypted = f.encrypt(text.encode())
    return encrypted.decode()  # convert bytes back to string for storage


# decrypt an encrypted string back to plain text
def decrypt(encrypted_text, key):
    f = Fernet(key)
    decrypted = f.decrypt(encrypted_text.encode())
    return decrypted.decode()
