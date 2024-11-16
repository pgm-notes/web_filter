#!/bin/bash

# Get the IDs of all images
image_ids=$(docker image ls --quiet)

for image_id in $image_ids; do
  # Get the repo and tag for the image (if any)
  repo_tag=$(docker image inspect --format '{{index .RepoTags 0}}' "$image_id")

  # Skip images without tags (dangling or intermediate images)
  if [[ -z "$repo_tag" ]]; then
    echo "Skipping image $image_id (no tag)"
    continue
  fi

  # Create a temporary container
  temp_container=$(docker create --entrypoint "" "$image_id" /bin/sh)

  # Check if /bin/chattr exists in the container
  docker start "$temp_container" >/dev/null
  if ! docker exec "$temp_container" test -f /bin/chattr; then
    echo "Skipping image $repo_tag (no /bin/chattr found)"
    docker rm -f "$temp_container" >/dev/null
    continue
  fi

  echo "Processing image $repo_tag (removing /bin/chattr)"

  # Remove /bin/chattr from the temporary container
  docker exec "$temp_container" rm -f /bin/chattr

  # Commit the container back to the original image name
  docker commit "$temp_container" "$repo_tag" >/dev/null

  # Remove the temporary container
  docker rm -f "$temp_container" >/dev/null

  # Remove the old image
  docker image rm "$image_id" >/dev/null

  echo "Updated image $repo_tag"
done

echo "All images processed!"
