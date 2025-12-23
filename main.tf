terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "terraform12334"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
}

# Example EC2 Instance
resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  tags = {
    Name        = "${var.environment}-instance"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Example S3 Bucket
resource "aws_s3_bucket" "example" {
  bucket = "${var.environment}-example-bucket-${var.project_name}"
  
  tags = {
    Name        = "${var.environment}-bucket"
    Environment = var.environment
  }
}
