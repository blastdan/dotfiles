#!/bin/bash

set -e

# Update the package list
sudo apt update

# Install necessary packages
sudo apt install -y apt-transport-https ca-certificates curl gnupg

# Add the Google Cloud public key to the keyring
if ! [ -d /usr/share/keyrings ]; then
  sudo mkdir -p /usr/share/keyrings
fi
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

# Add the Google Cloud CLI repository
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

# Update and install Google Cloud CLI
sudo apt update
sudo apt install -y google-cloud-cli

# Optional: Install additional components
sudo apt install -y google-cloud-cli-gke-gcloud-auth-plugin google-cloud-cli-kubectl-oidc kubectl

# Verify installation
gcloud --version

# Authenticate with Google Cloud
# Uncomment the line below to authenticate immediately
# gcloud auth login

# Final message
echo "Google Cloud CLI installation complete."
