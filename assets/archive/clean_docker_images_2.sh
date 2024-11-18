#!/bin/bash

# Get the IDs of all images
image_ids=$(docker image ls --quiet)

for image_id in $image_ids; do
#  # Get the repo and tag for the image (if any)
#  repo_tag=$(docker image inspect --format '{{index .RepoTags 0}}' "$image_id")

#   # Skip images without tags (dangling or intermediate images)
#   if [[ -z "$repo_tag" ]]; then
#     echo "Skipping image $image_id (no tag)"
#     continue
#   fi

  # Create a temporary container
  echo "1"
  temp_container=$(docker create --entrypoint "/bin/sleep 8" "$image_id")


  # Check if /bin/chattr exists in the container
  echo "2"
  # Pipe to >/dev/null if these logs become tedious
  docker start "$temp_container"
  if ! docker exec "$temp_container" test -f /bin/chattr; then
    echo "Skipping image $repo_tag (no /bin/chattr found)"
    echo "2A-1"
    docker rm -f "$temp_container" >/dev/null
    echo "2A-2"
    continue
  fi

  echo "Processing image $repo_tag (removing /bin/chattr)"

  echo "2B-1"
  # Remove /bin/chattr from the temporary container
  docker exec "$temp_container" rm -f /bin/chattr

  echo "2B-2"
  # Commit the container back to the original image name
  docker commit "$temp_container" "$repo_tag"

  echo "2B-3"
  # Remove the temporary container
  docker rm -f "$temp_container"

  echo "2B-4"
  # Remove the old image
  docker image rm "$image_id"

  echo "Updated image $repo_tag"
done

echo "All images processed!"
