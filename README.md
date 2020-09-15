# I. Establish Bastion Host with Ansible/Jenkins/kops and deploy K8S cluster from this node to AWS EC2
## The Bastion Host is an AWS EC2 node Ubuntu 18.6 includes:
### 1. Ansible
### 2. Jenkins with HTTPS configuration, HTTPS port 8443
### 3. AWS CLI
### 4. kops
### 5. Jenkins jobs to deploy the k8s cluster to system
### 6. Jenkins jobs to deploy simulate tracking application with CD/CI
#### You need terrform to install bastion host, refer to https://www.terraform.io/downloads.html to download and install to your system
#### The Bastion Host has roles Full to S3, EC2, IAM, Loadbalancer and Autoscaling to peform kops command
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
### 2. k8-cluster-rsa-key-generate: Generate K8S RSA key
### 3. k8s-create: Create k8s cluster in S3 (not deployed yet)
### 4. k8s-cluster-deploy: Deploy K8S cluster to AWS 
### 5. k8s-auto-scale-config: Auto-scale configuration for k8s cluster
### 6. k8s-cluster-validate: Validate cluster
### 7. k8s-deploy-tracking-system: Deploy a simulate tracking system to k8s

### 1. Create S3 bucket to store your k8s configuration
Run the 1st job
```
Started by user Chau Phan
Running as SYSTEM
Building in workspace /var/lib/jenkins/workspace/s3-create-k8s-configuration
[s3-create-k8s-configuration] $ /bin/sh -xe /tmp/jenkins7863059195966590215.sh
+ aws s3api create-bucket --bucket myk8sconfiguration --region us-east-1
{
    "Location": "/myk8sconfiguration"
}
+ aws s3api put-bucket-versioning --bucket myk8sconfiguration --versioning-configuration Status=Enabled
+ aws s3api put-bucket-encryption --bucket myk8sconfiguration --server-side-encryption-configuration {"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}
Finished: SUCCESS
```
### 2. K8s create
Run task 2
```
Started by user Chau Phan
Running as SYSTEM
Building in workspace /var/lib/jenkins/workspace/k8s-create
[k8s-create] $ /bin/sh -xe /tmp/jenkins2508087537739312406.sh
+ kops create cluster --node-count=3 --zones=us-east-1a,us-east-1b,us-east-1c mycluster.k8s.local --state=s3://myk8sconfig
I0915 08:20:03.219843   13330 create_cluster.go:555] Inferred --cloud=aws from zone "us-east-1a"
I0915 08:20:03.313071   13330 subnets.go:184] Assigned CIDR 172.20.32.0/19 to subnet us-east-1a
I0915 08:20:03.313153   13330 subnets.go:184] Assigned CIDR 172.20.64.0/19 to subnet us-east-1b
I0915 08:20:03.313176   13330 subnets.go:184] Assigned CIDR 172.20.96.0/19 to subnet us-east-1c
I0915 08:20:04.064339   13330 create_cluster.go:1537] Using SSH public key: /var/lib/jenkins/.ssh/id_rsa.pub
Previewing changes that will be made:

I0915 08:20:04.410564   13330 apply_cluster.go:545] Gossip DNS: skipping DNS validation
I0915 08:20:04.457758   13330 executor.go:103] Tasks: 0 done / 96 total; 42 can run
I0915 08:20:04.828415   13330 executor.go:103] Tasks: 42 done / 96 total; 28 can run
I0915 08:20:05.315603   13330 executor.go:103] Tasks: 70 done / 96 total; 22 can run
I0915 08:20:05.432931   13330 executor.go:103] Tasks: 92 done / 96 total; 3 can run
W0915 08:20:05.440043   13330 keypair.go:139] Task did not have an address: *awstasks.LoadBalancer {"Name":"api.mycluster.k8s.local","Lifecycle":"Sync","LoadBalancerName":"api-mycluster-k8s-local-9s4spt","DNSName":null,"HostedZoneId":null,"Subnets":[{"Name":"us-east-1a.mycluster.k8s.local","ShortName":"us-east-1a","Lifecycle":"Sync","ID":null,"VPC":{"Name":"mycluster.k8s.local","Lifecycle":"Sync","ID":null,"CIDR":"172.20.0.0/16","EnableDNSHostnames":true,"EnableDNSSupport":true,"Shared":false,"Tags":{"KubernetesCluster":"mycluster.k8s.local","Name":"mycluster.k8s.local","kubernetes.io/cluster/mycluster.k8s.local":"owned"}},"AvailabilityZone":"us-east-1a","CIDR":"172.20.32.0/19","Shared":false,"Tags":{"KubernetesCluster":"mycluster.k8s.local","Name":"us-east-1a.mycluster.k8s.local","SubnetType":"Public","kubernetes.io/cluster/mycluster.k8s.local":"owned","kubernetes.io/role/elb":"1"}},{"Name":"us-east-1b.mycluster.k8s.local","ShortName":"us-east-1b","Lifecycle":"Sync","ID":null,"VPC":{"Name":"mycluster.k8s.local","Lifecycle":"Sync","ID":null,"CIDR":"172.20.0.0/16","EnableDNSHostnames":true,"EnableDNSSupport":true,"Shared":false,"Tags":{"KubernetesCluster":"mycluster.k8s.local","Name":"mycluster.k8s.local","kubernetes.io/cluster/mycluster.k8s.local":"owned"}},"AvailabilityZone":"us-east-1b","CIDR":"172.20.64.0/19","Shared":false,"Tags":{"KubernetesCluster":"mycluster.k8s.local","Name":"us-east-1b.mycluster.k8s.local","SubnetType":"Public","kubernetes.io/cluster/mycluster.k8s.local":"owned","kubernetes.io/role/elb":"1"}},{"Name":"us-east-1c.mycluster.k8s.local","ShortName":"us-east-1c","Lifecycle":"Sync","ID":null,"VPC":{"Name":"mycluster.k8s.local","Lifecycle":"Sync","ID":null,"CIDR":"172.20.0.0/16","EnableDNSHostnames":true,"EnableDNSSupport":true,"Shared":false,"Tags":{"KubernetesCluster":"mycluster.k8s.local","Name":"mycluster.k8s.local","kubernetes.io/cluster/mycluster.k8s.local":"owned"}},"AvailabilityZone":"us-east-1c","CIDR":"172.20.96.0/19","Shared":false,"Tags":{"KubernetesCluster":"mycluster.k8s.local","Name":"us-east-1c.mycluster.k8s.local","SubnetType":"Public","kubernetes.io/cluster/mycluster.k8s.local":"owned","kubernetes.io/role/elb":"1"}}],"SecurityGroups":[{"Name":"api-elb.mycluster.k8s.local","Lifecycle":"Sync","ID":null,"Description":"Security group for api ELB","VPC":{"Name":"mycluster.k8s.local","Lifecycle":"Sync","ID":null,"CIDR":"172.20.0.0/16","EnableDNSHostnames":true,"EnableDNSSupport":true,"Shared":false,"Tags":{"KubernetesCluster":"mycluster.k8s.local","Name":"mycluster.k8s.local","kubernetes.io/cluster/mycluster.k8s.local":"owned"}},"RemoveExtraRules":["port=443"],"Shared":null,"Tags":{"KubernetesCluster":"mycluster.k8s.local","Name":"api-elb.mycluster.k8s.local","kubernetes.io/cluster/mycluster.k8s.local":"owned"}}],"Listeners":{"443":{"InstancePort":443,"SSLCertificateID":""}},"Scheme":null,"HealthCheck":{"Target":"SSL:443","HealthyThreshold":2,"UnhealthyThreshold":2,"Interval":10,"Timeout":5},"AccessLog":null,"ConnectionDraining":null,"ConnectionSettings":{"IdleTimeout":300},"CrossZoneLoadBalancing":{"Enabled":false},"SSLCertificateID":"","Tags":{"KubernetesCluster":"mycluster.k8s.local","Name":"api.mycluster.k8s.local","kubernetes.io/cluster/mycluster.k8s.local":"owned"}}
I0915 08:20:05.514507   13330 executor.go:103] Tasks: 95 done / 96 total; 1 can run
I0915 08:20:05.591280   13330 executor.go:103] Tasks: 96 done / 96 total; 0 can run
Will create resources:
  AutoscalingGroup/master-us-east-1a.masters.mycluster.k8s.local
  	Granularity         	1Minute
  	LaunchConfiguration 	name:master-us-east-1a.masters.mycluster.k8s.local
  	MaxSize             	1
  	Metrics             	[GroupDesiredCapacity, GroupInServiceInstances, GroupMaxSize, GroupMinSize, GroupPendingInstances, GroupStandbyInstances, GroupTerminatingInstances, GroupTotalInstances]
  	MinSize             	1
  	Subnets             	[name:us-east-1a.mycluster.k8s.local]
  	SuspendProcesses    	[]
  	Tags                	{Name: master-us-east-1a.masters.mycluster.k8s.local, KubernetesCluster: mycluster.k8s.local, kubernetes.io/cluster/mycluster.k8s.local: owned, k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup: master-us-east-1a, k8s.io/role/master: 1, kops.k8s.io/instancegroup: master-us-east-1a}

  AutoscalingGroup/nodes.mycluster.k8s.local
  	Granularity         	1Minute
  	LaunchConfiguration 	name:nodes.mycluster.k8s.local
  	MaxSize             	3
  	Metrics             	[GroupDesiredCapacity, GroupInServiceInstances, GroupMaxSize, GroupMinSize, GroupPendingInstances, GroupStandbyInstances, GroupTerminatingInstances, GroupTotalInstances]
  	MinSize             	3
  	Subnets             	[name:us-east-1a.mycluster.k8s.local, name:us-east-1b.mycluster.k8s.local, name:us-east-1c.mycluster.k8s.local]
  	SuspendProcesses    	[]
  	Tags                	{KubernetesCluster: mycluster.k8s.local, kubernetes.io/cluster/mycluster.k8s.local: owned, k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup: nodes, k8s.io/role/node: 1, kops.k8s.io/instancegroup: nodes, Name: nodes.mycluster.k8s.local}

  DHCPOptions/mycluster.k8s.local
  	DomainName          	ec2.internal
  	DomainNameServers   	AmazonProvidedDNS
  	Shared              	false
  	Tags                	{KubernetesCluster: mycluster.k8s.local, kubernetes.io/cluster/mycluster.k8s.local: owned, Name: mycluster.k8s.local}

  EBSVolume/a.etcd-events.mycluster.k8s.local
  	AvailabilityZone    	us-east-1a
  	Encrypted           	false
  	SizeGB              	20
  	Tags                	{k8s.io/etcd/events: a/a, k8s.io/role/master: 1, kubernetes.io/cluster/mycluster.k8s.local: owned, Name: a.etcd-events.mycluster.k8s.local, KubernetesCluster: mycluster.k8s.local}
  	VolumeType          	gp2

  EBSVolume/a.etcd-main.mycluster.k8s.local
  	AvailabilityZone    	us-east-1a
  	Encrypted           	false
  	SizeGB              	20
  	Tags                	{k8s.io/etcd/main: a/a, k8s.io/role/master: 1, kubernetes.io/cluster/mycluster.k8s.local: owned, Name: a.etcd-main.mycluster.k8s.local, KubernetesCluster: mycluster.k8s.local}
  	VolumeType          	gp2

  IAMInstanceProfile/masters.mycluster.k8s.local
  	Shared              	false

  IAMInstanceProfile/nodes.mycluster.k8s.local
  	Shared              	false

  IAMInstanceProfileRole/masters.mycluster.k8s.local
  	InstanceProfile     	name:masters.mycluster.k8s.local id:masters.mycluster.k8s.local
  	Role                	name:masters.mycluster.k8s.local

  IAMInstanceProfileRole/nodes.mycluster.k8s.local
  	InstanceProfile     	name:nodes.mycluster.k8s.local id:nodes.mycluster.k8s.local
  	Role                	name:nodes.mycluster.k8s.local

  IAMRole/masters.mycluster.k8s.local
  	ExportWithID        	masters

  IAMRole/nodes.mycluster.k8s.local
  	ExportWithID        	nodes

  IAMRolePolicy/master-policyoverride
  	Role                	name:masters.mycluster.k8s.local
  	Managed             	true

  IAMRolePolicy/masters.mycluster.k8s.local
  	Role                	name:masters.mycluster.k8s.local
  	Managed             	false

  IAMRolePolicy/node-policyoverride
  	Role                	name:nodes.mycluster.k8s.local
  	Managed             	true

  IAMRolePolicy/nodes.mycluster.k8s.local
  	Role                	name:nodes.mycluster.k8s.local
  	Managed             	false

  InternetGateway/mycluster.k8s.local
  	VPC                 	name:mycluster.k8s.local
  	Shared              	false
  	Tags                	{Name: mycluster.k8s.local, KubernetesCluster: mycluster.k8s.local, kubernetes.io/cluster/mycluster.k8s.local: owned}

  Keypair/apiserver-aggregator
  	Signer              	name:apiserver-aggregator-ca id:cn=apiserver-aggregator-ca
  	Subject             	cn=aggregator
  	Type                	client
  	LegacyFormat        	false

  Keypair/apiserver-aggregator-ca
  	Subject             	cn=apiserver-aggregator-ca
  	Type                	ca
  	LegacyFormat        	false

  Keypair/apiserver-proxy-client
  	Signer              	name:ca id:cn=kubernetes
  	Subject             	cn=apiserver-proxy-client
  	Type                	client
  	LegacyFormat        	false

  Keypair/ca
  	Subject             	cn=kubernetes
  	Type                	ca
  	LegacyFormat        	false

  Keypair/etcd-clients-ca
  	Subject             	cn=etcd-clients-ca
  	Type                	ca
  	LegacyFormat        	false

  Keypair/etcd-manager-ca-events
  	Subject             	cn=etcd-manager-ca-events
  	Type                	ca
  	LegacyFormat        	false

  Keypair/etcd-manager-ca-main
  	Subject             	cn=etcd-manager-ca-main
  	Type                	ca
  	LegacyFormat        	false

  Keypair/etcd-peers-ca-events
  	Subject             	cn=etcd-peers-ca-events
  	Type                	ca
  	LegacyFormat        	false

  Keypair/etcd-peers-ca-main
  	Subject             	cn=etcd-peers-ca-main
  	Type                	ca
  	LegacyFormat        	false

  Keypair/kops
  	Signer              	name:ca id:cn=kubernetes
  	Subject             	o=system:masters,cn=kops
  	Type                	client
  	LegacyFormat        	false

  Keypair/kube-controller-manager
  	Signer              	name:ca id:cn=kubernetes
  	Subject             	cn=system:kube-controller-manager
  	Type                	client
  	LegacyFormat        	false

  Keypair/kube-proxy
  	Signer              	name:ca id:cn=kubernetes
  	Subject             	cn=system:kube-proxy
  	Type                	client
  	LegacyFormat        	false

  Keypair/kube-scheduler
  	Signer              	name:ca id:cn=kubernetes
  	Subject             	cn=system:kube-scheduler
  	Type                	client
  	LegacyFormat        	false

  Keypair/kubecfg
  	Signer              	name:ca id:cn=kubernetes
  	Subject             	o=system:masters,cn=kubecfg
  	Type                	client
  	LegacyFormat        	false

  Keypair/kubelet
  	Signer              	name:ca id:cn=kubernetes
  	Subject             	o=system:nodes,cn=kubelet
  	Type                	client
  	LegacyFormat        	false

  Keypair/kubelet-api
  	Signer              	name:ca id:cn=kubernetes
  	Subject             	cn=kubelet-api
  	Type                	client
  	LegacyFormat        	false

  Keypair/master
  	AlternateNames      	[100.64.0.1, 127.0.0.1, api.internal.mycluster.k8s.local, api.mycluster.k8s.local, kubernetes, kubernetes.default, kubernetes.default.svc, kubernetes.default.svc.cluster.local]
  	Signer              	name:ca id:cn=kubernetes
  	Subject             	cn=kubernetes-master
  	Type                	server
  	LegacyFormat        	false

  LaunchConfiguration/master-us-east-1a.masters.mycluster.k8s.local
  	AssociatePublicIP   	true
  	IAMInstanceProfile  	name:masters.mycluster.k8s.local id:masters.mycluster.k8s.local
  	ImageID             	099720109477/ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20200716
  	InstanceType        	t3.medium
  	RootVolumeDeleteOnTermination	true
  	RootVolumeSize      	64
  	RootVolumeType      	gp2
  	SSHKey              	name:kubernetes.mycluster.k8s.local-73:19:7a:5d:ce:15:21:2a:2e:22:d1:af:23:21:66:80 id:kubernetes.mycluster.k8s.local-73:19:7a:5d:ce:15:21:2a:2e:22:d1:af:23:21:66:80
  	SecurityGroups      	[name:masters.mycluster.k8s.local]
  	SpotPrice           	

  LaunchConfiguration/nodes.mycluster.k8s.local
  	AssociatePublicIP   	true
  	IAMInstanceProfile  	name:nodes.mycluster.k8s.local id:nodes.mycluster.k8s.local
  	ImageID             	099720109477/ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20200716
  	InstanceType        	t3.medium
  	RootVolumeDeleteOnTermination	true
  	RootVolumeSize      	128
  	RootVolumeType      	gp2
  	SSHKey              	name:kubernetes.mycluster.k8s.local-73:19:7a:5d:ce:15:21:2a:2e:22:d1:af:23:21:66:80 id:kubernetes.mycluster.k8s.local-73:19:7a:5d:ce:15:21:2a:2e:22:d1:af:23:21:66:80
  	SecurityGroups      	[name:nodes.mycluster.k8s.local]
  	SpotPrice           	

  LoadBalancer/api.mycluster.k8s.local
  	LoadBalancerName    	api-mycluster-k8s-local-9s4spt
  	Subnets             	[name:us-east-1a.mycluster.k8s.local, name:us-east-1b.mycluster.k8s.local, name:us-east-1c.mycluster.k8s.local]
  	SecurityGroups      	[name:api-elb.mycluster.k8s.local]
  	Listeners           	{443: {"InstancePort":443,"SSLCertificateID":""}}
  	HealthCheck         	{"Target":"SSL:443","HealthyThreshold":2,"UnhealthyThreshold":2,"Interval":10,"Timeout":5}
  	ConnectionSettings  	{"IdleTimeout":300}
  	CrossZoneLoadBalancing	{"Enabled":false}
  	SSLCertificateID    	
  	Tags                	{Name: api.mycluster.k8s.local, KubernetesCluster: mycluster.k8s.local, kubernetes.io/cluster/mycluster.k8s.local: owned}

  LoadBalancerAttachment/api-master-us-east-1a
  	LoadBalancer        	name:api.mycluster.k8s.local id:api.mycluster.k8s.local
  	AutoscalingGroup    	name:master-us-east-1a.masters.mycluster.k8s.local id:master-us-east-1a.masters.mycluster.k8s.local

  ManagedFile/etcd-cluster-spec-events
  	Base                	s3://myk8sconfig/mycluster.k8s.local/backups/etcd/events
  	Location            	/control/etcd-cluster-spec

  ManagedFile/etcd-cluster-spec-main
  	Base                	s3://myk8sconfig/mycluster.k8s.local/backups/etcd/main
  	Location            	/control/etcd-cluster-spec

  ManagedFile/manifests-etcdmanager-events
  	Location            	manifests/etcd/events.yaml

  ManagedFile/manifests-etcdmanager-main
  	Location            	manifests/etcd/main.yaml

  ManagedFile/manifests-static-kube-apiserver-healthcheck
  	Location            	manifests/static/kube-apiserver-healthcheck.yaml

  ManagedFile/mycluster.k8s.local-addons-bootstrap
  	Location            	addons/bootstrap-channel.yaml

  ManagedFile/mycluster.k8s.local-addons-core.addons.k8s.io
  	Location            	addons/core.addons.k8s.io/v1.4.0.yaml

  ManagedFile/mycluster.k8s.local-addons-dns-controller.addons.k8s.io-k8s-1.12
  	Location            	addons/dns-controller.addons.k8s.io/k8s-1.12.yaml

  ManagedFile/mycluster.k8s.local-addons-dns-controller.addons.k8s.io-k8s-1.6
  	Location            	addons/dns-controller.addons.k8s.io/k8s-1.6.yaml

  ManagedFile/mycluster.k8s.local-addons-kops-controller.addons.k8s.io-k8s-1.16
  	Location            	addons/kops-controller.addons.k8s.io/k8s-1.16.yaml

  ManagedFile/mycluster.k8s.local-addons-kube-dns.addons.k8s.io-k8s-1.12
  	Location            	addons/kube-dns.addons.k8s.io/k8s-1.12.yaml

  ManagedFile/mycluster.k8s.local-addons-kube-dns.addons.k8s.io-k8s-1.6
  	Location            	addons/kube-dns.addons.k8s.io/k8s-1.6.yaml

  ManagedFile/mycluster.k8s.local-addons-kubelet-api.rbac.addons.k8s.io-k8s-1.9
  	Location            	addons/kubelet-api.rbac.addons.k8s.io/k8s-1.9.yaml

  ManagedFile/mycluster.k8s.local-addons-limit-range.addons.k8s.io
  	Location            	addons/limit-range.addons.k8s.io/v1.5.0.yaml

  ManagedFile/mycluster.k8s.local-addons-rbac.addons.k8s.io-k8s-1.8
  	Location            	addons/rbac.addons.k8s.io/k8s-1.8.yaml

  ManagedFile/mycluster.k8s.local-addons-storage-aws.addons.k8s.io-v1.15.0
  	Location            	addons/storage-aws.addons.k8s.io/v1.15.0.yaml

  ManagedFile/mycluster.k8s.local-addons-storage-aws.addons.k8s.io-v1.7.0
  	Location            	addons/storage-aws.addons.k8s.io/v1.7.0.yaml

  Route/0.0.0.0/0
  	RouteTable          	name:mycluster.k8s.local
  	CIDR                	0.0.0.0/0
  	InternetGateway     	name:mycluster.k8s.local

  RouteTable/mycluster.k8s.local
  	VPC                 	name:mycluster.k8s.local
  	Shared              	false
  	Tags                	{Name: mycluster.k8s.local, KubernetesCluster: mycluster.k8s.local, kubernetes.io/cluster/mycluster.k8s.local: owned, kubernetes.io/kops/role: public}

  RouteTableAssociation/us-east-1a.mycluster.k8s.local
  	RouteTable          	name:mycluster.k8s.local
  	Subnet              	name:us-east-1a.mycluster.k8s.local

  RouteTableAssociation/us-east-1b.mycluster.k8s.local
  	RouteTable          	name:mycluster.k8s.local
  	Subnet              	name:us-east-1b.mycluster.k8s.local

  RouteTableAssociation/us-east-1c.mycluster.k8s.local
  	RouteTable          	name:mycluster.k8s.local
  	Subnet              	name:us-east-1c.mycluster.k8s.local

  SSHKey/kubernetes.mycluster.k8s.local-73:19:7a:5d:ce:15:21:2a:2e:22:d1:af:23:21:66:80
  	KeyFingerprint      	6a:3a:67:e0:dc:29:9d:e4:2b:6d:48:48:97:b1:4d:6f

  Secret/admin

  Secret/kube

  Secret/kube-proxy

  Secret/kubelet

  Secret/system:controller_manager

  Secret/system:dns

  Secret/system:logging

  Secret/system:monitoring

  Secret/system:scheduler

  SecurityGroup/api-elb.mycluster.k8s.local
  	Description         	Security group for api ELB
  	VPC                 	name:mycluster.k8s.local
  	RemoveExtraRules    	[port=443]
  	Tags                	{kubernetes.io/cluster/mycluster.k8s.local: owned, Name: api-elb.mycluster.k8s.local, KubernetesCluster: mycluster.k8s.local}

  SecurityGroup/masters.mycluster.k8s.local
  	Description         	Security group for masters
  	VPC                 	name:mycluster.k8s.local
  	RemoveExtraRules    	[port=22, port=443, port=2380, port=2381, port=4001, port=4002, port=4789, port=179]
  	Tags                	{Name: masters.mycluster.k8s.local, KubernetesCluster: mycluster.k8s.local, kubernetes.io/cluster/mycluster.k8s.local: owned}

  SecurityGroup/nodes.mycluster.k8s.local
  	Description         	Security group for nodes
  	VPC                 	name:mycluster.k8s.local
  	RemoveExtraRules    	[port=22]
  	Tags                	{kubernetes.io/cluster/mycluster.k8s.local: owned, Name: nodes.mycluster.k8s.local, KubernetesCluster: mycluster.k8s.local}

  SecurityGroupRule/all-master-to-master
  	SecurityGroup       	name:masters.mycluster.k8s.local
  	SourceGroup         	name:masters.mycluster.k8s.local

  SecurityGroupRule/all-master-to-node
  	SecurityGroup       	name:nodes.mycluster.k8s.local
  	SourceGroup         	name:masters.mycluster.k8s.local

  SecurityGroupRule/all-node-to-node
  	SecurityGroup       	name:nodes.mycluster.k8s.local
  	SourceGroup         	name:nodes.mycluster.k8s.local

  SecurityGroupRule/api-elb-egress
  	SecurityGroup       	name:api-elb.mycluster.k8s.local
  	CIDR                	0.0.0.0/0
  	Egress              	true

  SecurityGroupRule/https-api-elb-0.0.0.0/0
  	SecurityGroup       	name:api-elb.mycluster.k8s.local
  	CIDR                	0.0.0.0/0
  	Protocol            	tcp
  	FromPort            	443
  	ToPort              	443

  SecurityGroupRule/https-elb-to-master
  	SecurityGroup       	name:masters.mycluster.k8s.local
  	Protocol            	tcp
  	FromPort            	443
  	ToPort              	443
  	SourceGroup         	name:api-elb.mycluster.k8s.local

  SecurityGroupRule/icmp-pmtu-api-elb-0.0.0.0/0
  	SecurityGroup       	name:api-elb.mycluster.k8s.local
  	CIDR                	0.0.0.0/0
  	Protocol            	icmp
  	FromPort            	3
  	ToPort              	4

  SecurityGroupRule/master-egress
  	SecurityGroup       	name:masters.mycluster.k8s.local
  	CIDR                	0.0.0.0/0
  	Egress              	true

  SecurityGroupRule/node-egress
  	SecurityGroup       	name:nodes.mycluster.k8s.local
  	CIDR                	0.0.0.0/0
  	Egress              	true

  SecurityGroupRule/node-to-master-tcp-1-2379
  	SecurityGroup       	name:masters.mycluster.k8s.local
  	Protocol            	tcp
  	FromPort            	1
  	ToPort              	2379
  	SourceGroup         	name:nodes.mycluster.k8s.local

  SecurityGroupRule/node-to-master-tcp-2382-4000
  	SecurityGroup       	name:masters.mycluster.k8s.local
  	Protocol            	tcp
  	FromPort            	2382
  	ToPort              	4000
  	SourceGroup         	name:nodes.mycluster.k8s.local

  SecurityGroupRule/node-to-master-tcp-4003-65535
  	SecurityGroup       	name:masters.mycluster.k8s.local
  	Protocol            	tcp
  	FromPort            	4003
  	ToPort              	65535
  	SourceGroup         	name:nodes.mycluster.k8s.local

  SecurityGroupRule/node-to-master-udp-1-65535
  	SecurityGroup       	name:masters.mycluster.k8s.local
  	Protocol            	udp
  	FromPort            	1
  	ToPort              	65535
  	SourceGroup         	name:nodes.mycluster.k8s.local

  SecurityGroupRule/ssh-external-to-master-0.0.0.0/0
  	SecurityGroup       	name:masters.mycluster.k8s.local
  	CIDR                	0.0.0.0/0
  	Protocol            	tcp
  	FromPort            	22
  	ToPort              	22

  SecurityGroupRule/ssh-external-to-node-0.0.0.0/0
  	SecurityGroup       	name:nodes.mycluster.k8s.local
  	CIDR                	0.0.0.0/0
  	Protocol            	tcp
  	FromPort            	22
  	ToPort              	22

  Subnet/us-east-1a.mycluster.k8s.local
  	ShortName           	us-east-1a
  	VPC                 	name:mycluster.k8s.local
  	AvailabilityZone    	us-east-1a
  	CIDR                	172.20.32.0/19
  	Shared              	false
  	Tags                	{kubernetes.io/role/elb: 1, Name: us-east-1a.mycluster.k8s.local, KubernetesCluster: mycluster.k8s.local, kubernetes.io/cluster/mycluster.k8s.local: owned, SubnetType: Public}

  Subnet/us-east-1b.mycluster.k8s.local
  	ShortName           	us-east-1b
  	VPC                 	name:mycluster.k8s.local
  	AvailabilityZone    	us-east-1b
  	CIDR                	172.20.64.0/19
  	Shared              	false
  	Tags                	{Name: us-east-1b.mycluster.k8s.local, KubernetesCluster: mycluster.k8s.local, kubernetes.io/cluster/mycluster.k8s.local: owned, SubnetType: Public, kubernetes.io/role/elb: 1}

  Subnet/us-east-1c.mycluster.k8s.local
  	ShortName           	us-east-1c
  	VPC                 	name:mycluster.k8s.local
  	AvailabilityZone    	us-east-1c
  	CIDR                	172.20.96.0/19
  	Shared              	false
  	Tags                	{kubernetes.io/role/elb: 1, Name: us-east-1c.mycluster.k8s.local, KubernetesCluster: mycluster.k8s.local, kubernetes.io/cluster/mycluster.k8s.local: owned, SubnetType: Public}

  VPC/mycluster.k8s.local
  	CIDR                	172.20.0.0/16
  	EnableDNSHostnames  	true
  	EnableDNSSupport    	true
  	Shared              	false
  	Tags                	{Name: mycluster.k8s.local, KubernetesCluster: mycluster.k8s.local, kubernetes.io/cluster/mycluster.k8s.local: owned}

  VPCDHCPOptionsAssociation/mycluster.k8s.local
  	VPC                 	name:mycluster.k8s.local
  	DHCPOptions         	name:mycluster.k8s.local

Must specify --yes to apply changes

Cluster configuration has been created.

Suggestions:
 * list clusters with: kops get cluster
 * edit this cluster with: kops edit cluster mycluster.k8s.local
 * edit your node instance group: kops edit ig --name=mycluster.k8s.local nodes
 * edit your master instance group: kops edit ig --name=mycluster.k8s.local master-us-east-1a

Finally configure your cluster with: kops update cluster --name mycluster.k8s.local --yes

Finished: SUCCESS
```

