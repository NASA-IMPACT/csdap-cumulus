require "aws-sdk-iam"

#
# Per the Cumulus deployment documentation:
#
#     Amazon Elasticsearch Service does not use a VPC Endpoint. To use ES within
#     a VPC, before deploying run:
#
#         aws iam create-service-linked-role --aws-service-name es.amazonaws.com
#
#     This operation only needs to be done once per account, but it must be done
#     for both NGAP and regular AWS environments.
#
# See https://nasa.github.io/cumulus/docs/v9.6.0/deployment/deployment-readme#vpc-subnets-and-security-group
#
# This hook simply check to see if this service linked role exists, and if not,
# it creates it so that we don't have to remember to do this manually before
# deploying the first Cumulus deployment to a given AWS account.
#
class EnsureElasticsearchServiceLinkedRoleExists
  def call(runner)
    client = Aws::IAM::Client.new

    begin
      client.get_role(role_name: "AWSServiceRoleForAmazonElasticsearchService")
    rescue Aws::IAM::Errors::NoSuchEntity
      puts "Creating AWS IAM service linked role for service 'es.amazonaws.com'"
      client.create_service_linked_role(aws_service_name: "es.amazonaws.com")
    end
  end
end

before("apply", execute: EnsureElasticsearchServiceLinkedRoleExists)
