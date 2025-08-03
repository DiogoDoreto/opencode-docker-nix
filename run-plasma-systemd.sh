#!/usr/bin/env sh

CONTAINER_NAME=opencode-plasma-systemd

if podman container exists "$CONTAINER_NAME"; then
    echo "Container '$CONTAINER_NAME' already exists."
    printf "Do you want to (r)euse the existing container or destroy and create a (n)ew one? [reuse/new]: "
    read choice
    case "$choice" in
        reuse|r)
            podman start -ai "$CONTAINER_NAME"
            exit $?
            ;;
        new|n)
            echo "Removing '$CONTAINER_NAME'..."
            podman rm -f "$CONTAINER_NAME"
            ;;
        *)
            echo "Invalid option. Exiting."
            exit 1
            ;;
    esac
fi

echo "Creating '$CONTAINER_NAME'..."
podman run -it \
    --name "$CONTAINER_NAME" \
    -v /home/dog/projects/opencode-docker/contexts/global/.config/opencode/:/root/.config/opencode:rw \
    -v /home/dog/projects/opencode-docker/contexts/plasma-systemd/.local/:/root/.local:rw \
    -v /home/dog/projects/plasma-systemd-widget/:/app:rw \
    -p 8080:8080 \
    opencode opencode .
