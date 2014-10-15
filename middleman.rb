#
# Deploy middleman site

namespace :deploy do

  desc <<-EOH

Create symlink to the current release.

Replace standard capistano recipe and point current_path to
`latest_release/build` directory inside middleman deployed dir.

Source File #{path_to __FILE__}

EOH

  task :create_symlink do
    on_rollback do
      if previous_release
        run "#{try_sudo} rm -f #{current_path}; #{try_sudo} ln -s #{previous_release}/build #{current_path}; true"
       else
         logger.important "no previous release to rollback to, rollback of symlink skipped"
       end
    end

    run "#{try_sudo} rm -f #{current_path} && #{try_sudo} ln -s #{latest_release}/build #{current_path}"

  end

end

namespace :middleman do

  desc <<-EOH

build middleman site on target host.

Source File #{path_to __FILE__}

EOH
  task :build do
    run "cd #{latest_release} && bundle exec middleman build"
  end
  before "deploy:create_symlink", "middleman:build"
end
