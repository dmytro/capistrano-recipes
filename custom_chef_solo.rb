#
# @author Dmytro Kovalov, dmytro@coiney.com
#

# This will copy custom configuration to the remote host into
# the same directory where chef-solo is installed, therefore adding
# messing files or overwriting files that already exist in chef-sol
# repository.

set_default :custom_chef_solo, File.expand_path("../custom_chef_solo", File.dirname(__FILE__))

namespace :chefsolo do 
  desc "Copy custom configuration files to the remote host"
  task :custom do 


    options = { shell: :bash, pty: true }
    unless chef_solo_bootstrap_skip ||  exists?(:custom_chef_solo_ran)
      upload_dir custom_chef_solo, chef_solo_remote, exclude: %w{./.git ./tmp}, options: options
      set :custom_chef_solo_ran, true # Ensure it runs only once in each deploy
    end
  end
  
end

before "chefsolo:roles",  "chefsolo:custom"
after  "chefsolo:deploy", "chefsolo:custom"
