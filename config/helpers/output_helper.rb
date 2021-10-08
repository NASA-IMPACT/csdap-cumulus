module Terraspace::Project::OutputHelper
  def unquoted(obj)
    obj.to_s.gsub(/(^")|("$)/, "")
  end

  def json_output(name)
    unquoted(JSON.dump(output(name)))
  end
end
