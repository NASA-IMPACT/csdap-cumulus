output "vpc_id" {
  value = data.aws_vpc.ngap_vpc.id
}

output "subnets" {
  value = data.aws_subnets.ngap_subnets
}
