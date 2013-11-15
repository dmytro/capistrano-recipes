set_default :chef_solo_roles_skip, false

namespace :chefsolo do

  desc <<-EOF
Deploy JSON file(s) to server corresponding to servers' role(s)

This recipe will find all roles the target server has and try to
deploy to the server JSON file(s) corresponding to server role(s). If
servers defined as:

role :db, db01.example.com
role :web, web01.example.com

this recipe will deploy role `db.json` to db01 and `web.json` to
web01.

Configuration:

- To skip infra roles process use: cap -s chef_solo_roles_skip=true ...

Source File #{path_to __FILE__}

EOF

  task :roles do 
    run %Q{ #{try_sudo} #{chef_solo_remote}/run_roles.rb  $CAPISTRANO:HOST$ }
  end                           # :roles

  
  desc "Stop after executing chefsolo:roles"
  task :no_release do
    logger.info "Infra deployed. Stopping on user request."
    exit
  end
end

after  "chefsolo:roles", "chefsolo:no_release" if fetch(:infra_only, false)
before "chefsolo:roles", "chefsolo:deploy" unless fetch(:chef_solo_roles_skip, true)
before "deploy", "chefsolo:roles"          unless fetch(:chef_solo_roles_skip, true)

desc 'TODO'
task :configuration_bag do
  @variables.each do |k,v|
    puts "#{k}: #{v}" unless v.class == Proc
  end
end
