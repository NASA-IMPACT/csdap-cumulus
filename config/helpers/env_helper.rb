module Terraspace::Project::EnvHelper
  ##
  # Returns +true+ if the current AWS account is an "old" account (that is, not
  # a CBA account); +false+ otherwise.

  def in_cba?
    account = expansion(':ACCOUNT')
    # Does the current AWS account ID end with one of the account ID suffixes
    # of the "old" (non-CBA) accounts?  (Suffixes are used simply to avoid
    # putting full account IDs in the source code, for extra security.)
    %w{8451 7469 5982}.none? { |suffix| account.end_with? suffix }
  end

  def in_sandbox?
    %w{uat sit prod ops}.none?{ |env_part|
      Terraspace.env.downcase.include? env_part
    }
  end

  ##
  # Returns a standard bucket name using the specified +slug+ for consistent,
  # non-conflicting and universally unique names.  This allows for using the
  # same +TS_ENV+ value in different AWS accounts because the last 4 digits of
  # the AWS account ID is used to make the bucket name universally unique.

  def bucket(slug)
    # Since we will need to maintain our existing deployments in conjunction
    # with standing up deployments in our new CBA accounts, we need to
    # accommodate buckets in both sets of accounts in a way that avoids name
    # conflicts, along with not requiring name changes for the existing ones.

    prefix =
      if !in_cba? && Terraspace.env == "uat" then
        # The "old" UAT buckets were created before any naming convention was
        # in place, and were also already configured to connect to the Metrics
        # Team's bucket, so could not be changed.  Therefore, the bucket name
        # prefix is "hard-coded".
        "csdap-uat-"
      else
        "#{if in_cba? then "csda" else "csdap" end}-cumulus-#{Terraspace.env}-"
      end

    # The buckets in the old accounts, don't include the last 4 digits of the
    # AWS account ID (because there was no anticipation of having to migrate to
    # new accounts), so they have no suffix.  Only the buckets in the new CBA
    # accounts will include a suffix in order to avoid name conflicts.
    suffix = if in_cba? then "-#{expansion(':ACCOUNT')[-4..]}" else "" end

    "#{prefix}#{slug}#{suffix}"
  end
end
