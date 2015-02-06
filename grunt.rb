#
# Install Grunt build
#

namespace :deploy do

  namespace :grunt do
    task :build do
      run "cd #{current_release}#{config_sub_dir}; bundle exec grunt build "; #> /tmp/grunt-build.log 2>&1"
    end
  end

end
after "deploy:bower:install", "deploy:grunt:build"
