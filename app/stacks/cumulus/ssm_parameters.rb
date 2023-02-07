#
# Terraspace generates `ssm_parameters.tf.json` from this file.
#
# All required AWS SSM Parameters should be specified in this file rather than
# in `main.tf` (or some other `.tf` file) so that the Terraspace hook in
# `config/hooks/terraform.rb` can use the generated `ssm_parameters.tf.json`
# file to prompt for missing parameters.
#
# For information about the Ruby DSL used in this file, see
# https://terraspace.cloud/docs/dsl/
#
# The "//" key is recognized in the Terraform JSON syntax as a comment (see
# https://www.terraform.io/docs/language/syntax/json.html#comment-properties),
# and is used here as an SSM parameter description.
#

# ------------------------------------------------------------------------------
# STACK-INDEPENDENT
# ------------------------------------------------------------------------------

data("aws_ssm_parameter", "launchpad_passphrase",
  "//": "Launchpad Passphrase",
  name: "/shared/cumulus/launchpad-passphrase"
)

if !in_cba? then
  data("aws_ssm_parameter", "csdap_host_url",
    "//": "CSDAP Cognito Host URL",
    name: "/shared/cumulus/csdap-host-url"
  )

  data("aws_ssm_parameter", "csdap_client_id",
    "//": "CSDAP Cognito Client ID",
    name: "/shared/cumulus/csdap-client-id"
  )

  data("aws_ssm_parameter", "csdap_client_password",
    "//": "CSDAP Cognito Client Password",
    name: "/shared/cumulus/csdap-client-password"
  )

  data("aws_ssm_parameter", "log_destination_arn",
    "//": "ESDIS Metrics CloudWatch Logs Destination ARN",
    name: "/shared/cumulus/log-destination-arn"
  )

  data("aws_ssm_parameter", "metrics_es_host",
    "//": "ESDIS Metrics Elasticsearch Host",
    name: "/shared/cumulus/metrics-es-host"
  )

  data("aws_ssm_parameter", "metrics_es_username",
    "//": "ESDIS Metrics Elasticsearch Username",
    name: "/shared/cumulus/metrics-es-username"
  )

  data("aws_ssm_parameter", "metrics_es_password",
    "//": "ESDIS Metrics Elasticsearch Password",
    name: "/shared/cumulus/metrics-es-password"
  )
end

# ------------------------------------------------------------------------------
# STACK-SPECIFIC (not shared across stacks)
# ------------------------------------------------------------------------------

data("aws_ssm_parameter", "urs_client_id",
  "//": "Earthdata Login (EDL) Application Client ID",
  name: expansion("/:ENV/cumulus/urs-client-id")
)

data("aws_ssm_parameter", "urs_client_password",
  "//": "Earthdata Login (EDL) Application Password",
  name: expansion("/:ENV/cumulus/urs-client-password")
)
