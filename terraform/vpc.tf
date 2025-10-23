module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "dotgroup-devops-vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = [for i in range(0, 3) : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i in range(3, 6) : cidrsubnet(var.vpc_cidr, 4, i)]

  enable_nat_gateway      = true
  single_nat_gateway      = true
  map_public_ip_on_launch = true
}
