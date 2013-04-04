set_default(:unicorn_user) { user }
set_default(:unicorn_timeout, 30)
set_default(:unicorn_workers, 1)
set_default(:unicorn_pid) { "#{shared_path}/pids/unicorn.pid" }
set_default(:unicorn_config) { "#{shared_path}/config/unicorn.rb" }
set_default(:unicorn_err_log) { "#{shared_path}/log/unicorn.stderr.log" }
set_default(:unicorn_out_log) { "#{shared_path}/log/unicorn.stdout.log" }

namespace :unicorn do

  start_unicorn  = "cd #{current_path}; bundle exec unicorn -E production -c #{current_path}/config/unicorn.rb -D"
  reload_unicorn = "kill -s USR2 `cat #{unicorn_pid}`"

  desc "Setup Unicorn initializer and app configuration"
  task :setup, roles: :app do
    run "mkdir -p #{shared_path}/config"
    template "unicorn.rb.erb", unicorn_config
  end
  after "deploy:setup", "unicorn:setup"

  desc "Symlink unicorn config"
  task :symlink do
    run "ln -nfs #{unicorn_config} #{release_path}/config/unicorn.rb"
  end
  after "deploy:finalize_update", "unicorn:symlink"

  desc "Start Unicorn"
  task :start, :except => { :no_release => true } do
    run start_unicorn
  end
  after "deploy:start", "unicorn:start"

  desc "Stop Unicorn"
  task :stop, :except => { :no_release => true } do
    run "kill -s QUIT `cat #{unicorn_pid}`"
  end
  after "deploy:stop", "unicorn:stop"

  desc "Restart unicorn"
  task :restart, roles: :app do
    run "if [[ -f #{unicorn_pid} ]]; then #{reload_unicorn}; else #{start_unicorn}; fi"
  end

end
