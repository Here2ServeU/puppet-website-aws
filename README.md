# Comprehensive Guide to Set Up Puppet Server, Agents (Ubuntu & Amazon Linux), and Deploy a Website Using Puppet Automation


## Step 1: Prerequisites

### 1.	Launch EC2 Instances:
- Puppet Server: Ubuntu 22.04
- Puppet Agent 1: Ubuntu 22.04
- Puppet Agent 2: Ubuntu 22.04

### 2.	Security Group Rules:
- Allow inbound SSH (port 22).
- Allow inbound HTTP (port 80).
- Allow inbound Puppet traffic (port 8140).

**Note**: For this, we use the ***setup-puppet-cluster.sh*** file to automate step 1.

## Step 2: Install Puppet Server on the Controller Node

### 1. Update System and Install Prerequisites
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install wget -y
```
### 2. Add Puppet Repository
```bash
wget https://apt.puppet.com/puppet8-release-jammy.deb
sudo dpkg -i puppet8-release-jammy.deb
sudo apt update
```
### 3. Install Puppet Server
```bash
sudo apt install -y puppetserver
```
### 4. Configure Puppet Server

- Edit the configuration:
```bash
sudo nano /etc/puppetlabs/puppet/puppet.conf
```
- Add:
```rb
[main]
certname = puppet-server
dns_alt_names = puppet,puppet-server
environment = production
runinterval = 1h
```
### 5. Set Java Heap Memory

- Edit Java memory settings:
```bash
sudo nano /etc/default/puppetserver
```
- Set:
```rb
JAVA_ARGS="-Xms512m -Xmx512m"
```
### 6. Start Puppet Server
```bash
sudo systemctl start puppetserver
sudo systemctl enable puppetserver
sudo systemctl status puppetserver
```
## Step 3: Install Puppet Agent on Client Nodes
### For Ubuntu Node
#### 1.	Update System and Add Repository
```bash
sudo apt update && sudo apt upgrade -y
wget https://apt.puppet.com/puppet8-release-jammy.deb
sudo dpkg -i puppet8-release-jammy.deb
sudo apt update
sudo apt install -y puppet-agent
```
#### 2.	Configure Puppet Agent
- Edit the configuration:
```bash
sudo nano /etc/puppetlabs/puppet/puppet.conf
```
- Add:
```rb
[main]
server = puppet-server
certname = puppet-agent-1
environment = production
runinterval = 1h
```
#### 3.	Start Puppet Agent
```bash
sudo systemctl start puppet
sudo systemctl enable puppet
sudo systemctl status puppet
```

## Step 4: Configure /etc/hosts and /etc/hostname

### On Both Worker Nodes and Puppet Server:
#### 1.	Edit /etc/hosts:
```bash
sudo nano /etc/hosts
```
- Add entries:
```txt
<puppet-server-ip> puppet puppet-server
<ubuntu-agent-ip> puppet-agent-1
<amazon-agent-ip> puppet-agent-2
```
#### 2.	Update /etc/hostname:
```bash
sudo nano /etc/hostname
```
##### Set:
- On Puppet Server: puppet-server
- On First Worker Node: puppet-agent-1
- On Second Worker Node: puppet-agent-2

- Apply changes:
```bash
sudo hostnamectl set-hostname <hostname>
```
## Step 5: Establish Connection Between Puppet Server and Agents

### On Puppet Agents:

- Request a certificate:
```bash
sudo /opt/puppetlabs/bin/puppet agent --test
```
### On Puppet Server:
#### 1.	List and Sign Certificates:
```bash
sudo /opt/puppetlabs/bin/puppetserver ca list
sudo /opt/puppetlabs/bin/puppetserver ca sign --certname puppet-agent-1
sudo /opt/puppetlabs/bin/puppetserver ca sign --certname puppet-agent-2
```
#### 2.	Re-run Agent to Apply Configurations:
```bash
sudo /opt/puppetlabs/bin/puppet agent --test
```
## Step 6: Deploy Website Using Puppet

### 1. Create Puppet Module Directory
```bash
sudo mkdir -p /etc/puppetlabs/code/environments/production/modules/webapp/{manifests,files}
```
### 2. Copy index.html
```bash
sudo cp webdata/index.html /etc/puppetlabs/code/environments/production/modules/webapp/files/
```
### 3. Create init.pp Manifest

- Edit:
```bash
sudo nano /etc/puppetlabs/code/environments/production/modules/webapp/manifests/init.pp
```
- Add:
```rb
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
```
### 4. Update site.pp

- Edit:
```bash
sudo nano /etc/puppetlabs/code/environments/production/manifests/site.pp
```
- Add:
```rb
node 'puppet-agent-ubuntu' {
  include webapp
}

node 'puppet-agent-amazon' {
  include webapp
}
```

## Step 7: Apply Manifest and Verify
### 1.	Run Puppet Agent:
```bash
sudo /opt/puppetlabs/bin/puppet agent --test
```
### 2.	Verify Website:
#### Open a browser and navigate to:
- ***http://<ubuntu-agent-1-ip>***
- ***http://<ubuntu-agent-2-ip>***
- You should see the form for students to register for DevOps, Cloud, or Generative AI courses.

---

## Clean Up
- Use the **destroy-puppet-cluster.sh** file to do it. 
```bash
./destroy-puppet-cluster.sh
```

This guide sets up the Puppet Server and agents, configures connectivity and automates website deployment on multiple nodes. Let me know if you need further assistance!
