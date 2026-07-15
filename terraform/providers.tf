# ==============================================================================
# TERRAFORM PROVIDERS AND STATE BACKEND CONFIGURATION
# ==============================================================================
# In Terraform, Providers are plugins that translate Terraform code into cloud API
# calls (e.g. AWS, GCP, Azure, Kubernetes).
# The Backend determines where Terraform stores the 'state file' (.tfstate)
# which maps real-world resources to your configuration files.
# ==============================================================================

terraform {
  required_version = ">= 1.5.0" # Specifies the minimum Terraform CLI version required

  # Define the required plugins/providers
  required_providers {
    aws = {
      source  = "hashicorp/aws" # Provider registry path
      version = "~> 5.0"        # Allows upgrades to 5.x minor versions, but locks major version
    }
  }

  # ============================================================================
  # STATE BACKEND DEFINITION
  # ============================================================================
  # By default, Terraform saves state locally (terraform.tfstate).
  # In production, you must use a remote backend (like AWS S3) with state-locking
  # (via DynamoDB) to allow multiple developers to collaborate without conflicting.
  #
  # Example Production Remote Backend (Commented out for initial local use):
  #
  # backend "s3" {
  #   bucket         = "my-company-terraform-states"
  #   key            = "devops-practice/state.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks" # Used for concurrent state-locking
  #   encrypt        = true
  # }
  # ============================================================================
  
  backend "local" {
    path = "terraform.tfstate" # Saves state locally in the workspace directory
  }
}

# Configure the AWS Provider block
provider "aws" {
  region = var.aws_region # Parameterized AWS region loaded from variables.tf
}
