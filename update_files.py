#!/usr/bin/python3

import argparse
import subprocess
import hashlib
import os
import shutil

LOCKED_FILENAME_LIST = './locked_filenames.txt'
CHATTR = './assets/chattr'
DEVICE_UUID_HASH_FILE = './assets/device_uuid_hash.txt'
SCRIPT_PATH = os.path.realpath(__file__)  # Absolute path to the current script
ASCII_ART_OF_MESSIAH = """
                |
            \       /
              .---.
         '-.  |   |  .-'
           ___|   |___
      -=  [           ]  =-
          `---.   .---'
       __||__ |   | __||__
       '-..-' |   | '-..-'
         ||   |   |   ||
         ||_.-|   |-,_||
       .-"`   `"`'`   `"-.
     .'                   '.
"""

def get_number_of_files_to_lock():
    with open(LOCKED_FILENAME_LIST, 'r') as file:
        return sum(1 for _ in file)


def is_usb_key_authentic():
    try:
        output = subprocess.check_output("lsblk -o MOUNTPOINTS,UUID | grep CHATTR_EXT4", shell=True)
        key_name, key_uuid = output.decode().strip().split()
        key_hash = hashlib.sha256(key_name.encode()).hexdigest()
        if key_hash != "a89d81f75e8d0d25c234a2634b99d4f582a5e1e58f5a21d333161879fe66fb03":
            print("USB Key is not Authentic!")
            return False

        print("USB Key is Authentic. Return it immediately when done for safekeeping.")
        return True
    except Exception as e:
        print(f"Error checking USB key authenticity: {e}")
        return False


def set_files_immutable(immutable=True):
    chattr_fail_count = 0
    mode = '+' if immutable else '-'
    number_of_files_to_lock = get_number_of_files_to_lock()

    with open(LOCKED_FILENAME_LIST, 'r') as file:
        for target_filename in file:
            target_filename = target_filename.strip()
            try:
                subprocess.run(['sudo', CHATTR, f"{mode}i", target_filename], check=True)
            except subprocess.CalledProcessError:
                chattr_fail_count += 1
                print(f"WARNING: Failed to {'lock' if immutable else 'unlock'} file \"{target_filename}\"")

    if chattr_fail_count >= number_of_files_to_lock:
        print(f"ERROR: ALL FILES FAILED TO {'LOCK' if immutable else 'UNLOCK'}")
        exit(1)
    elif chattr_fail_count >= number_of_files_to_lock - 1:
        print(f"ERROR: ALL BUT ONE FILES FAILED TO {'LOCK' if immutable else 'UNLOCK'}")
        exit(1)

    print(f"FINISHED {'LOCKING' if immutable else 'UNLOCKING'} FILES")


def update_file_contents():

    # Check USB Authenticity
    print("Checking USB key authenticity")
    if not is_usb_key_authentic():
        print("ERROR: Failed USB key authenticity test")
        exit(1)

    # Git Pull
    initial_checksum = hashlib.sha256(open(SCRIPT_PATH, 'rb').read()).hexdigest()
    print("Running git pull...")
    git_pull_output = subprocess.run(["git", "pull"], check=True, capture_output=True, text=True)
    updated_checksum = hashlib.sha256(open(SCRIPT_PATH, 'rb').read()).hexdigest()

    if updated_checksum != initial_checksum:
        print("WARNING: Script updated during git pull. Please re-run the script.")
        sys.exit(0)  # Exit to avoid inconsistent state
    if "Already up to date." in git_pull_output.stdout:
        print("USB Key repo already up to date. Proceeding to update local files.")
    else:
        print("Git pull complete. Proceeding to update local files.")

    # Update files
    set_files_immutable(False)
    with open(LOCKED_FILENAME_LIST, 'r') as file:
        for target_path in file:
            target_path = target_path.strip()
            git_copy_filename = "./locked_file_contents/" + os.path.basename(target_path)
            subprocess.run(['sudo', 'cp', git_copy_filename, target_path])
    set_files_immutable(True)
    return True


def main():

    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        '--update', 
        dest = 'update_files',
        action = 'store_true', 
        help = 'This pulls the latest repo files and updates local copies, leaving files locked afterward',
    )
    group.add_argument(
        '--check-usb-key',
        dest = 'check_usb_key',
        action = 'store_true', 
        help='Ensures the authentic USB key is inserted to run privileged softrware like docker',
    )
    
    args = parser.parse_args()
    if args.check_usb_key:
        if not is_usb_key_authentic():
            print("ERROR: Authentic USB Key is not found")
            exit(1)
        exit(0)

    elif args.update_files:
        if not os.path.isfile(LOCKED_FILENAME_LIST):
            print(f"Error: File \"{LOCKED_FILENAME_LIST}\" has not been created yet! "
                "These are paths to your hosts file, resolv.conf, and any other files "
                "for docker or apt regarding e2fsprogs")
            exit(1)

        if update_file_contents():
            print("UPDATED SUCCESSFULLY\n\nYou may close this window. God is amazing. Thank Him always.\n")
            print(ASCII_ART_OF_MESSIAH)
            exit(0)
        else:
            print("UPDATE FAILED\n\nPlease debug by trying manually to get an error statement")
            exit(1)

            
if __name__ == "__main__":
    main()

