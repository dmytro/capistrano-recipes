#
# Deploy ghost contents
#

namespace :ghost do

  desc <<-EOH

Create symlink to the current release for ghost.

EOH

  task :create_symlink do
    on_rollback do
      if latest_release
        run "#{try_sudo} rm -f #{ghost_content_path}/themes/coiney; #{try_sudo} ln -s #{latest_release}/themes/coiney #{ghost_content_path}/themes/coiney; true"
      else
        logger.important "ghost : no previous release to rollback to, rollback of symlink skipped"
      end
    end
    run "#{try_sudo} rm -f #{ghost_content_path}/themes/coiney && #{try_sudo} ln -s #{current_release}/themes/coiney #{ghost_content_path}/themes/coiney"
  end

  task :restart do
    run "#{try_sudo} /sbin/sv restart ghost"
  end
end

after "deploy:finalize_update", "ghost:create_symlink"
after "ghost:create_symlink", "ghost:restart"
