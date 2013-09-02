# Using this as a source
# http://spin.atomicobject.com/2012/07/26/standalone-puppet-with-capistrano/
#

#
# PATH on localhost, relative to the project
#
set_default :puppet_path, File.expand_path("../puppet/", File.dirname(__FILE__))
set_default :puppet_remote,     "~#{user}/puppet" # PATH to the puppet directory on remote server
set_default :puppet_bootstrap_skip, false

namespace :puppet do

  desc "Copy puppet manifests files to remote host(s)"
  task :deploy do
    unless puppet_bootstrap_skip
      # Puppet bootstrap supposed to run *after* chef-solo
      # bootstrap. So, gem installation should work.
      sudo "-i gem install --no-ri --no-rdoc facter puppet"

      # Deploy directory with manifests.
      upload_dir puppet_path, puppet_remote
    end

  end
  
  desc "Run specified manifest"
  task :apply do
    raise "Puppet manifest file should be defined" unless manifest.exist? 
    # Run RVM/Puppet!
    sudo "puppet apply #{manifest}"
  end
end

after "chefsolo:deploy", "puppet:deploy"
