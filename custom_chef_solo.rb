#
# @author Dmytro Kovalov, dmytro@coiney.com
#
set_default :custom_chef_solo, File.expand_path("../custom_chef_solo", File.dirname(__FILE__))
set_default :custom_chef_solo_skip, false

namespace :chefsolo do 
  desc <<-DESC
  Copy custom configuration files to the remote host

  This will copy custom configuration to the remote host into the same
  directory  where chef-solo  is installed,  therefore adding  messing
  files  or   overwriting  files   that  already  exist   in  chef-solo
  repository.

  Configuration 
  -------------

  set `-S custom_chef_solo_skip=true` to skip execution of this task.

  Source file: #{File.basename(__FILE__)}

DESC

  task :custom do 
    options = { shell: :bash, pty: true }
    unless chef_solo_bootstrap_skip ||  exists?(:custom_chef_solo_ran)
      upload_dir custom_chef_solo, chef_solo_remote, exclude: %w{./.git ./tmp}, options: options
      set :custom_chef_solo_ran, true # Ensure it runs only once in each deploy
    end
  end
end

before "chefsolo:roles",  "chefsolo:custom" unless fetch(:custom_chef_solo_skip, true)
after  "chefsolo:deploy", "chefsolo:custom" unless fetch(:custom_chef_solo_skip, true)
