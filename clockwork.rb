set :clockwork_roles, :app
set :cw_log_file, "#{current_path}/log/clockwork.log"
set :cw_pid_file, "#{current_path}/tmp/pids/clockwork.pid"

set_default :clockwork_worker, "app/workers/clock_worker.rb"
 
namespace :clockwork do
  desc "Stop clockwork"
  task :stop, :roles => :app, :on_no_matching_servers => :continue do
    
    run "[ -s #{cw_pid_file} ] && cat #{cw_pid_file} | xargs kill -int || echo 'clockwork not running' >&2"
  end
 
  desc "Start clockwork"
  task :start, :roles => :app, :on_no_matching_servers => :continue do

    run "cd #{current_path}; RAILS_ENV=production nohup bundle exec clockwork #{clockwork_worker} -e #{rails_env} >> #{cw_log_file} 2>&1 &", :pty => false
    run "ps -C ruby -o pid,cmd | awk '$0 ~ /bin\\/clockwork/ {print $1 }' > #{cw_pid_file} "

  end
 
  desc "Restart clockwork"
  task :restart do
    stop
    start
  end
end

after "deploy:stop", "clockwork:stop"
after "deploy:start", "clockwork:start"
after "deploy:restart", "clockwork:restart"
