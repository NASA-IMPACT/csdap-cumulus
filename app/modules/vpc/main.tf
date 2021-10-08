data "aws_vpc" "ngap_vpc" {
  tags = {
    Name = "Application VPC"
  }
}

data "aws_subnet_ids" "ngap_subnets" {
  vpc_id = data.aws_vpc.ngap_vpc.id

  filter {
    name   = "tag:Name"
    values = ["Private application *"]
  }
}
