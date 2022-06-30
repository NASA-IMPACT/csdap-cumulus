require "aws-sdk-lambda"
require "aws-sdk-ssm"

module Helpers
  module_function

  def get_parameters(names)
    # Aws::SSM::Client#get_parameters limits the number of names to 10, so we
    # need to make multiple calls to #get_parameters to get all of them. Ugh!
    # See https://docs.aws.amazon.com/systems-manager/latest/APIReference/API_GetParameters.html

    client = Aws::SSM::Client.new

    loop = lambda { |acc, names|
      return acc if names.length == 0

      head = client.get_parameters(names: names.take(10), with_decryption: true)
      tail = loop.call(acc, names.drop(10))

      {
        parameters: head[:parameters] + tail[:parameters],
        invalid_parameters: head[:invalid_parameters] + tail[:invalid_parameters],
      }
    }

    loop.call({ parameters: [], invalid_parameters: [] }, names)
  end

  #
  # Determines the list of missing AWS SSM Parameters by parsing the JSON in the
  # file `ssm_parameters.tf.json` (generated during the Terraspace build process
  # from the file `app/stacks/cumulus/ssm_parameters.rb`).  A parameter is "missing"
  # if it either does not exist or it has a value of "TBD".
  #
  def get_missing_parameters(runner)
    params_json = File.read(File.join(runner.mod.cache_dir, "ssm_parameters.tf.json"))
    params = JSON.parse(params_json)['data']['aws_ssm_parameter'].values()
    name_to_description = Hash[params.map {|p| [p["name"], p["//"]]}]
    names = name_to_description.keys()
    resp = get_parameters(names)

    # Parameter names for parameters that have the value "TBD"
    tbds = resp[:parameters].select { |p| p["value"] == "TBD" }.map { |p| p["name"] }
    # Parameter names for parameters that do not exist
    invalids = resp[:invalid_parameters]

    (invalids + tbds).map { |name|
      {
        name: name,
        description: name_to_description[name],
      }
    }
  end

  def put_parameter(name:, description:, value:)
    client = Aws::SSM::Client.new
    client.put_parameter(
      name: name,
      description: description,
      type: "SecureString",
      value: value.empty? ? "TBD" : value,
      overwrite: true,
    )
  end
end

class SetLambdaMemorySizes
  def call(runner)
    puts
    puts "NOTE: Manually setting built-in Cumulus AWS Lambda Function memory"
    puts "sizes as necessary, until Cumulus provides the ability to set them"
    puts "via Terraform configuration.  This should be removed and performed"
    puts "in the appropriate tf or tfvars file(s) when supported by Cumulus."
    puts "(See #{__FILE__.delete_prefix(Dir.pwd).delete_prefix('/')})"

    client = Aws::Lambda::Client.new

    memory_sizes = {
      "PostToCmr": 512,
    }

    memory_sizes.each do |name, size|
      #
      # This value is duplicated in the following places.  When making a change, you
      # must make the appropriate change in ALL locations:
      #
      # - Dockerfile (CUMULUS_PREFIX)
      # - app/stacks/cumulus/config/hooks/terraform.rb (function_name)
      # - config/terraform/tfvars/base.tfvars (prefix)
      #
      function_name = "cumulus-#{Terraspace.env}-#{name}"

      puts
      puts "~ #{function_name} -> #{size} MB"

      client.update_function_configuration(
        function_name: function_name,
        memory_size: size,
      )
    end

    puts
  end
end

class EnsureSsmParametersExist
  include Helpers

  def call(runner)
    get_missing_parameters(runner).each do |param|
      put_parameter(**param, value: "TBD")
    end
  end
end

class InteractivelySetSsmParameters
  include Helpers

  def call(runner)
    missing_parameters = get_missing_parameters(runner)

    if not missing_parameters.empty?
      if ENV["TF_IN_AUTOMATION"]
        raise (
          "The following AWS SSM Parameters are missing, but cannot be" +
          " supplied interactively because TF_IN_AUTOMATION is set:" +
          " #{missing_parameters.map { |p| p[:name] }}." +
          " Set the specified parameters and rerun the command."
        )
      end

      expander = TerraspacePluginAws::Interfaces::Expander.new(runner.mod)

      puts
      puts "-----------------------------------------------------------------"
      puts "Environment (TS_ENV): #{Terraspace.env}"
      puts "AWS Account ID      : #{expander.account}"
      puts "-----------------------------------------------------------------"
      puts
      puts "The following parameters must be supplied:"
      puts

      missing_parameters.each do |param|
        puts "  * #{param[:description]} (#{param[:name]})"
      end

      puts
      puts "If you do not know the correct value to supply for any parameter,"
      puts "EITHER press Ctrl-C to exit OR press Enter/Return to skip a parameter"
      puts "and continue.  The next time you deploy, you will be re-prompted for"
      puts "any previously unspecified parameters."
      puts

      missing_parameters.each do |param|
        name = param[:name]
        description = param[:description]
        print "#{description} (#{name}): "
        value = $stdin.gets.chomp

        if value.empty?
          puts "Skipping #{description} (#{name})"
        end

        put_parameter(**param, value: value)
      end
    end
  end
end

before("plan", execute: EnsureSsmParametersExist)
before("apply", execute: InteractivelySetSsmParameters)

before("plan", "apply",
  execute: %Q[bin/ensure-buckets-exist.sh $(echo "var.buckets" | terraform console | grep '"name" = ' | sed -E 's/.*= "([^"]*)"/\\1/')]
)

# Technically speaking, we only need to do this after "apply", but we're also
# doing it after "plan" so that we can fail-fast, if there is an issue, and the
# operation is fast and free, so there's no problem doing it twice.
after("plan", "apply", execute: SetLambdaMemorySizes)
