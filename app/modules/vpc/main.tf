data "aws_vpc" "ngap_vpc" {
  tags = {
    Name = "Application VPC"
  }
}

data "aws_subnets" "ngap_subnets" {
  filter {
    name   = "tag:Name"
    values = ["Private application *a subnet", "Private application *b subnet"]
  }
}
