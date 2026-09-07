resource "aws_vpc" "std08_lab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "std08-lab-vpc"
  }

}
