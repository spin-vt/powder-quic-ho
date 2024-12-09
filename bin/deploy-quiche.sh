#!/bin/bash

# Exit on any error
set -e

# Function to print messages
function log {
    echo -e "\033[1;34m$1\033[0m"
}

log "Step 1: Install prerequisites"
# Install Rust and Cargo (if not already installed)
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
fi

# Install required system packages
if [ -x "$(command -v apt-get)" ]; then
    sudo apt-get update
    sudo apt-get install -y build-essential cmake pkg-config libssl-dev
elif [ -x "$(command -v dnf)" ]; then
    sudo dnf install -y gcc gcc-c++ cmake pkg-config openssl-devel
elif [ -x "$(command -v brew)" ]; then
    brew install cmake pkg-config openssl
else
    log "Unsupported package manager. Please install build tools and libssl-dev manually."
    exit 1
fi

log "Step 2: Clone the quiche repository"
# Clone the quiche repository
QUICHE_REPO_URL="https://github.com/cloudflare/quiche.git"
QUICHE_DIR="quiche"
if [ ! -d "$QUICHE_DIR" ]; then
    git clone $QUICHE_REPO_URL
else
    log "Repository already cloned. Pulling latest changes..."
    cd $QUICHE_DIR && git pull && cd ..
fi

log "Step 3: Build quiche"
# Build quiche
cd $QUICHE_DIR
cargo build --release

log "Step 4: Build successful"
echo "The quiche library has been built successfully. The compiled files are located in 'target/release/'."
