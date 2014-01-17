set_default :chef_solo_roles_skip, false

namespace :chefsolo do

  desc <<-EOF
[internal] Deploy JSON file(s) to server corresponding to servers' role(s)

This recipe will find all roles the target server has and try to
deploy to the server JSON file(s) corresponding to server role(s). If
servers defined as:

role :db, db01.example.com
role :web, web01.example.com

this recipe will deploy role `db.json` to db01 and `web.json` to
web01.

Chef solo roles is called internally from chefsolo:deploy.

Source File #{path_to __FILE__}

EOF

  task :roles do 
    l_sudo = sudo               # Hack to use actual sudo locally. In other places - use rvmsudo.
    set :sudo, "sudo"
    sudo "bash #{chef_solo_remote}/install.sh empty.json", options
    set :sudo, l_sudo
    run %Q{ #{try_sudo} /usr/local/rvm/bin/rvm-exec #{chef_solo_remote}/run_roles.rb  $CAPISTRANO:HOST$ }
  end                           # :roles


  task :exit_on_request do 
    if fetch(:only_infra, false)
      logger.info "********************** ONLY INFRA specified, Infra deployed. Stopping on user request. **********************"
      exit
    end
  end
end

after "deploy:setup", "chefsolo:exit_on_request" if fetch(:only_infra, false)

