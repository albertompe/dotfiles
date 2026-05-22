# macOS specific settings

# Update system tools function
system-update() {
  echo "🛠️ Updating system tools..."
  echo "🔄 Updating brew tools and casks..."
  brew update && brew upgrade
  brew upgrade --cask --greedy
  echo "✅ brew updated!"
  zinit-update
  mise-update
  krew-plugins-update
  echo "🎉 Everything's fresh and clean!"
}

# Homebrew installed tools manpages
export MANPATH="$MANPATH:$(brew --prefix)/share/man:$HOME/.local/share/mise/installs/**/share/man"

# ==============================================================================
# DESCRIPTION: K3D Pod Network Router for Rancher Desktop (macOS)
#
# Create the cluster using:
#
# k3d cluster create k3s-default \
#   --network host \
#   --k3s-arg "--flannel-backend=host-gw@server:0"
# ==============================================================================
k3d-fix-net() {
    echo "🔍 Detecting Rancher Desktop VM IP..."
    local vm_ip=$(rdctl shell ip -4 addr show rd1 | awk '/inet / {print $2}' | cut -d/ -f1)

    if [ -z "$vm_ip" ]; then
        echo "❌ Error: Could not detect the rd1 interface. Is Rancher Desktop running?"
        return 1
    fi

    echo "✅ VM IP found: $vm_ip. Setting up macOS routing..."
    sudo route -n delete -net 10.42.0.0/16 2>/dev/null
    sudo route -n add -net 10.42.0.0/16 "$vm_ip"

    echo "⚙️ Configuring VM Kernel parameters (sysctl)..."
    rdctl shell sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null
    rdctl shell sudo sysctl -w net.ipv4.conf.all.rp_filter=0 > /dev/null
    rdctl shell sudo sysctl -w net.ipv4.conf.default.rp_filter=0 > /dev/null
    rdctl shell sudo sysctl -w net.ipv4.conf.rd1.rp_filter=0 > /dev/null

    echo "🛡️ Updating VM Firewall rules (iptables & NAT)..."
    rdctl shell sudo iptables -P FORWARD ACCEPT > /dev/null
    # FIXED: Added explicit source and specific comment to match the unfix script
    rdctl shell sudo iptables -t nat -A POSTROUTING -s 192.168.205.0/24 -j MASQUERADE -m comment --comment "k3d-mac-routing" > /dev/null

    echo "🎉 Network setup complete! You can now connect to your k3d pods directly by IP."
}

# ==============================================================================
# DESCRIPTION: K3D Pod Network Unrouter / Cleaner (macOS)
# ==============================================================================
k3d-unfix-net() {
    echo "🔍 Detecting Rancher Desktop VM IP for cleanup..."
    local vm_ip=$(rdctl shell ip -4 addr show rd1 | awk '/inet / {print $2}' | cut -d/ -f1)

    if [ -z "$vm_ip" ]; then
        echo "⚠️ Warning: Could not detect rd1 interface. Forcing macOS route deletion anyway..."
    fi

    echo "🧹 Removing macOS static route for K3s pods..."
    sudo route -n delete -net 10.42.0.0/16 2>/dev/null

    echo "⚙️ Restoring VM Kernel parameters to defaults (sysctl)..."
    # FIXED: Re-enabling forwarding only for the local loopback so k3d internal API communication stays alive
    rdctl shell sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null
    rdctl shell sudo sysctl -w net.ipv4.conf.all.rp_filter=1 > /dev/null
    rdctl shell sudo sysctl -w net.ipv4.conf.default.rp_filter=1 > /dev/null
    rdctl shell sudo sysctl -w net.ipv4.conf.rd1.rp_filter=1 > /dev/null

    echo "🛡️ Safely removing custom VM Firewall rules (iptables)..."
    # FIXED: Deletes explicitly our custom rule, leaving Docker's rules completely untouched
    rdctl shell sudo iptables -t nat -D POSTROUTING -s 192.168.205.0/24 -j MASQUERADE -m comment --comment "k3d-mac-routing" 2>/dev/null

    echo "🎉 Cleanup complete! All network configurations have been reverted safely."
}

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
  cat <<EOF > "$TMP_CONFIG"
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
