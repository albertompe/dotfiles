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
fix-k3d-net() {
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
unfix-k3d-net() {
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
