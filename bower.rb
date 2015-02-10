#
# Install Bower
#

namespace :deploy do

  namespace :bower do
    task :install do
      run "cd #{current_release}#{config_sub_dir}; git config url.\"https://\".insteadOf git:// ; bower --config.interactive=false install > /tmp/bower-install.log 2>&1"
    end
  end

end
after "bundle:install", "deploy:bower:install"
