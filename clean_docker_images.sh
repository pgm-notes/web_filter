#!/bin/bash

dockerfile_template="./Dockerfile.generic"
if [[ ! -f $dockerfile_template ]]; then
  echo "Error: $dockerfile_template not found!"
  exit 1
fi

images=$(docker image ls --format "{{.Repository}}:{{.Tag}}")

for image in ${images[@]}; do
    sed "s/<image_name_and_tag>/$image/g" $dockerfile_template > ./Dockerfile.tmp
    echo "@"
    echo "$image"
    docker build -t "$image" -f ./Dockerfile.tmp .
done

docker image prune --force
rm -f Dockerfile.tmp
echo "All images have been patched."

