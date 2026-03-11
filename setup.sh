#!/bin/bash

set -e

echo "Starting VM bootstrap setup..."

# Update system
echo "Updating packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Install basic tools
echo "Installing basic packages..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    jq \
    vim \
    net-tools \
    ca-certificates \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common

# -------------------------------
# Install Docker
# -------------------------------
echo "Installing Docker..."

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker $USER

echo "Docker installed"

# -------------------------------
# Install kubectl
# -------------------------------
echo "Installing kubectl..."

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl
sudo mv kubectl /usr/local/bin/

echo "kubectl installed"

# -------------------------------
# Install Helm
# -------------------------------
echo "Installing Helm..."

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "Helm installed"

# -------------------------------
# Install Terraform
# -------------------------------
echo "Installing Terraform..."

wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com \
$(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update

sudo apt-get install -y terraform

echo "Terraform installed"

# -------------------------------
# Install AWS CLI
# -------------------------------
echo "Installing AWS CLI..."

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

unzip awscliv2.zip
sudo ./aws/install

echo "AWS CLI installed"

# -------------------------------
# Install Azure CLI
# -------------------------------
echo "Installing Azure CLI..."

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo "Azure CLI installed"

# -------------------------------
# Install Node Exporter
# -------------------------------
echo "Installing Node Exporter..."

cd /tmp

NODE_EXPORTER_VERSION="1.7.0"

wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

tar xvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/

sudo useradd --no-create-home --shell /bin/false node_exporter || true

cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

echo "Node Exporter installed."

# -------------------------------
# Cleanup
# -------------------------------
rm -rf /tmp/aws*
rm -rf /tmp/node_exporter*

echo "Bootstrap setup completed successfully!"
