
# AWS Golden AMI CI/CD Infrastructure with Terraform and Python

### Overview  
This repository provides a fully automated, production-grade AWS infrastructure provisioning and AMI pipeline system built using **Terraform** and **Python**.  
It demonstrates **Immutable Infrastructure** and **Golden AMI-based CI/CD** principles to create scalable multi-tier architecture consisting of VPC, subnets, load balancers, autoscaling groups, RDS database, and end-to-end automation that continuously updates application templates on new deployments.  

***

## Architecture Summary  

The solution provisions a **highly available three-tier architecture** across two Availability Zones in AWS using Terraform, and automates image baking and autoscaling updates via custom Python scripts.  

### Components  

#### **1. Terraform Infrastructure (`infra/`)**
After running `terraform apply` from the *infra* directory, the following resources are provisioned:  

- **Networking Layer**
  - **VPC:** One VPC configured with **6 subnets** spanning **two Availability Zones**  
    - AZ-1:  
      - `Public-Web-Subnet-AZ-1`  
      - `Private-App-Subnet-AZ-1`  
      - `Private-DB-Subnet-AZ-1`
    - AZ-2:  
      - `Public-Web-Subnet-AZ-2`  
      - `Private-App-Subnet-AZ-2`  
      - `Private-DB-Subnet-AZ-2`
  - Proper routing tables and associations for high availability and isolation.  

- **Security Groups**
  - `Internet_Facing_LB_SG`: Public ALB inbound rules (HTTP/HTTPS)
  - `Web_Instance_SG`: For frontend instances behind LB
  - `Internal_LB_SG`: Load balancer for backend communication
  - `App_Instance_SG`: For backend EC2 layer
  - `DB_SG`: RDS database access from backend layer
  - `ssm_endpoint_sg`: Access control for Systems Manager Session Manager
  - `builder_instance_sg`: Used by temporary AMI builder instances  

- **Session Manager Endpoints**
  - Three private endpoints created for secure, direct access to private instances using AWS Session Manager.  

- **Database Layer**
  - **Amazon RDS (MySQL/PostgreSQL)** hosted in private subnets (`Private-DB-Subnet-AZ-1`, `Private-DB-Subnet-AZ-2`) for redundancy.  

- **Compute Layer**
  - **Launch Templates:**  
    - `frontend-template`  
    - `backend-template`  
    - Both initially reference **base Amazon Linux AMI** (no app preloaded).
  - **Auto Scaling Groups:**  
    - One for **frontend** and one for **backend** instances.  
    - Initially each group launches **1 instance**, marked unhealthy until application AMIs are baked and updated.

- **Target Groups**
  - `frontend-tg` and `backend-tg` linked to their corresponding autoscaling setups.

***

#### **2. Python AMI Automation (`scripts/`)**
The scripts directory implements a **Golden AMI CI/CD pipeline** using a Python module (6–7 files).  
This module transforms dynamically built instances into production-ready AMIs, then updates autoscaling groups with the latest launch templates automatically.

### Workflow  

1. **AMI Builder Instances:**  
   - Python scripts launch 2 **temporary EC2 instances** in **Public Subnets** with public IPs.  

2. **Bootstrapping (User Data):**  
   - Each instance executes a **user data** sequence that:  
     - Clones source code from GitHub.  
     - Installs dependencies and environment packages.  
     - Configures and pre-validates application setup.  

3. **AMI Creation:**  
   - Once configuration completes, the Python module creates **2 AMIs** — one for the frontend and one for the backend.  

4. **Launch Template Update:**  
   - The pipeline then:  
     - Creates **new launch template versions** for both frontend and backend.  
     - Updates **Auto Scaling Groups (ASGs)** to use the **newest AMI versions**.  

5. **Cleanup:**  
   - After successful updates, the temporary builder instances are **automatically terminated**.  

This maintains an **immutable deployment model**, where every update rolls out new instances from freshly baked golden images, ensuring consistency and reliability across environments.

***

## Folder Structure  

```bash
project-root/
│
├── infra/                     # Terraform Infrastructure Code (10–15 files)
│   ├── main.tf
│   ├── variables.tf
│   ├── vpc.tf
│   ├── subnets.tf
│   ├── security_groups.tf
│   ├── endpoints.tf
│   ├── rds.tf
│   ├── autoscaling.tf
│   ├── loadbalancers.tf
│   ├── outputs.tf
│   └── ...
│
└── scripts/                   # Python-based Golden AMI Pipeline
    ├── main.py
    ├── ami_builder.py
    ├── launch_template_updater.py
    ├── autoscaling_updater.py
    ├── aws_helpers.py
    ├── config.py
    └── cleanup.py
```

***

## How to Use  

### 1. Provision Infrastructure  
```bash
cd infra
terraform init
terraform apply
```
This step creates the full base infrastructure including VPC, subnets, RDS, ALBs, and ASGs.

### 2. Run Golden AMI Pipeline  
```bash
cd ../scripts
python3 main.py
```
This triggers AMI creation and autoscaling updates. You’ll see:
- Temporary builder EC2s being launched in public subnets
- User data executing build process
- New AMIs created in AWS AMI console
- ASGs updated to latest launch template versions
- Builder instances terminated automatically

***

## Key Technical Highlights  

- Fully automated **Infrastructure as Code (IaC)** via Terraform.  
- End-to-end **Golden AMI pipeline** using only native AWS services (without third-party CI/CD).  
- Immutable application deployment model with **versioned launch templates**.  
- Secure private access using **AWS Session Manager endpoints** (no bastion host required).  
- Scalable and HA-ready setup following best AWS networking and security practices.  

***

## Future Enhancements  

- Integration with **CodePipeline/CodeBuild** for scheduled AMI refresh.  
- Adding **Terraform remote backend (S3 + DynamoDB)** for state management.  
- Multi-environment separation (Dev, Stage, Prod).  
- Automatic health checking and rollback support in automation layer.  

***