Here’s a step-by-step guide to set up Puppet Server and Puppet Agent on Ubuntu EC2 instances, configure the necessary files, and deploy a website using Puppet.

---
## Step 1: Prerequisites
1.	Launch two EC2 instances:
	•	Puppet Server: Ubuntu 22.04
	•	Puppet Agent: Ubuntu 22.04

2.	Ensure Security Group Rules:
	•	Allow inbound SSH (port 22).
  •	Allow inbound HTTP (port 80).
	•	Allow inbound Puppet traffic (port 8140).

## Step 2: Install Puppet Server on the Controller Node

### 1. Update and install prerequisites

sudo apt update && sudo apt upgrade -y
sudo apt install wget -y

2. Add Puppet repository

wget https://apt.puppet.com/puppet8-release-jammy.deb
sudo dpkg -i puppet8-release-jammy.deb
sudo apt update

3. Install Puppet Server

sudo apt install -y puppetserver

4. Configure Puppet Server

Edit the Puppet Server configuration file:

sudo nano /etc/puppetlabs/puppet/puppet.conf

Add or modify the following under [main]:

[main]
certname = puppet-server
dns_alt_names = puppet,puppet-server
environment = production
runinterval = 1h

5. Set up Java memory allocation

Update the Java heap size for better performance:

sudo nano /etc/default/puppetserver

Set:

JAVA_ARGS="-Xms512m -Xmx512m"

6. Start and enable Puppet Server

sudo systemctl start puppetserver
sudo systemctl enable puppetserver
sudo systemctl status puppetserver

Step 3: Install Puppet Agent on the Client Node

1. Update and install prerequisites

sudo apt update && sudo apt upgrade -y
sudo apt install wget -y

2. Add Puppet repository

wget https://apt.puppet.com/puppet8-release-jammy.deb
sudo dpkg -i puppet8-release-jammy.deb
sudo apt update

3. Install Puppet Agent

sudo apt install -y puppet-agent

4. Configure Puppet Agent

Edit the Puppet Agent configuration file:

sudo nano /etc/puppetlabs/puppet/puppet.conf

Add or modify the following under [main]:

[main]
server = puppet-server
certname = puppet-agent
environment = production
runinterval = 1h

5. Start and enable Puppet Agent

sudo systemctl start puppet
sudo systemctl enable puppet
sudo systemctl status puppet

Step 4: Configure /etc/hosts and /etc/hostname

On Both Nodes:

Edit /etc/hosts:

sudo nano /etc/hosts

Add entries for both the Puppet Server and Agent:

98.82.188.197 puppet puppet-server
98.84.99.140 puppet-agent

Update /etc/hostname:

sudo nano /etc/hostname

Set the hostname to match the certname in the Puppet configuration:
	•	On Puppet Server: puppet-server
	•	On Puppet Agent: puppet-agent

Apply changes:

sudo hostnamectl set-hostname <hostname>

Step 5: Establish Connection Between Server and Agent

1. Test Puppet Agent

On the agent, request a certificate:

sudo /opt/puppetlabs/bin/puppet agent --test

2. Sign the certificate on the Puppet Server

On the server:

sudo /opt/puppetlabs/bin/puppetserver ca list
sudo /opt/puppetlabs/bin/puppetserver ca sign --certname puppet-agent

3. Re-run the agent to apply configurations

On the agent:

sudo /opt/puppetlabs/bin/puppet agent --test

Step 6: Create Manifest to Install Nginx and Deploy the Website

1. Create directories for Puppet manifest and files

On the Puppet Server:

sudo mkdir -p /etc/puppetlabs/code/environments/production/modules/webapp/{manifests,files}

2. Copy index.html to the module files directory

sudo cp webdata/index.html /etc/puppetlabs/code/environments/production/modules/webapp/files/

3. Create the init.pp file

Edit the manifest file:

sudo nano /etc/puppetlabs/code/environments/production/modules/webapp/manifests/init.pp

Add the following content:

class webapp {
  package { 'nginx':
    ensure => installed,
  }

  service { 'nginx':
    ensure => running,
    enable => true,
  }

  file { '/var/www/html/index.html':
    ensure  => file,
    source  => 'puppet:///modules/webapp/index.html',
    require => Package['nginx'],
  }
}

4. Update site.pp

Edit the site-wide manifest:

sudo nano /etc/puppetlabs/code/environments/production/manifests/site.pp

Add the following:

node 'puppet-agent' {
  include webapp
}

Step 7: Apply the Manifest

On the Puppet Agent:

sudo /opt/puppetlabs/bin/puppet agent --test

This will:
	1.	Install Nginx on the agent node.
	2.	Copy the index.html file to /var/www/html/ directory.
	3.	Start and enable the Nginx service.

Step 8: Verify the Website
	1.	Open a web browser and visit http://<puppet-agent-ip>.
	2.	You should see the form where potential students can register for DevOps, Cloud, or Generative AI courses.

This setup ensures the Puppet Server and Agent are correctly configured, and the website is deployed seamlessly using Puppet automation.