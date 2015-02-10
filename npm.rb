#
# Install NPM modules
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
      run "cd #{shared_path} && mkdir -p node_modules"
      run "cd #{current_release} && ln -nfs #{shared_path}/node_modules"
      run "cd #{current_release}#{config_sub_dir}; npm install > /tmp/npm-install.log 2>&1 "
    end
  end

end
after "bundle:install", "deploy:npm:install"
