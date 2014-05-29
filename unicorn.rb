set_default(:unicorn_user) { user }
set_default(:unicorn_timeout, 30)
set_default(:unicorn_workers, 1)
set_default(:unicorn_socket, "#{shared_path}/config/unicorn.sock")
set_default(:unicorn_pid) { "#{shared_path}/pids/unicorn.pid" }
set_default(:unicorn_config) { "#{shared_path}/config/unicorn.rb" }
set_default(:unicorn_err_log) { "#{shared_path}/log/unicorn.stderr.log" }
set_default(:unicorn_out_log) { "#{shared_path}/log/unicorn.stdout.log" }
set_default(:unicorn_port) { 5000 } # For use with Apache since Apache can't listen on socket.

namespace :unicorn do


  namespace :init_d do

    desc <<-DESC
 Install /etc/init.d file for Unicorn.

  Source file: #{path_to __FILE__}

DESC
    task :install, roles: :web, except: { no_release: true } do
      template "unicorn.init.erb", "/tmp/unicorn.init"
      run "#{sudo} mv /tmp/unicorn.init /etc/init.d/unicorn"
    end
  end


  desc <<-DESC
 Setup Unicorn initializer and app configuration.

  Source file: #{path_to __FILE__}

DESC
  task :setup, except: { no_release: true } do
    run "mkdir -p #{shared_path}/config"
  end
  after "deploy:setup", "unicorn:setup"

  desc <<-DESC
 Generate and copy unicorn config.

  Source file: #{path_to __FILE__}

DESC
  task :copy, roles: :web, except: { no_release: true }  do
    template "unicorn.rb.erb", unicorn_config
  end
  before "unicorn:symlink", "unicorn:copy"
  before "unicorn:copy",    "unicorn:setup"


  desc <<-DESC
 Symlink unicorn config.

  Source file: #{path_to __FILE__}

DESC
  task :symlink, roles: :web, except: { no_release: true }  do
    run "ln -nfs #{unicorn_config} #{release_path}/config/unicorn.rb"
  end
  after "deploy:finalize_update", "unicorn:symlink"

  desc <<-DESC
 [internal] Set commands for Unicorn restart/reload.

  Source file: #{path_to __FILE__}

DESC
  task :variables do
    # Need to run this in task - variables are task-level namespaced
    set :unicorn_start,   "(echo '*** Starting Unicorn'; cd #{current_path} && bundle exec unicorn -E #{rails_env} -c #{current_path}/config/unicorn.rb -D)"
    set :unicorn_reload,  "(echo '*** Reloading Unicorn'; kill -s USR2 `cat #{unicorn_pid}`)"
    set :unicorn_stop,    "(echo '*** Stopping Unicorn'; kill `cat #{unicorn_pid}`)"
    set :unicorn_running, "(test -f #{unicorn_pid} && ps $(cat #{unicorn_pid}) > /dev/null)"
  end


  desc <<-DESC
 Start Unicorn.

  Source file: #{path_to __FILE__}

DESC
  task :start, :except => { :no_release => true } do
    run unicorn_start
  end

  desc <<-DESC
 Stop Unicorn.

  Source file: #{path_to __FILE__}

DESC
  task :stop, :except => { :no_release => true } do
    run unicorn_stop
  end

  desc <<-DESC
 Reload Unicorn.

This will send `kill -USR2` to Unicorn master which allows for
no-downtime reloadds of all unicorn children processes.

Source file: #{path_to __FILE__}

DESC
  task :reload, roles: :web, except: { no_release: true }  do
    run "if #{unicorn_running}; then #{unicorn_reload}; else #{unicorn_start}; fi"
  end

  desc <<-DESC
 Restart unicorn.

  Source file: #{path_to __FILE__}

DESC
  task :restart, roles: :web, except: { no_release: true }  do
    run "if #{unicorn_running}; then #{unicorn_stop}; fi; #{unicorn_start}"
  end

  namespace :logs do

    desc <<-DESC
 Tail Unicorn logs.

  Source file: #{path_to __FILE__}

DESC
    task :tail do
      trap("INT") { puts 'Interupted'; exit 0; }
      run "tail -f #{shared_path}/log/unicorn*.log" do |channel, stream, data|
        puts  # for an extra line break before the host name
        puts "#{channel[:host]}: #{data}"
        break if stream == :err
      end
    end

    desc <<-DESC
 Clear all Unicorn logs.

  Source file: #{path_to __FILE__}

DESC
    task :clear do
      run "for i in #{shared_path}/log/unicorn*; do cat /dev/null > $i; done"
    end
end

end

before "unicorn:reload", "unicorn:variables"
before "unicorn:start", "unicorn:variables"
before "unicorn:restart", "unicorn:variables"
after "deploy:start", "unicorn:start"
after "deploy:stop", "unicorn:stop"
