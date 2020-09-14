# Establish Bastion Host with Ansible/Jenkins/kops and deploy K8S cluster from this node to AWS EC2
## The Bastion Host is an AWS EC2 node includes:
### 1. Ansible
### 2. Jenkins with HTTPS configuration (will be guided in next steps)
### 3. AWS CLI
### 4. kops
### 5. Jenkins jobs to deploy the k8s cluster to system
### 6. Jenkins jobs to deploy simulate tracking application with CD/CI
#### You need terrform to install bastion host, refer to https://www.terraform.io/downloads.html to download and install to your system
* Input AWS credentials key to your local machines
aws configure

```
AWS Access Key ID [****************XUOH]: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
AWS Secret Access Key [****************EQSD]: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
Default region name [us-east-1]:
Default output format [json]:
```

* Init and validate the bastionhost_kops_jenkins
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

* Terraform validate
terraform validate

```
Success! The configuration is valid.
```

