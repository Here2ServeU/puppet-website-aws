## Step 1: Install Puppet Server On controller
```bash
sudo apt-get update && sudo apt-get upgrade
sudo apt-get install wget 
wget https://apt.puppetlabs.com/puppet-release-bionic.deb 
sudo dpkg -i puppet-release-bionic.deb
sudo apt-get update 
apt policy puppet master
sudo apt-get install puppet-master 
```

## Step 2: Install Puppet Agent
```bash
sudo apt-get update && sudo apt-get upgrade
sudo apt-get install wget 
wget https://apt.puppetlabs.com/puppet-release-bionic.deb 
sudo dpkg -i puppet-release-bionic.deb
sudo apt-get update 
apt policy puppet master
sudo apt-get install puppet
```
## Step 3: Configure Puppet Controller Node: 
```bash
sudo nano /etc/default/puppet-master 
```
### Add the following: 
JAVA-ARGS="Xms512m Xmx512m"   // Add this line
```bash
sudo systemctl restart puppet-master 
sudo ufw allow 8140/tcp   # Only if you did not use the "setup-puppet-cluster.sh" file. 
```
### Configure the /etc/hosts
```bash
sudo nano /etc/hosts
```
### Add the following (Controller Node's IP and hostname): 
<IP_Address> puppet 

### Create the following directory path
```bash
sudo mkdir -p /etc/puppet/code/environments/production/manifests
```

## Step 4: Configure Puppet worker Node: 
```bash
sudo nano /etc/hosts  # Add the Puppet Master in the /etc/hosts  
sudo systemctl start puppet 
sudo systemctl enable puppet 
```

## Step 5: More configurations On Controller Node 
```bash
sudo puppet cert list 
sudo puppet cert sign --all 
```
### Creating a Manifest 
```bash
mkdir webapp
nano webapp/index.html # Add content for the web application
sudo /etc/puppet/code/environments/production/manifests/site.pp 
```
#### Add the following content: 
```rb
# site.pp manifest
node default {
  # Ensure Nginx is installed and running
  case $facts['os']['family'] {
    'Debian': {
      package { 'nginx':
        ensure => installed,
      }

      service { 'nginx':
        ensure    => running,
        enable    => true,
        subscribe => Package['nginx'],
      }
    }

    'RedHat': {
      package { 'nginx':
        ensure => installed,
        name   => 'nginx', # Adjust this if Amazon Linux uses a different package name
      }

      service { 'nginx':
        ensure    => running,
        enable    => true,
        subscribe => Package['nginx'],
      }
    }

    default: {
      notify { "Unsupported OS family: ${facts['os']['family']}":
        message => "Nginx installation is not supported on this OS family.",
      }
    }
  }
    # Ensure the index.html file is copied to the Nginx document root
  file { '/var/www/html/index.html':
    ensure  => file,
    source  => 'puppet:///modules/webapp/index.html',
    require => Package['nginx'],
    notify  => Service['nginx'],
  }
}
```

### Create the Module Directory and Copy the index.html file: 
```bash
sudo mkdir -p /etc/puppetlabs/code/environments/production/modules/webapp/files
sudo cp webdata/index.html /etc/puppetlabs/code/environments/production/modules/webapp/files/index.html
```
### Run the Puppet Agent on Nodes: 
```bash
sudo puppet agent --test
```
#### What This Does
1.	Installs Nginx based on the OS family (Debian or RedHat).

2.	Starts and enables the Nginx service.

3.	Copies the index.html file to the Nginx document root (/var/www/html/).

4.	Restarts the Nginx service if the index.html file changes.

