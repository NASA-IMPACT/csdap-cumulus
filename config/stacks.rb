# config/stacks.rb

# To ensure the stacks are stood up in the correct/expected order.

stack "rds-cluster"

stack "data-persistence" do
  depends_on "rds_cluster"
end

stack "cumulus" do
  depends_on "data-persistence"
end

stack "post-deploy-mods" do
  depends_on "cumulus"
end

