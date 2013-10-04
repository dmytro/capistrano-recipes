require 'chef/knife'
require 'chef/application/solo'
require 'chef/data_bag_item'
require 'pathname'

##
# Read databag on local host, using custom directory if it is defined.
#
def get_data_bag bag, item=nil
  Chef::Config[:solo] = true
  Chef::Config[:data_bag_path] = "#{(exists?(:custom_chef_solo) ? custom_chef_solo : chef_solo_path)}/data_bags"

  if item
    Chef::DataBagItem.load(bag, item.to_s).raw_data
  else
    Chef::DataBag.load(bag)
  end

end

##
# Return relative path to the recipe file. Use in recipe documentation.
#
def path_to file
  Pathname.new(file).relative_path_from(Pathname.new(ENV['PWD'])).to_s
end

##
# Parse ERB template from tempaltes directory and upload to target server.
#
# @param [File] __file__ - if not provided then templates are assumed
#     to be in ../templates directory relative to this file, otherwise
#     in the same directory relative to the __file__ parameter.
#
def template(from, to, __file__=nil, options: {})
  erb = File.read(File.expand_path("../templates/#{from}", __file__ || __FILE__))
  put ERB.new(erb,0,'<>%-').result(binding), to, options
end

def set_default(name, *args, &block)
  set(name, *args, &block) unless exists?(name)
end

# Runs +command+ as root invoking the command with su -c
# and handling the root password prompt.
#
#   surun "/etc/init.d/apache reload"
#   # Executes
#   # su - -c '/etc/init.d/apache reload'
#
def surun(command)
  password = Capistrano::CLI.password_prompt("root password: ")

  options = { shell: :bash, pty: true }
  options.merge! hosts: only_hosts if exists? :only_hosts

  run("su - -c '#{command}'", options) do |channel, stream, output|
    channel.send_data("#{password}\n") if output
  end

end

# Try to execute command with sudo, if it fails fallback to surun.
#
def sudo_or_su(command)
  begin
    sudo command
  rescue
    puts <<-EMSG

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Sudo is not installed (or not configured)
following commands will be executed with root password.

#{command}

Please type root password at the prompt.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

EMSG
    surun(command)
  end
end

# Runs command remotely and return 0 or other status code
#
# @param cmd Shell command to tun
#
# @return true or false
def test_command cmd

  cmd << " > /dev/null 2>&1 ; echo $?"
  return(capture(cmd, shell: :bash, pty: true).strip.to_i == 0)
end

set_default :recipe_base, "lib"

#
# DSL extensions. Some functions to extend current Capistrano DSL with
# ofthen used patterns.
# ==================================================================

##
# Load additional recipes from file.
#
# @param name [String,Symbol] name of the recipe file, symbolized,
#     without .rb extension.
#
# @param local [Boolean] If `true` try to load recipe from
#     `local_recipes` subdirectory. Otherwise use subdirectory
#     `recipes`. Recipes is git submodule with generic recipes, while
#     `local_recipes` is local subdirectory with collection of the
#     recipes that are used only in the current project.
#
def recipe name, local = false
  path = local ? "local_recipes" : "recipes"
  load File.expand_path("#{recipe_base}/#{path}/#{name.to_s}.rb")
end

##
# Tar directory locally and send it to remote location, untarring
#
# @param local [String]
#
# @param remote [String]
#
# @apram exclude: [Array] list of local subdirectories, regexp's to
#     exclude from tar'ing. Arguments to tar's --exclude command. By
#     default always exclude .git subdirectory.
#
def upload_dir local, remote, options: {}, exclude: ["./.git"]
  begin
    temp = %x{ mktemp /tmp/captemp-tar.XXXX }.chomp
    run_locally "cd #{local} && tar cfz #{temp} #{exclude.map { |e| "--exclude #{e}" }.join(' ')} ."
    upload temp, temp
    run "mkdir -p #{remote} && cd #{remote} && tar xfz #{temp}", options
  ensure
    run_locally "rm -f #{temp}"
    run  "rm -f #{temp}", options
  end
end
