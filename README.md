# Puppet Hands-On Project: DevOps and Cloud Enrollment Form

## Project Overview

This hands-on project sets up a Puppet cluster with one controller node and two worker nodes (Amazon Linux and Ubuntu) on AWS. The project includes an HTML form (webapp/index.html) for users to enroll in DevOps and Cloud courses at T2S. The setup process is automated using setup-puppet-cluster.sh, and resources can be cleaned up using destroy-puppet-cluster.sh.

---

## Steps to Complete the Project

### 1. Set Up the Puppet Cluster
- Use the setup-puppet-cluster.sh script to provision the Puppet Controller and two worker nodes (Amazon Linux and Ubuntu) on AWS.
- The script creates the necessary security group, PEM key, and EC2 instances.

### 2. Configure Puppet Master on the Controller Node
- SSH into the Puppet Controller node:
```bash
ssh -i ~/.ssh/puppet-controller-key.pem ubuntu@<controller-public-ip>
```

#### Install Puppet Server:
```bash
sudo apt update
sudo apt install -y puppetserver
sudo systemctl start puppetserver
sudo systemctl enable puppetserver
```

#### Edit the Puppet configuration file /etc/puppetlabs/puppet/puppet.conf:
```bash
sudo nano /etc/puppetlabs/puppet/puppet.conf
```
- Add the following under [main]:
```rb
certname = puppet-controller
server = puppet-controller
environment = production
```
### 3. Install Puppet Agent on Worker Nodes
- SSH into each worker node:
```bash
ssh -i ~/.ssh/puppet-controller-key.pem ec2-user@<worker-public-ip>
```

- Install Puppet Agent (example for Amazon Linux):
```bash
sudo yum install -y https://yum.puppet.com/puppet-release-el-7.noarch.rpm
sudo yum install -y puppet-agent
```

- Start and enable Puppet Agent:
```bash
sudo systemctl start puppet
sudo systemctl enable puppet
```

### 4. Deploy the Enrollment Form to the Puppet Controller’s Web Server

#### Step 4.1: Install Apache Web Server on the Puppet Controller
- On the Puppet Controller node:
```bash
sudo apt install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
```


#### Step 4.2: Prepare the Puppet Manifest
- Create a new Puppet module named webapp:
```bash
sudo mkdir -p /etc/puppetlabs/code/environments/production/modules/webapp/{manifests,files}
```

- Copy the index.html file to the files directory:
```bash
sudo cp ~/path/to/index.html /etc/puppetlabs/code/environments/production/modules/webapp/files/
```

- Create the init.pp manifest:
```bash
sudo nano /etc/puppetlabs/code/environments/production/modules/webapp/manifests/init.pp
```

- Add the following content:
```rb
class webapp {
  file { '/var/www/html/index.html':
    ensure => 'file',
    source => 'puppet:///modules/webapp/index.html',
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0644',
  }
}
```

### 5. Apply the Puppet Configuration
- Add the webapp class to the Puppet Controller node:
```
sudo nano /etc/puppetlabs/code/environments/production/manifests/site.pp
```

- Add:
```rb
node 'puppet-controller' {
  include webapp
}
```

- Run the Puppet agent on the Puppet Controller to apply the manifest:
```bash
sudo puppet agent --test
```

### 6. Verify the Deployment
- Access the web server on the Puppet Controller node:
```txt
http://<controller-public-ip>/index.html
```

- The enrollment form should be displayed.

### 7. Clean Up the Cluster
- Use the destroy-puppet-cluster.sh script to terminate the Puppet Controller and worker nodes, delete the security group, and remove the PEM key.

---

## Explanation of Steps
- **Provisioning the Cluster**: Automates the setup of necessary infrastructure for the Puppet Controller and worker nodes using AWS CLI.
- **Installing Puppet Components**: Configures the Puppet Master on the controller and agents on the worker nodes for centralized configuration management.
- **Deploying the Enrollment Form**: Utilizes Puppet to manage the index.html file and ensures it is deployed to the web server directory.
- **Verification and Cleanup**: Ensures the application is working as expected and removes all resources after use.

---

This project demonstrates hands-on knowledge of Puppet for configuration management in a DevOps environment.
