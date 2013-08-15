set_default(:unicorn_user) { user }
set_default(:unicorn_timeout, 30)
set_default(:unicorn_workers, 1)
set_default(:unicorn_pid) { "#{shared_path}/pids/unicorn.pid" }
set_default(:unicorn_config) { "#{shared_path}/config/unicorn.rb" }
set_default(:unicorn_err_log) { "#{shared_path}/log/unicorn.stderr.log" }
set_default(:unicorn_out_log) { "#{shared_path}/log/unicorn.stdout.log" }
set_default(:unicorn_port) { 5000 } # For use with Apache since Apache can't listen on socket.

namespace :unicorn do

  namespace :init_d do

    desc "Install /etc/init.d file for Unicorn"
    task :install do
      template "unicorn.init.erb", "/tmp/unicorn.init"
      run "#{sudo} mv /tmp/unicorn.init /etc/init.d/unicorn"
    end
  end

  start_unicorn  = "(cd #{current_path} && bundle exec unicorn -E production -c #{current_path}/config/unicorn.rb -D)"
  reload_unicorn = "( kill -s USR2 `cat #{unicorn_pid}` || true )"
  stop_unicorn = "( kill `cat #{unicorn_pid}` || true )"

  unicorn_running = "( test -f #{unicorn_pid} && ps $(cat #{unicorn_pid}) > /dev/null ) ; echo $? "

  desc "Setup Unicorn initializer and app configuration"
  task :setup, roles: :app do
    run "mkdir -p #{shared_path}/config"
    template "unicorn.rb.erb", unicorn_config
  end
  after "deploy:setup", "unicorn:setup"

  desc "Copy unicorn config"
  task :copy do
    upload "config/unicorn.rb", "#{shared_path}/config/unicorn.rb"
  end
  before "unicorn:symlink", "unicorn:copy"


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

  desc "Reload Unicorn"
  task :reload, roles: :app do

    running = ( capture(unicorn_running).strip == '0')
    
    if running
      logger.info "Reloading Unicorn"
      run reload_unicorn
    else
      logger.info "Unicorn is not running. Starting."
      run start_unicorn
    end
  end

  desc "Restart unicorn"
  task :restart, roles: :app do

    running = ( capture(unicorn_running).strip == '0')
    
    if running
      logger.info "Reloading Unicorn"
      run stop_unicorn
      run start_unicorn
    else
      logger.info "Unicorn is not running. Starting."
      run start_unicorn
    end
  end

  namespace :logs do 
    
    desc "Tail Unicorn logs"
    task :tail do 
      trap("INT") { puts 'Interupted'; exit 0; }
      run "tail -f #{shared_path}/log/unicorn*.log" do |channel, stream, data|
        puts  # for an extra line break before the host name
        puts "#{channel[:host]}: #{data}" 
        break if stream == :err    
      end
    end
    
    desc "Clear all Unicorn logs"
    task :clear do
      run "for i in #{shared_path}/log/unicorn*; do cat /dev/null > $i; done"
    end
end

end
