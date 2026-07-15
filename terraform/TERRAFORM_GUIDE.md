# Terraform Infrastructure as Code (IaC) Guide

This guide covers the core configuration patterns and architectural concepts for **Terraform** as an Infrastructure as Code (IaC) provisioning tool, referencing the files created in the `terraform/` directory.

---

## 🧭 Syllabus Topics Explained

### 1. Variables
* **Concept**: Input parameters to customize and configure deployments. You define them in `variables.tf` and pass values using file variables (`terraform.tfvars`) or command arguments.
* **Example**:
  ```hcl
  variable "instance_type" {
      type    = string
      default = "t3.micro"
  }
  ```

---

### 2. Output
* **Concept**: Return values printed to the console after `terraform apply`. Used to output endpoints (like EC2 public IPs or RDS hostnames) to users or automation scripts.
* **Example**:
  ```hcl
  output "ec2_public_ip" {
      value = aws_instance.app_server.public_ip
  }
  ```

---

### 3. State
* **Concept**: Terraform records the state of your infrastructure in a local or remote JSON file named `terraform.tfstate`. This state is the "single source of truth" mapping configuration declarations to actual cloud resources.
* **Warning**: Never modify this file manually! If resources change outside of Terraform (e.g., in the AWS Console), Terraform updates its state during the next plan check.

---

### 4. Backend
* **Concept**: Defines where the state file is stored. By default, it's saved locally.
* **Production S3 Backend with Locking**: For production, state files are stored in an AWS S3 bucket with versioning. An AWS DynamoDB table handles state locking, preventing two developers from running updates concurrently and corrupting the state.
* **Example**:
  ```hcl
  backend "s3" {
      bucket         = "company-tf-states"
      key            = "dev/state.tfstate"
      dynamodb_table = "tf-state-locks" # Prevents concurrent runs
  }
  ```

---

### 5. Module
* **Concept**: Reusable containers for grouping multiple resources together. Instead of copy-pasting code to build a VPC in 10 files, you write a VPC module once and reference it.
* **Example**:
  ```hcl
  module "vpc" {
      source      = "./modules/vpc"
      environment = "dev"
      cidr_block  = "10.0.0.0/16"
  }
  ```

---

### 6. Created Resources

Our `main.tf` configuration provisions the following standard AWS layers:
1. **VPC & Subnets**: Builds a private network. Uses public subnets for the EC2 server and two private subnets spanning multiple Availability Zones for the database.
2. **Security Groups (Firewalls)**: 
   * **Web Server Group**: Opens port `80`, `443`, and `22` (SSH) to the public internet.
   * **Database Group**: Opens port `5432` **only** to incoming traffic originating from the Web Server Group (keeps database inaccessible to public hackers).
3. **RDS Database**: A managed Postgres instance (`db.t3.micro`) configured within the private database subnets.
4. **EC2 Instance**: An Ubuntu server virtual machine configured to run user_data scripts that bootstrap Docker on start.

---

## 🛠️ Step-by-Step Execution Guide

To use these configurations, follow these terminal instructions from the `terraform/` directory:

### Step 1: Initialize Terraform
Downloads the required AWS provider plugin and sets up the local state file:
```bash
terraform init
```

### Step 2: Format & Validate (Syntax check)
Check if your syntax and file formatting are clean:
```bash
# Formats files automatically to standard style spacing
terraform fmt

# Validates config structure and parameters
terraform validate
```

### Step 3: Run dry-run Plan
Generates a execution plan showing what resources will be created (`+`), modified (`~`), or deleted (`-`) without making actual API changes:
```bash
terraform plan
```

### Step 4: Apply Changes (Provision)
Deploys the VPC, EC2 instance, Security Groups, and RDS Postgres instance into AWS. You will be prompted to type `yes` to approve:
```bash
terraform apply
```

### Step 5: Destroy Infrastructure (Clean up)
Tears down and deletes all resources created by Terraform. Use this to clean up your AWS account and prevent cost accumulations:
```bash
terraform destroy
```
