require 'yaml'
require 'optparse'

=begin

The OpenShift Sidecar Audit Config Generator adds a sidecar
logging container to the 'containers' definition in an
OpenShift deployment configuration template.

The script assumes the following:
 - the user has a basic ruby environment installed;
 - the user has the openshift clients installed

The script can also delete all sidecar logging containers
from a specifed deployment configuration by passing the
'--delete' flag.

=end

delete=false

opt_parser = OptionParser.new do |opt|
  opt.banner = " Usage: ruby config-generator.rb DC_NAME"
  opt.separator ""
  opt.separator " Options:"

  opt.on "-h","--help","Print help" do
    puts opt
    exit
  end

  opt.on "-v","--version","Display version" do
    puts "OpenShift Audit Sidecar Config Generator v1.0.0"
    exit
  end

  opt.on "-d","--delete","Delete audit config" do
    delete=true
  end 

  opt.separator ""

end

unless ARGV[0]
  puts opt_parser
  exit
end

opt_parser.parse!

puts "INFO :: Processing deployment config #{ARGV[0]}"
std1 = `oc export dc #{ARGV[0]} -o yaml > deployment.yml`
file = YAML::load_file('deployment.yml')

if delete
  puts "INFO :: Deleting the sidecar container config"
  cons = file["spec"]["template"]["spec"]["containers"]
  cons.delete_if do |c|
    if c["name"] == "logging-sidecar"
      true
    end
  end
  # Set the containers back again
  file["spec"]["template"]["spec"]["containers"] = cons
else
  puts "INFO :: Patching the sidecar container config"
  template = YAML::load_file('template-fragment.yml')
  file["spec"]["template"]["spec"]["containers"] << template
end

# Patch and cleanup
File.open('new-dc.yml','w') {|f| f.write file.to_yaml }
std2 = `oc replace -f new-dc.yml`
std3 = `rm new-dc.yml`
std4 = `rm deployment.yml`
puts "INFO :: Successfully patched deployment config #{ARGV[0]}"
