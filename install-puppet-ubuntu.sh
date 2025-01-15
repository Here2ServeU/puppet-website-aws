#!/bin/bash

# Variables
PUPPET_REPO_URL="https://apt.puppet.com/puppet7-release-jammy.deb"  # Replace 'jammy' for other Ubuntu versions if needed
PUPPET_CONF="/etc/puppetlabs/puppet/puppet.conf"
PUPPET_SERVER="34.229.245.67"
CERTNAME="ubuntu-agent"
ENVIRONMENT="production"

# Step 1: Add Puppet's Official APT Repository
echo "Adding Puppet's official APT repository..."
curl -O $PUPPET_REPO_URL
sudo dpkg -i $(basename $PUPPET_REPO_URL)

# Step 2: Update Package Lists
echo "Updating package lists..."
sudo apt update

# Step 3: Install Puppet Agent
echo "Installing Puppet Agent..."
sudo apt install -y puppet-agent

# Step 4: Configure the Puppet Agent
echo "Configuring Puppet Agent..."
sudo tee $PUPPET_CONF <<EOF
[main]
server = $PUPPET_SERVER
certname = $CERTNAME
environment = $ENVIRONMENT
EOF

# Step 5: Configure Puppet Binary Path
export PATH=$PATH:/opt/puppetlabs/bin
source ~/.bashrc

# Step 6: Start and Enable Puppet Agent
echo "Starting and enabling Puppet Agent..."
sudo systemctl start puppet
sudo systemctl enable puppet

# Step 7: Sign the Certificate on the Puppet Controller
echo "Requesting certificate signing from Puppet Controller..."
echo "Run the following commands on the Puppet Controller to sign the certificate:"
echo "  sudo puppetserver ca list"
echo "  sudo puppetserver ca sign --certname $CERTNAME"

# Step 8: Verify the Puppet Agent Configuration
echo "Verifying Puppet Agent configuration..."
sudo puppet agent --test

echo "Puppet Agent setup on Ubuntu is complete. Verify that the agent has applied configurations correctly."