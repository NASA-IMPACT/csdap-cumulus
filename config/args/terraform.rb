# See https://terraspace.cloud/docs/config/args/terraform/

command("init",
  args: ["-no-color", "-reconfigure", "-upgrade"],
)
command("plan",
  args: ["-no-color", "-refresh=false"],
)
command("apply",
  args: ["-no-color"],
)
