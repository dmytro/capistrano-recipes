#
# Install NPM modules and Bower, Grunt build
#

namespace :deploy do

  namespace :npm do

    desc "Remove NPM caches in case npm intall fails"
    task :fix do
      run "cd ~#{user} && #{sudo} rm -rf tmp .npm "
    end

    task :install do
      run "which npm > /dev/null || ( #{chef_solo_command} #{chef_solo_remote}/web.json )"
      run "cd ~#{user} && mkdir -p tmp .npm && #{sudo} chown -R #{user}:#{user} tmp .npm "
      run "cd #{current_release}; npm install > /tmp/npm-install.log 2>&1 "
    end
  end

  namespace :bower do
    task :install do
      run "cd #{current_release}; git config url.\"https://\".insteadOf git:// ; bower --config.interactive=false install > /tmp/bower-install.log 2>&1"
    end
  end

  namespace :grunt do
    task :build do
      run "cd #{current_release}; bundle exec grunt build > /tmp/grunt-build.log 2>&1"
    end
  end

end
after "bundle:install", "deploy:npm:install"
after "bundle:install", "deploy:bower:install"
after "deploy:bower:install", "deploy:grunt:build"
