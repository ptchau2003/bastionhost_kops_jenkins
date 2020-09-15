# I. Establish Bastion Host with Ansible/Jenkins/kops and deploy K8S cluster from this node to AWS EC2
## The Bastion Host is an AWS EC2 node Ubuntu 18.6 includes:
### 1. Ansible
### 2. Jenkins with HTTPS configuration, HTTPS port 8443
### 3. AWS CLI
### 4. kops
### 5. Jenkins jobs to deploy the k8s cluster to system
### 6. Jenkins jobs to deploy simulate tracking application with CD/CI
#### You need terrform to install bastion host, refer to https://www.terraform.io/downloads.html to download and install to your system
#### The Bastion Host has roles Full to S3, EC2, IAM to peform kops command
## Input AWS credentials key to your local machines
aws configure

```
AWS Access Key ID [****************XUOH]: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
AWS Secret Access Key [****************EQSD]: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
Default region name [us-east-1]:
Default output format [json]:
```
## Generate SSH key for Bastion host
ssh-keygen
```
Generating public/private rsa key pair.
Enter file in which to save the key (/home/cloud_user/.ssh/id_rsa):
```
### The key name id_rsa must be copy into same directory with Terrform directory
## Init and validate the bastionhost_kops_jenkins
terraform init

```
Initializing the backend...

Initializing provider plugins...
- Using previously-installed hashicorp/aws v3.6.0

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, we recommend adding version constraints in a required_providers block
in your configuration, with the constraint strings suggested below.

* hashicorp/aws: version = "~> 3.6.0"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

## Terraform validate
terraform validate

```
Success! The configuration is valid.
```
## Terrform apply
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_key_pair.bastion-host: Creating...
aws_iam_role.kops: Creating...
aws_default_vpc.default: Creating...
aws_iam_role.kops: Creation complete after 1s [id=kops]
aws_iam_instance_profile.kops_profile: Creating...
aws_iam_role_policy.kops_policy: Creating...
aws_key_pair.bastion-host: Creation complete after 1s [id=bastion-host]
aws_iam_role_policy.kops_policy: Creation complete after 0s [id=kops:kops]
aws_iam_instance_profile.kops_profile: Creation complete after 1s [id=kops_profile]
aws_default_vpc.default: Creation complete after 4s [id=vpc-XXXXXXXXXXXXXXXXXX]
aws_security_group.bastion-host-sg: Creating...
aws_security_group.bastion-host-sg: Creation complete after 4s [id=sg-XXXXXXXXXXXXXXXXXX]
aws_instance.bastion-host: Creating...
aws_instance.bastion-host: Still creating... [10s elapsed]
aws_instance.bastion-host: Still creating... [20s elapsed]
aws_instance.bastion-host: Still creating... [30s elapsed]
aws_instance.bastion-host: Provisioning with 'local-exec'...
aws_instance.bastion-host (local-exec): Executing: ["/bin/sh" "-c" "echo XXXXXXXXXXXXXXXXXX > public_ip.txt"]
aws_instance.bastion-host: Creation complete after 35s [id=i-XXXXXXXXXXXXXXXXXX]

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

```
### Generate key for Jenkins
#### Create key and certificate. Provide information wherever asked.
sudo openssl req -newkey rsa:2048 -nodes -keyout jenkins.key -x509 -days 700 -out jenkins.crt
#### Below command would ask you for password. Remember the same as that will be used during the configuration.
sudo openssl pkcs12 -inkey jenkins.key -in jenkins.crt -export -out jenkins.pkcs12
#### Import the key to java jenkins
sudo keytool -importkeystore -srckeystore jenkins.pkcs12 -srcstoretype pkcs12 -destkeystore /var/lib/jenkins/jenkins.jks -deststoretype PKCS12
#### Modify the jenkins configuration to support jenkins

sudo vi /etc/default/jenkins
```
JENKINS_ARGS="--webroot=/var/cache/$NAME/war --httpPort=-1 --httpsPort=8443 --httpsKeyStore="/var/lib/jenkins/jenkins.jks" --httpsKeyStorePassword="XXXXXX"
```
#### Restart jenkins
sudo service jenkins restart
#### Check by https:\/\<BationHost IP\>:8443/ successfully

# II. Jenkins jobs loading
## Copy all the jobs to Bastion Host /tmp/ directory
```
scp -pr jobs ubuntu@`cat public_ip.txt`:/tmp/
config.xml                                                                                                                                                                      100% 1291    18.7KB/s   00:00
config.xml                                                                                                                                                                      100% 1478    21.4KB/s   00:00
config.xml                                                                                                                                                                      100%  955    13.9KB/s   00:00
config.xml                                                                                                                                                                      100% 1038    15.1KB/s   00:00
config.xml                                                                                                                                                                      100% 1478    21.5KB/s   00:00
config.xml                                                                                                                                                                      100% 1331    16.3KB/s   00:00
config.xml                                                                                                                                                                      100% 1337    19.4KB/s   00:00
config.xml                                                                                                                                                                      100%  694    10.1KB/s   00:00
config.xml                                                                                                                                                                      100% 1404    20.2KB/s   00:00
config.xml                                                                                                                                                                      100% 1745    25.3KB/s   00:00
config.xml                                                                                                                                                                      100% 1334    19.3KB/s   00:00
config.xml                                                                                                                                                                      100% 1534    22.3KB/s   00:00
config.xml                                                                                                                                                                      100%  468     6.8KB/s   00:00
```
## Log into the Bastion Host 
ssh ubuntu@\`cat public_ip.txt\`
## Change owner of the directory
cd /tmp
chown -R jenkins:jenkins jobs
## Move the job to jenkins jobs
sudo cp -pr /tmp/jobs/* /var/lib/jenkins/jobs/
## Restart jenkins
sudo service jenkins restart
## Access to Jenkins and input the Admin password from
```
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
## Install the needed jenkins following the instruction
## After done, you can see all available k8s job available
# III. Use K8S jobs to deploy the Kubenetes system to AWS
## Jobs includes in order to conduct
### 1. s3-create-k8s-configuration: Jobs to create S3 bucket to store k8s configuration
### 2. k8s-create: Create k8s cluster in S3 (not deployed yet)
### 3. k8s-cluster-deploy: Deploy K8S cluster to AWS 
### 4. k8-cluster-rsa-key-generate: Generate K8S RSA key
### 5. k8s-auto-scale-config: Auto-scale configuration for k8s cluster
### 6. k8s-cluster-validate: Validate cluster
### 7. k8s-deploy-tracking-system: Deploy a simulate tracking system to k8s

## Export enviroment to k8s under jenkins user
NAME: name of the cluster
BUCKET: BUCKET name
S3NAME: It is s3://BUCKET
```
sudo -i
su - jenkins
export NAME='mycluster.k8s.local'
export S3NAME='s3://myclusterconfiguration'
export BUCKET='myclusterconfiguration'
```


