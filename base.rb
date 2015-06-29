#require 'chef/knife'
require 'chef/application/solo'
require 'chef/data_bag_item'
require 'pathname'
require 'securerandom'

$LOAD_PATH << "#{File.dirname(__FILE__)}/lib"
require "git_tags"


def fatal(str)
  sep = "\n\n#{'*' * 80}\n\n"
  abort "#{sep}\t#{str}#{sep}"
end

##
# Read databag on local host, using custom directory if it is defined.
#
def get_data_bag bag, item=nil
  Chef::Config[:solo] = true
  Chef::Config[:data_bag_path] = "#{local_chef_cache_dir}/data_bags"

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
# Ensure that application code is tagged. Deploy only code from the git tag.
#
def ensure_release_tagged
  set :branch do
    tags = GitTags.new(repository).tags
    default = tags.last
    fatal "Cannot find any tags in the repository" if default.nil?

    puts <<-PUT
********************************************
Found tags:
#{tags[-10..-1].join("\n")}
********************************************
    PUT

    tag = Capistrano::CLI.ui.ask "\n\n Choose a tag to deploy (make sure to push the tag first): [Default: #{default}] "
    tag = default if tag.empty?

    fatal "Cannot deploy as no tag was found" if tag.nil?
    tag
  end
end


##
# Parse ERB template from tempaltes directory and upload to target server.
#
# @param [File] __file__ - if not provided then templates are assumed
#     to be in ../templates directory relative to this file, otherwise
#     in the same directory relative to the __file__ parameter.
#
def template(from, to, __file__=__FILE__, options: {})
  @template_path = File.dirname(File.expand_path("../templates/#{from}", __file__))
  erb = File.read(File.expand_path("../templates/#{from}", __file__ ))
  remote_user = options.delete :as
  if remote_user
    begin
      temp = "/tmp/template_#{from.gsub("/","_")}.temp"
      put ERB.new(erb,0,'<>%-').result(binding), temp, options
      sudo "mv #{temp} #{to}", options
      sudo "chown #{remote_user} #{to}", options
    ensure
      sudo "rm -f #{temp}"
    end
  else
    put ERB.new(erb,0,'<>%-').result(binding), to, options
  end
end

##
# Partial parsing for template files.
# For nested template inclusion.
# Usage: see nginx.conf.erb for erxample
def partial file
  ERB.new(File.read(file),0,'<>%-').result(binding)
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
set_default :config_sub_dir, ""

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
#     `site/recipes` subdirectory. Otherwise use subdirectory
#     `recipes`. Recipes is git submodule with generic recipes, while
#     `site/recipes` is local subdirectory with collection of the
#     recipes that are used only in the current project.
#
def recipe name, local = false
  path = local ? "site/recipes" : "recipes"
  load File.expand_path("#{recipe_base}/#{path}/#{name.to_s}.rb")
end

##
# Tar directory locally and send it to remote location, untarring
#
# @param local [String]
#
# @param remote [String]
#
# @param exclude: [Array] list of local subdirectories, regexp's to
#     exclude from tar'ing. Arguments to tar's --exclude command. By
#     default always exclude .git subdirectory.
#
def upload_dir local, remote, options: {}, exclude: ["./.git"]
  begin
    temp = %x{ mktemp /tmp/captemp-tar.XXXX }.chomp
    remote_temp = "/tmp/captemp.#{SecureRandom.hex}"
    run_locally "cd #{local} && tar cfz #{temp} #{exclude.map { |e| "--exclude #{e}" }.join(' ')} ."
    upload temp, remote_temp
    run "mkdir -p #{remote} && cd #{remote} && tar xfz #{remote_temp}", options
  ensure
    run_locally "rm -f #{temp}"
    run  "rm -f #{remote_temp}", options
  end
end

##
# Copy directory locally using tar.
#
# @param  src [String]
#
# @param  dst [String]
#
# @param exclude: [Array] list of local subdirectories, regexp's to
#     exclude from tar'ing. Arguments to tar's --exclude command. By
#     default always exclude .git subdirectory.
def copy_dir src, dest, exclude: ["./.git"]
  run_locally "mkdir -p #{dest} && (cd #{src} && tar cf - #{exclude.map { |e| "--exclude #{e}" }.join(' ')} .) | (cd #{dest} && tar xf -)"
end
