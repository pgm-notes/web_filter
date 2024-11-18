#!/bin/bash

# Get all images with no repository or tag (orphans/parents)
parent_images=$(docker image ls --filter "dangling=true" --quiet)

# Loop through each parent image
for parent_id in $parent_images; do
    # Find all child images dependent on the current parent
    child_images=$(docker image inspect --format '{{.Id}} {{.Parent}}' $(docker image ls --quiet) | grep "$parent_id" | awk '{print $1}')

    # Rebase each child image
    for child_id in $child_images; do
        repo_tag=$(docker image inspect --format '{{index .RepoTags 0}}' "$child_id")
        echo "Rebasing child image $repo_tag onto itself"
        docker tag "$child_id" "$repo_tag" # Create a new image with the same tag
    done
done

# Remove the parent images now that they are no longer referenced
for parent_id in $parent_images; do
    echo "Deleting parent image $parent_id"
    docker rmi -f "$parent_id"
done

echo "All parent images removed successfully."

