##
### TERRAFORM VERSION
##
terraform {
  required_version = ">= 0.12.26"
}

##
### PROVIDER SETTINGS
##
#variable "aws_access_key" { type = "string" }
#variable "aws_secret_key" { type = "string" }
variable "region" {
  type = string
}

variable "azs" {
  type = list(string)
}

provider "aws" {
  #	access_key = "${var.aws_access_key}"
  #	secret_key = "${var.aws_secret_key}"
  region  = var.region
  version = "~> 3.37"
}

##
### Database
##
variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_pass" {
  type = string
}

variable "db_instance_type" {
  type = string
}

#############################################################
# Data sources to get VPC and default security group details
#############################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

module "postgres_sg" {
  source              = "terraform-aws-modules/security-group/aws//modules/postgresql"
  name                = "postgresql-sg"
  description         = "Security group with postgresql port open for HTTP security group created above (computed)"
  vpc_id              = data.aws_vpc.default.id
  ingress_cidr_blocks = ["0.0.0.0/0"]
}

#############################################################
# Database
#############################################################
resource "aws_db_instance" "mydb" {
  allocated_storage      = 5
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "12.7"
  instance_class         = var.db_instance_type
  name                   = var.db_name
  username               = var.db_user
  password               = var.db_pass
  skip_final_snapshot    = "true"
  publicly_accessible    = "true"
  vpc_security_group_ids = [module.postgres_sg.security_group_id]
}

output "vault_db_connection_string" {
  value = "postgresql://${var.db_user}:${var.db_pass}@${aws_db_instance.mydb.address}:5432/${var.db_name}"
}

