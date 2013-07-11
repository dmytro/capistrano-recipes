
load "#{File.dirname(__FILE__)}/unicorn.rb"

namespace :unicorn do
  
  desc "Start Unicorn (Monit)"
  task :start, :roles => :app do
    run "sudo monit start unicorn"
  end
  
  desc "Stop Unicorn (Monit)"
  task :stop, :roles => :app do
    run "sudo monit stop unicorn"
  end
  
  task :graceful_stop, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} kill -s QUIT `cat #{unicorn_pid}`"
  end

  desc "Restart Unicorn (Monit)"
  task :restart, :roles => :app do
    top.monit.disable
    top.unicorn.graceful_stop
    top.unicorn.start
    top.monit.enable
  end

  desc "Reload Unicorn (gracefully restart workers)"
   task :reload, :roles => :app do
    run "sudo /etc/init.d/unicorn upgrade"
   end

  desc "reconfigure unicorn (reload config and gracefully restart workers)"
  task :reconfigure, :roles => :app do
    run "sudo /etc/init.d/unicorn reload"
  end
end
