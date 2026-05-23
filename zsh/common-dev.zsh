# Create a k3d cluster on the host network with a local registry
k3d-cluster-setup() {
    local CLUSTER_NAME="${1:-k3s-default}"
    local REGISTRY_NAME="registry.localhost"
    local REGISTRY_FULL="k3d-${REGISTRY_NAME}"
    local PORT="5005"
    local TMP_CONFIG="/tmp/k3d-registries-${CLUSTER_NAME}.yaml"

    echo "🚀 Starting K3d host network environment..."

    # 1. Validate or create the local registry
    if k3d registry list "$REGISTRY_FULL" &>/dev/null; then
        echo "ℹ️  Registry '$REGISTRY_FULL' already exists."
    else
        echo "📦 Creating registry '$REGISTRY_NAME' on port $PORT..."
        k3d registry create "$REGISTRY_NAME" --port "$PORT" || return 1
    fi

    # 2. Generate valid K3s native registries.yaml
    echo "📝 Generating valid registry configuration..."
    cat <<EOF >"$TMP_CONFIG"
mirrors:
  "${REGISTRY_FULL}:${PORT}":
    endpoint:
      - "http://${REGISTRY_FULL}:${PORT}"
EOF

    # 3. Create the K3d cluster
    echo "🏗️  Creating cluster '$CLUSTER_NAME' on the host network..."
    k3d cluster create "$CLUSTER_NAME" \
        --network host \
        --k3s-arg "--flannel-backend=host-gw@server:0" \
        --registry-config "$TMP_CONFIG"

    # 4. Clean up the temporary file
    rm -f "$TMP_CONFIG"
}

# Delete a k3d cluster and the associated local registry
k3d-cluster-cleanup() {
    local CLUSTER_NAME="${1:-k3s-default}"
    local REGISTRY_NAME="registry.localhost"
    local REGISTRY_FULL="k3d-${REGISTRY_NAME}"

    echo "🗑️  Cleaning up K3d host environment..."

    # 1. Delete the K3d cluster
    if k3d cluster list "$CLUSTER_NAME" &>/dev/null; then
        echo "🏗️  Deleting cluster '$CLUSTER_NAME'..."
        k3d cluster delete "$CLUSTER_NAME"
    else
        echo "ℹ️  Cluster '$CLUSTER_NAME' not found. Skipping."
    fi

    # 2. Delete the local registry
    if k3d registry list "$REGISTRY_FULL" &>/dev/null; then
        echo "📦 Deleting registry '$REGISTRY_FULL'..."
        k3d registry delete "$REGISTRY_FULL"
    else
        echo "ℹ️  Registry '$REGISTRY_FULL' not found. Skipping."
    fi

    echo "✅ Cleanup complete!"
}

# Deploy a container to explore local registry images.
# If the container is already deployed it will be replaced.
# Usage:
#   registry-ui-deploy              Create the container accessing registry on port 5005 exposing the ui in port 8080
#   registry-ui-deploy 5000         Create the container accessing registry on port 5000 exposing the ui in port 8080
#   registry-ui-deploy 5000 8081    Create the container accessing registry on port 5000 exposing the ui in port 8081
registry-ui-setup() {
    local REGISTRY_PORT="${1:-5005}" # First parameter: Registry port (default 5005)
    local UI_PORT="${2:-8080}"       # Second parameter: UI port (default 8080)

    echo "Desplegando Docker Registry UI..."
    echo "- Conectando al registry en puerto: ${REGISTRY_PORT}"
    echo "- Exponiendo la UI en puerto: ${UI_PORT}"

    # Stop and delete the container if already created.
    docker rm -f registry-ui 2>/dev/null

    docker run -d \
        -p "${UI_PORT}:80" \
        -e NGINX_PROXY_PASS_URL=http://host.docker.internal:${REGISTRY_PORT} \
        -e SINGLE_REGISTRY=true \
        --name registry-ui \
        joxit/docker-registry-ui:main

    echo "✅ UI disponible en: http://localhost:${UI_PORT}"
}

# Removes the container with the ui to explore local registry.
registry-ui-cleanup() {
    echo "Limpiando contenedor registry-ui..."
    docker rm -f registry-ui 2>/dev/null &&
        echo "✅ Contenedor registry-ui eliminado." ||
        echo "ℹ️  El contenedor registry-ui no estaba presente."
}
