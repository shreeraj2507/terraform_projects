# Deploying a VPC with Web and Database EC2 Instances in AWS Using Terraform

## Overview

This project provisions a complete AWS Virtual Private Cloud (VPC) infrastructure using Terraform. It sets up a VPC with public and private subnets, and deploys two EC2 instances:

- **Web Server (EC2)**: Deployed in the **public subnet** to serve web traffic.
- **Database Server (EC2)**: Deployed in the **private subnet** for backend database operations.

The infrastructure includes essential AWS resources such as:

- VPC
- Public and Private Subnets
- Internet Gateway
- NAT Gateway
- Route Tables and Associations
- EC2 Instances
- Security Groups
- Elastic IP (for NAT Gateway)

## File Structure

`main.tf`: Contains the core Terraform code that defines the infrastructure.
`variables.tf`: Defines the input variables used throughout the configuration.