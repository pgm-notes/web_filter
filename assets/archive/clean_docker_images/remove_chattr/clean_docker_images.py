#!/bin/python3

import docker

def remove_chattr_from_image(client, image_id):
    try:
        # Get the image's repo tags
        image = client.images.get(image_id)
        repo_tags = image.attrs.get("RepoTags", [])
        image_name = repo_tags[0] if repo_tags else None

        # Create a temporary container
        temp_container = client.containers.create(
            image=image_id,
            command="sleep 1",
            entrypoint="/bin/sh",
            name=f"temp_{image_id[:12]}"
        )

        # Start the container
        temp_container.start()

        # Remove /bin/chattr
        try:
            temp_container.exec_run("rm -f /bin/chattr", privileged=True)
            print(f"Removed /bin/chattr from image: {image_id}")
        except Exception as e:
            print(f"Failed to remove /bin/chattr from container for image {image_id}: {e}")
            temp_container.remove(force=True)
            return

        # Commit the container back to the image
        if image_name:
            client.images.commit(temp_container.id, repository=image_name)
            print(f"Committed changes to image: {image_name}")
        else:
            client.images.commit(temp_container.id, repository=image_id)
            print(f"Committed changes to image ID: {image_id}")

        # Cleanup the temporary container
        temp_container.remove(force=True)
        print(f"Cleaned up temporary container for image: {image_id}")

    except Exception as e:
        print(f"Error processing image {image_id}: {e}")


def main():
    # Initialize Docker client
    client = docker.from_env()

    # Get all image IDs
    images = client.images.list()
    if not images:
        print("No Docker images found.")
        return

    # Process each image
    for image in images:
        image_id = image.id
        remove_chattr_from_image(client, image_id)


if __name__ == "__main__":
    main()



