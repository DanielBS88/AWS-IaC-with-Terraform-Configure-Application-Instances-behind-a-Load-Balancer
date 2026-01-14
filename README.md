AWS IaC with Terraform: Configure Application Instances behind a Load Balancer

Lab Description
The objective of this lab is to use the pre-existing resources, such as VPC, Security Groups, and an Instance Profile, to build a fully functioning deployment with compute nodes running behind an Application Load Balancer. This involves creating and configuring a Launch Template with a start-up script, deploying an Auto Scaling Group for instance management, and provisioning an Application Load Balancer for traffic distribution. Additionally, compute instances must execute a start-up script to generate and upload a formatted text file to cloud object storage upon launch.
Common Task Requirements
•	Do not define the backend in the configuration; Terraform will use the local backend by default.
•	Avoid the usage of the local-exec provisioner.
•	The use of the prevent_destroy lifecycle attribute is prohibited.
•	Use versions.tf to define the required versions of Terraform and its providers.
•	Define the Terraform required_version as >= 1.5.7.
•	All variables must include valid descriptions and type definitions, and they should only be defined in variables.tf.
•	Resource names provided in tasks should be defined via variables or generated dynamically/concatenated (e.g., in locals using Terraform functions). Avoid hardcoding in resource definitions or using the default property for variables.
•	Configure all non-sensitive input parameter values in terraform.tfvars.
•	Outputs must include valid descriptions and should only be defined in outputs.tf.
•	Ensure TF configuration is clean and correctly formatted. Use the terraform fmt command to rewrite Terraform configuration files into canonical format and style.
1.	The following pre-provisioned resources are available and ready for use:
- VPC: cmtr-k5vl9gpq-vpc Pre-configured Virtual Private Cloud.
- Subnets: Subnets within the VPC for deploying resources:
o	"public_subnet_cidr_a": "10.0.1.0/24",
o	"private_subnet_cidr_a": "10.0.2.0/24",
o	"public_subnet_cidr_b": "10.0.3.0/24",
o	"private_subnet_cidr_b": "10.0.4.0/24"
o	Security Groups:
o	cmtr-k5vl9gpq-ec2_sg: Allows SSH access.
o	cmtr-k5vl9gpq-http_sg: Allows HTTP access to the instances.
o	cmtr-k5vl9gpq-sglb: Allows HTTP access to the Load Balancer.
o	IAM Instance Profile: cmtr-k5vl9gpq-instance_profileGrants permissions for compute instances to interact with AWS services.
o	Key Pair: cmtr-k5vl9gpq-keypair for SSH access to the instances.
2.	Familiarize yourself with key AWS resources:
- Launch Templates
- Auto Scaling Groups
- Application Load Balancers
3.	Make sure the following information is available:
- Amazon Machine Image (AMI) ID: ami-09e6f87a47903347c
- AWS Region: us-east-1


Task Resources
•	AWS Launch Template (cmtr-k5vl9gpq-template): Configures the settings for launching compute instances.
•	AWS Auto Scaling Group (cmtr-k5vl9gpq-asg): Dynamically manages compute instances behind the Application Load Balancer.
•	AWS Application Load Balancer (cmtr-k5vl9gpq-loadbalancer): Distributes incoming traffic across instances in the Auto Scaling Group.
•	AWS Security Groups:
•	cmtr-k5vl9gpq-ec2_sg: Allows SSH access.
•	cmtr-k5vl9gpq-http_sg: Allows HTTP access to compute instances.
•	cmtr-k5vl9gpq-sglb: Allows HTTP access to the Load Balancer.
•	Cloud Object Storage: Used for storing the generated files from compute instances.
•	Tags for resources:
•	Terraform=true
•	Project=cmtr-k5vl9gpq

Objectives
File Setup:
Create the following Terraform files: application.tf to define all resources for this task.
Launch Template Configuration:
Define an AWS Launch Template (cmtr-k5vl9gpq-template) with the following parameters:
- Name: cmtr-k5vl9gpq-template
- Instance type: t3.micro
- Security Groups: cmtr-k5vl9gpq-ec2_sg and cmtr-k5vl9gpq-http_sg
- Network interface setting: delete_on_termination=true
- Key Pair Name: ${ssh_key_name}
- IAM Instance Profile: cmtr-k5vl9gpq-instance_profile
- Add the start-up bash script to the user_data field.
- metadata_options: http_endpoint = "enabled" http_tokens = "optional"
Auto Scaling Group Configuration:
Create an Auto Scaling Group (cmtr-k5vl9gpq-asg) using the Launch Template:
- Name: cmtr-k5vl9gpq-asg
- Desired capacity: 2
- Minimum size: 1
- Maximum size: 2
- Add a lifecycle configuration block to ignore changes to load_balancers and target_group_arns.
Application Load Balancer Configuration:
Provision an Application Load Balancer (cmtr-k5vl9gpq-loadbalancer) with the following settings:
- Name: cmtr-k5vl9gpq-loadbalancer
- Listener: HTTP protocol on port 80
- Attach the Load Balancer to the Auto Scaling Group using aws_autoscaling_attachment.
- Assign security group cmtr-k5vl9gpq-sglb.
Bash Start-Up Script:
In the user_data field of the Launch Template, you need to include a startup bash script that performs the following tasks when the instance first boots up:
- Updates the system packages.
- Installs necessary utilities and components required to set up a basic web server (e.g., aws-cli, httpd, jq).
- Enables the web server to start on boot and starts it immediately.
- Retrieves metadata about the current EC2 instance (such as its instance ID and private IP address) using a secure token-based method (IMDSv2).
- Creates a simple HTML web page located at /var/www/html/index.html, which displays this instance-specific information:
       `This message was generated on instance $INSTANCE_ID with the following IP: $PRIVATE_IP`
Resource Tagging:
Tag all resources with the following:
- Terraform=true
- Project=cmtr-k5vl9gpq
Terraform Workflow:
Run the following Terraform commands:
1. terraform init to initialize the backend and provider.
2. terraform fmt to enforce standard code formatting.
3. terraform validate to ensure the configuration is valid.
4. terraform plan to preview resource changes.
5. terraform apply to deploy the defined infrastructure.

Task Verification
AWS Console Validation:
1.	Verify that all resources (Launch Template cmtr-k5vl9gpq-template, Auto Scaling Group cmtr-k5vl9gpq-asg, Application Load Balancer cmtr-k5vl9gpq-loadbalancer) are created and functioning correctly.
2.	Check the Application Load Balancer routing traffic correctly to healthy instances.
Compute Instance Validation:
1.	Ensure the start-up script successfully runs on instance launch, generating and uploading the text file to the correct location in cloud object storage.
2.	Verify the file has the correct naming convention and format.
Tagging Validation:
1.	Confirm all resources are tagged as:
- Terraform=true
- Project=cmtr-k5vl9gpq
Git Repository Validation:
1.	Ensure all Terraform files (application.tf) and the bash start-up script are committed and pushed to the Git repository.
Pipeline Validation:
If applicable, validate the infrastructure using the proctor GitLab pipeline.

Definition of DONE
•	Terraform creates all resources (cmtr-k5vl9gpq-template, cmtr-k5vl9gpq-asg, cmtr-k5vl9gpq-loadbalancer) without errors.
•	All resources are properly tagged and functional per the specified configuration.
•	Load balancer distributes traffic between two instances
•	Terraform files are committed and pushed to the Git repository.
•	GitLab pipeline validation passes, if configured.
