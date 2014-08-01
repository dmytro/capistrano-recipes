#
# Install NPM modules and Bower, Grunt build
#

namespace :deploy do

  namespace :npm do
    task :install do
      run "which npm > /dev/null || ( #{chef_solo_command} #{chef_solo_remote}/web.json )"
      run "cd #{current_release}; npm install --silent"
    end
  end

  namespace :bower do
    task :install do
      run "cd #{current_release}; git config url.\"https://\".insteadOf git:// ; bower --config.interactive=false install"
    end
  end

  namespace :grunt do
    task :build do
      run "cd #{current_release}; bundle exec grunt build"
    end
  end

end
after "bundle:install", "deploy:npm:install"
after "bundle:install", "deploy:bower:install"
after "deploy:bower:install", "deploy:grunt:build"
