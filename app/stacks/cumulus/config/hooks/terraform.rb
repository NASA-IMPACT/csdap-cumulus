require "aws-sdk-ssm"

#
# Ensures that all AWS SSM Parameters are set.
#
# Determines the list of required AWS SSM Parameters by parsing the JSON in the
# file `ssm_parameters.tf.json` (generated during the Terraspace build process
# from the file `app/stacks/cumulus/ssm_parameters.rb`).  Then attempts to get
# parameter values from AWS, and for each parameter that does not exist, prompts
# the user for the value and sets the parameter.
#
# If the environment variable `TF_IN_AUTOMATION` is set (to any value), raises
# an exception rather than prompting the user, if any parameters are missing.
#
class EnsureSsmParametersExist
  def call(runner)
    params_json = File.read(File.join(runner.mod.cache_dir, "ssm_parameters.tf.json"))
    params = JSON.parse(params_json)['data']['aws_ssm_parameter'].values()
    name_to_description = Hash[params.map {|p| [p["name"], p["//"]]}]
    names = name_to_description.keys()

    client = Aws::SSM::Client.new
    resp = client.get_parameters(names: names, with_decryption: true)
    invalid_parameters = resp[:invalid_parameters]

    if not invalid_parameters.empty?
      if ENV["TF_IN_AUTOMATION"]
        raise (
          "The following AWS SSM Parameters are missing, but cannot be" +
          " supplied interactively because TF_IN_AUTOMATION is set:" +
          " #{invalid_parameters}.  Set the specified parameters and rerun" +
          " the command."
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

      invalid_parameters.each do |name|
        description = name_to_description[name]
        puts "  * #{description} (#{name})"
      end

      puts
      puts "If you do not know the correct value to supply for any parameter,"
      puts "you may press Ctrl-C to terminate the current Terraform process"
      puts "and rerun the command later, once you have obtained the necessary"
      puts "parameter value(s)."
      puts

      invalid_parameters.each do |name|
        description = name_to_description[name]
        print "#{description} (#{name}): "
        value = $stdin.gets.chomp
        client.put_parameter(
          name: name,
          description: description,
          type: "SecureString",
          value: value,
        )
      end
    end
  end
end

before("plan", "apply",
  execute: EnsureSsmParametersExist,
)

before("plan", "apply",
  execute: %Q[bin/ensure-buckets-exist.sh $(echo "var.buckets" | terraform console | grep '"name" = ' | sed -E 's/.*= "([^"]*)"/\\1/')]
)
