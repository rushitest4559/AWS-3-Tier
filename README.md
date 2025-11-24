# Cost-Optimized 3-Tier AWS Architecture with Zero NAT Gateway & Automated Golden AMI Pipeline

A production-ready, secure, and cost-efficient 3-tier architecture built on AWS — designed with **zero NAT Gateway**, saving ~₹40,000/month, and powered by a fully automated **Golden AMI CI/CD pipeline** using Python + boto3.

This project combines real-world cloud design, DevOps automation, and cost optimization patterns widely used by top tech companies.

---

## 🚀 Key Highlights

* **100% Terraform IaC**: VPC, subnets, route tables, ALB, ASG, RDS, VPC endpoints, IAM roles, and more.
* **Zero NAT Gateway Architecture**:

  * Private subnets run without internet egress.
  * Outbound access via **S3, ECR, SSM, Logs, Monitoring VPC endpoints**.
  * Saves massive recurring costs.
* **Automated Golden AMI Pipeline (Python + boto3)**:

  * Launches temporary builder EC2 instances.
  * Clones app repo and installs dependencies.
  * Bakes hardened AMIs.
  * Updates Launch Templates.
  * Triggers ASG Rolling Deployments.
  * Terminates builders automatically.
* **Immutable Deployments**:

  * No in-place updates.
  * Zero downtime during refresh.
* **Bastion-Free Access**:

  * Uses AWS Session Manager for SSH/terminal access.

---

## 🏗️ Architecture Overview

```
Internet
   ↓
Public ALB
   ↓
Private Web ASG (Web Tier)
   ↓
Internal ALB
   ↓
Private App ASG (App Tier)
   ↓
Private RDS (DB Tier)

⤴ Temporary AMI Builder Instances (Public Subnets → Auto-terminated)
```

---

## 📁 Folder Structure

```
infra/       → Terraform modules & root config (VPC, ALB, ASG, RDS, endpoints)
scripts/     → Python Golden AMI Pipeline (main.py + helper modules)
```

---

## ⚙️ How to Deploy

### 1. Provision Core Infrastructure

```bash
cd infra
terraform init
terraform apply
```

### 2. Run Golden AMI Pipeline

```bash
cd ../scripts
python main.py
```

This automatically builds a new AMI, updates the Launch Template, triggers rolling updates, and safely replaces all instances.

---

## 🧰 Tech Stack

**AWS:** VPC, EC2, ALB, Auto Scaling, RDS, IAM, VPC Endpoints, Session Manager
**IaC:** Terraform (modular setup)
**Automation:** Python + boto3
**Concepts:** Immutable infra, cost optimization, secure private-tier architecture, automated AMI baking

---

## 👤 Author

Built by **Rushikesh Nikam** (Nov 2025)
GitHub: [https://github.com/rushitest4559](https://github.com/rushitest4559)

---

## 📌 Notes

* Use this as a showcase project for resumes, portfolios, and interviews.
* Rename the repo to reflect the project title.
* Update your Naukri project section with the same name.

This project represents practical knowledge, real cloud architecture, cost savings, and production-style automation — ideal for DevOps, Cloud, and SRE roles.
