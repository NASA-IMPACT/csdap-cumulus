class RequireDevInstance
  def call(runner)
    mod = runner.mod

    # if Terraspace.env == "dev" && mod.options.instance.isnil?
    #   raise <<~MSG

    #     For 'dev' deployments, you must specify an '--instance' option,
    #     which must be your Cumulus deployment prefix.
    #   MSG
    # end
  end
end

before("build", execute: RequireDevInstance)
