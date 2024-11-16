#!/usr/bin/python3

import hashlib

def check_password():
    password = input("Enter password: ")
    hash_file = 'password_hash.txt'

    with open(hash_file, 'r') as f:
        stored_hash = f.read().strip()

    hashed_password = hashlib.sha256(password.encode()).hexdigest()

    if hashed_password == stored_hash:
        print("Password is correct.")
        return True
    else:
        print("Password is incorrect.")
        return False

def main():
    if check_password():
        

if __name__ = "__main__":
    main()

