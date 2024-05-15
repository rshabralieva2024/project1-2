# main.tf
provider "aws" {
  region = "us-east-2"
}

module "vpc" {
  source  = "./modules/vpc"
}