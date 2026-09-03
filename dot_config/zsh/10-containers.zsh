# Container engine switching
_CE_STATE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/container-engine"
DOCKER_SOCK="unix:///var/run/docker.sock"
PODMAN_SOCK="unix:///run/user/$(id -u)/podman/podman.sock"

ce() {
    case "${1:-}" in
    docker|podman)
        CONTAINER_ENGINE="$1"
        [ "$1" = "docker" ] && export DOCKER_HOST="$DOCKER_SOCK" || export DOCKER_HOST="$PODMAN_SOCK"
        echo "$CONTAINER_ENGINE" > "$_CE_STATE_FILE"
        echo "Engine: $CONTAINER_ENGINE"
        ;;
    "")
        echo "Engine: $CONTAINER_ENGINE"
        ;;
    *)
        echo "Usage: ce [docker|podman]"
        ;;
    esac
}

CONTAINER_ENGINE="$(cat "$_CE_STATE_FILE" 2>/dev/null || echo docker)"
[ "$CONTAINER_ENGINE" = "docker" ] && export DOCKER_HOST="$DOCKER_SOCK" || export DOCKER_HOST="$PODMAN_SOCK"

# Container services management
docker-start()   { sudo systemctl start docker.service docker.socket;   echo "Docker started"; }
docker-stop()    { sudo systemctl stop docker.service docker.socket;    echo "Docker stopped"; }
docker-enable()  { sudo systemctl enable --now docker.service docker.socket; echo "Docker enabled on boot"; }
docker-disable() { sudo systemctl disable --now docker.service docker.socket; echo "Docker disabled on boot"; }
docker-status()  { echo "active:   $(systemctl is-active docker.service)"; echo "enabled:  $(systemctl is-enabled docker.service)"; }

podman-start()   { systemctl --user start podman.socket;  echo "Podman socket started"; }
podman-stop()    { systemctl --user stop podman.socket;   echo "Podman socket stopped"; }
podman-enable()  { systemctl --user enable --now podman.socket; echo "Podman socket enabled"; }
podman-disable() { systemctl --user disable --now podman.socket; echo "Podman socket disabled"; }
podman-status()  { echo "active:   $(systemctl --user is-active podman.socket)"; echo "enabled:  $(systemctl --user is-enabled podman.socket)"; }

cstatus() {
    echo "Docker:"
    docker-status | sed 's/^/    /'
    echo "Podman socket:"
    podman-status | sed 's/^/    /'
    echo "Engine:        $CONTAINER_ENGINE"
}
