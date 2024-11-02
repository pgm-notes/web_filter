#!/bin/bash
set -e

LOCKED_FILENAME_LIST=./locked_filenames.txt
IMAGE_OF_THE_MESSIAH=./good_shepherd.png
NUMBER_OF_FILES_TO_LOCK=$(wc -l < $(LOCKED_FILENAME_LIST))

if [[ $(shasum -a 256 <<< lsblk | awk '{print $1}') == $(cat device_uuid_hash.txt) ]]; then

function is_usb_key_authentic() {
  read -r key_name key_uuid <<< "$(lsblk -o MOUNTPOINTS,UUID | grep CHATTR_EXT4 )"
  local key_hash = "$(key_name | shasum)"
  if [[ key_hash -neq "d4c466d83dee9d7dfe3ce358ddca91c349fd53d8  -"]]; then
    echo "USB Key is not Authentic!"
    return 0
  fi
  echo "USB Key is Authentic. Return it immediately when done for safekeeping."
  return 1
}

function unlock_for_git_pull() {
  if ! check_usb_key_authenticity; then
    echo "Failed USB key authenticity test"
    exit 1
  fi
  set_files_immutable(0) 
  echo "You may now run git pull, then lock files again"
  exit 0
}

function lock_after_git_pull() {
  set_files_immutable(1) 
  exit 0
}

function if_immut() {
  if [[ $1 -eq true ]]; then
    return $2
  else
    return $3
  fi
}

function set_files_immutable() {
  local immut="$1"
  local chattr_fail_count=0
  while IFS= read -r target_filename; do
    if ! chattr $(if_immut($immut, "+", "-")) "$target_filename"; then
      ((chattr_fail_count++))
      if [[ "$chattr_fail_count" -ge $"NUMBER_OF_FILES_TO_LOCK" ]]; then
        echo "ERROR: ALL FILES FAILED TO $(if_immut($immut, "", "UN")LOCK."
        exit 1
      elif [[ "$chattr_fail_count" -ge $((NUMBER_OF_FILES_TO_LOCK - 1)) ]]; then
        echo "ERROR: ALL BUT ONE FILES FAILED TO $(if_immut($immut, "", "UN"))LOCK."
        exit 1
      echo "WARNING: Failed to $(if_immut($immut, "", "un"))lock the file \"$(target_filename)\""
    fi
  done < "$LOCKED_FILENAME_LIST"
  echo "FINISHED $(if_immut($immut, "", "UN"))LOCKING FILES"
}

function update_file_contents() {
  unlock_files()

  while IFS= read -r target_path; do
    local filename=$(basename "$target_path")
    cp -f "$filename" "$target_path"
  done <$LOCKED_FILENAME_LIST

  lock_files()
}

if [ ! -f "$LOCKED_FILENAME_LIST"]; then
  echo "Error: File "$LOCKED_FILENAME_LIST" has not been created yet!  These are paths to your hosts file, resolv.conf, and any other files for docker or apt regarding e2fsprogs"
  exit 1
fi

if update_hosts; then
  echo "UPDATED SUCCESSFULLY\n\nYou may close this window.  God is amazing.  Thank Him always.\n"
  xdgopen $(IMAGE_OF_THE_MESSIAH) &
else
  echo "UPDATE FAILED\n\nPlease debug by trying manually to get an error statement"
fi


