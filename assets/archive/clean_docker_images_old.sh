#!/bin/bash

#!/bin/bash

# Function to process each image
process_image() {
  local image_id=$1
  local image_name=$(docker image inspect --format '{{.RepoTags}}' "$image_id" | sed 's/\[//g; s/\]//g')

  # Generate a temporary container name
  local temp_container="temp_$image_id"

  # Create and start a container with overridden CMD and ENTRYPOINT
  docker create --name "$temp_container" --entrypoint /bin/sh "$image_id" -c "sleep 1" >/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    echo "Failed to create container from image: $image_id"
    return
  fi

  # Start the container and remove chattr
  docker start "$temp_container" >/dev/null 2>&1
  docker exec "$temp_container" rm -f /bin/chattr

  # Commit changes back to the image
  if [[ -n "$image_name" && "$image_name" != "null" ]]; then
    docker commit "$temp_container" "$image_name"
  else
    docker commit "$temp_container" "$image_id"
  fi

  # Cleanup temporary container
  docker rm -f "$temp_container" >/dev/null 2>&1

  docker rmi "$image_id"
  echo "Processed image: $image_id"
}

# Get all image IDs and process them
image_ids=$(docker image ls --quiet | sort -u)
if [[ -z "$image_ids" ]]; then
  echo "No Docker images found."
  exit 1
fi

for image_id in $image_ids; do
  process_image "$image_id"
done

echo "All images processed."
